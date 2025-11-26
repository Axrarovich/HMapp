import 'dart:async';
import 'package:comply/screens/users_screen/create_order_screen.dart';
import 'package:comply/services/master_service.dart';
import 'package:comply/services/room_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class Place {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String? imageUrl;

  Place({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'],
      name: json['place_name'] ?? 'Unknown Place',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      imageUrl: json['image_url'],
    );
  }
}

class Room {
    final int id;
    final String? roomNumber;
    final String? description;
    final double price;
    final String? imageUrl;
    final bool isAvailable;

    Room({ required this.id, this.roomNumber, this.description, required this.price, this.imageUrl, required this.isAvailable });

    factory Room.fromJson(Map<String, dynamic> json) {
        return Room(
            id: json['id'],
            roomNumber: json['room_number'],
            description: json['description'],
            price: double.tryParse(json['price'].toString()) ?? 0.0,
            imageUrl: json['image_url'],
            isAvailable: json['is_available'] == 1,
        );
    }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final MasterService _masterService = MasterService();
  final RoomService _roomService = RoomService();

  final Set<Marker> _markers = {};
  Place? _selectedPlace;
  List<Room> _roomsForSelectedPlace = [];
  bool _isPlaceDetailsVisible = false;
  bool _isLoadingRooms = false;

  static const CameraPosition _tashkent = CameraPosition(
    target: LatLng(41.311081, 69.240562),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _fetchAndSetMarkers();
  }

  Future<void> _fetchAndSetMarkers() async {
    try {
      final masters = await _masterService.getMasters();
      final places = masters.map((m) => Place.fromJson(m)).where((p) => p.latitude != 0.0 && p.longitude != 0.0).toList();

      final markers = places.map((place) {
        return Marker(
          markerId: MarkerId(place.id.toString()),
          position: LatLng(place.latitude, place.longitude),
          infoWindow: InfoWindow(title: place.name),
          onTap: () {
             _onMarkerTapped(place);
          },
        );
      }).toSet();

      if (mounted) {
        setState(() {
          _markers.addAll(markers);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load places: $e')),
        );
      }
    }
  }

  void _onMarkerTapped(Place place) {
    setState(() {
      _selectedPlace = place;
      _isPlaceDetailsVisible = true;
      _isLoadingRooms = true;
      _roomsForSelectedPlace = [];
    });
    _fetchRoomsForPlace(place.id);
  }

  Future<void> _fetchRoomsForPlace(int masterId) async {
    try {
      final roomsData = await _roomService.getRoomsForPlace(masterId);
      final rooms = roomsData.map((r) => Room.fromJson(r)).toList();
       if (mounted) {
        setState(() {
            _roomsForSelectedPlace = rooms;
            _isLoadingRooms = false;
        });
       }
    } catch (e) {
        if (mounted) {
            setState(() { _isLoadingRooms = false; });
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to load rooms: $e')),
            );
        }
    }
  }

  void _hidePlaceDetails() {
      if (mounted) {
        setState(() {
            _isPlaceDetailsVisible = false;
            _selectedPlace = null;
            _roomsForSelectedPlace = [];
        });
      }
  }

  Future<void> _goToMyLocation() async {
    Location location = Location();

    debugPrint("Checking location service...");
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      debugPrint("Location service is disabled. Requesting service...");
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        debugPrint("Location service request was denied.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.')),
          );
        }
        return;
      }
    }
    debugPrint("Location service is enabled.");

    debugPrint("Checking location permission...");
    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      debugPrint("Location permission is denied. Requesting permission...");
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        debugPrint("Location permission request was denied.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')),
          );
        }
        return;
      }
    }
    debugPrint("Location permission is granted.");

    try {
      debugPrint("Getting current location...");
      LocationData locationData = await location.getLocation();
      debugPrint("Location received: ${locationData.latitude}, ${locationData.longitude}");
      final GoogleMapController controller = await _controller.future;
      debugPrint("Moving camera to new location.");
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(locationData.latitude!, locationData.longitude!),
          zoom: 18,
        ),
      ));
      debugPrint("Camera move initiated.");
    } catch (e) {
      debugPrint("Error getting location: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _tashkent,
            markers: _markers,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            onTap: (_) => _hidePlaceDetails(), // Hide details when tapping on map
          ),
           Positioned(
            right: 16.0,
            bottom: 0,
            top: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: FloatingActionButton(
                      heroTag: 'zoomIn',
                      onPressed: () async {
                        final GoogleMapController controller = await _controller.future;
                        controller.animateCamera(CameraUpdate.zoomIn());
                      },
                      child: const Icon(Icons.add),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: FloatingActionButton(
                      heroTag: 'zoomOut',
                      onPressed: () async {
                        final GoogleMapController controller = await _controller.future;
                        controller.animateCamera(CameraUpdate.zoomOut());
                      },
                      child: const Icon(Icons.remove),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: FloatingActionButton(
                      heroTag: 'myLocation',
                      onPressed: _goToMyLocation,
                      child: const Icon(Icons.my_location),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isPlaceDetailsVisible)
            DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.2,
              maxChildSize: 0.8,
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                      boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.25))]
                  ),
                  child: _buildPlaceDetailsSheet(scrollController),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceDetailsSheet(ScrollController scrollController) {
    if (_selectedPlace == null) return const SizedBox.shrink();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_selectedPlace!.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        const Divider(height: 1),
        Expanded(
          child: _isLoadingRooms
              ? const Center(child: CircularProgressIndicator())
              : _roomsForSelectedPlace.isEmpty
                  ? const Center(child: Text('No rooms available.'))
                  : ListView.builder(
                        controller: scrollController,
                        itemCount: _roomsForSelectedPlace.length,
                        itemBuilder: (context, index) => _buildRoomCard(_roomsForSelectedPlace[index]),
                    ),
        ),
      ],
    );
  }

  Widget _buildRoomCard(Room room) {
      return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      if (room.imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(room.imageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
                          ),
                      Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Text(room.roomNumber ?? 'Room', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(room.description ?? '', style: const TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${room.price.toStringAsFixed(0)} UZS / night', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                      ElevatedButton(
                                          onPressed: room.isAvailable ? () {
                                              Navigator.push(context, MaterialPageRoute(builder: (context) => 
                                                CreateOrderScreen(
                                                  masterId: _selectedPlace!.id,
                                                  roomId: room.id,
                                                )));
                                          } : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: room.isAvailable ? Colors.blue : Colors.grey,
                                          ),
                                          child: Text(room.isAvailable ? 'Book Now' : 'Occupied'),
                                      )
                                    ],
                                  )
                              ],
                          ),
                      )
                  ],
              ),
          ),
      );
  }
}
