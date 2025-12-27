import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:comply/config/constants.dart';
import 'package:comply/screens/users_screen/create_order_screen.dart';
import 'package:comply/services/master_service.dart';
import 'package:comply/services/room_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:intl/intl.dart';

// Helper function to resolve full image URL
String? _resolveImageUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http')) return url;
  try {
    // Assuming baseUrl is defined in constants.dart like 'http://ip:port/api'
    final serverUri = Uri.parse(baseUrl.replaceAll('/api', ''));
    // Ensure url doesn't start with / if we are using resolve, or handle it.
    // resolve() handles paths starting with / correctly against the root.
    return serverUri.resolve(url.startsWith('/') ? url.substring(1) : url).toString(); 
  } catch (e) {
    print("Error resolving URL: $e");
    return url;
  }
}

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
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      imageUrl: _resolveImageUrl(json['image_url']),
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
    final int capacity;

    Room({ 
      required this.id, 
      this.roomNumber, 
      this.description, 
      required this.price, 
      this.imageUrl, 
      required this.isAvailable,
      required this.capacity,
    });

    factory Room.fromJson(Map<String, dynamic> json) {
        return Room(
            id: json['id'],
            roomNumber: json['room_number'],
            description: json['description'],
            price: double.tryParse(json['price'].toString()) ?? 0.0,
            imageUrl: _resolveImageUrl(json['image_url']),
            isAvailable: json['is_available'] == 1,
            capacity: int.tryParse(json['capacity'].toString()) ?? 0,
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

  Future<BitmapDescriptor> _getMarkerIcon(String? imageUrl, Size size) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      return BitmapDescriptor.defaultMarker;
    }

    try {
      final http.Response response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        final ui.Codec codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: size.width.toInt(),
          targetHeight: size.height.toInt(),
        );
        final ui.FrameInfo fi = await codec.getNextFrame();
        final ui.Image image = fi.image;

        final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
        final Canvas canvas = Canvas(pictureRecorder);
        final Paint paint = Paint()..isAntiAlias = true;
        final double radius = size.width / 2;

        final Path clipPath = Path()
          ..addOval(Rect.fromCircle(center: Offset(radius, radius), radius: radius));
        canvas.clipPath(clipPath);
        canvas.drawImage(image, Offset.zero, paint);

        final ui.Image recordedImage = await pictureRecorder.endRecording().toImage(
          size.width.toInt(),
          size.height.toInt(),
        );
        final ByteData? byteData = await recordedImage.toByteData(format: ui.ImageByteFormat.png);
        
        if (byteData != null) {
            final Uint8List pngBytes = byteData.buffer.asUint8List();
            return BitmapDescriptor.fromBytes(pngBytes);
        }
      }
    } catch (e) {
      print('Error creating circular marker image: $e');
    }

    return BitmapDescriptor.defaultMarker;
  }

  Future<void> _fetchAndSetMarkers() async {
    try {
      final masters = await _masterService.getMasters();
      final places = masters.map((m) => Place.fromJson(m)).where((p) => p.latitude != 0.0 && p.longitude != 0.0).toList();

      final Set<Marker> markers = {};
      for (var place in places) {
        final BitmapDescriptor icon = await _getMarkerIcon(place.imageUrl, const Size(120, 120));
        markers.add(
          Marker(
            markerId: MarkerId(place.id.toString()),
            position: LatLng(place.latitude, place.longitude),
            infoWindow: InfoWindow(title: place.name),
            icon: icon,
            onTap: () {
              _onMarkerTapped(place);
            },
          ),
        );
      }

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
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    try {
      LocationData locationData = await location.getLocation();
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(locationData.latitude!, locationData.longitude!),
          zoom: 18,
        ),
      ));
    } catch (e) {
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
            onTap: (_) => _hidePlaceDetails(),
          ),
           Positioned(
            right: 16.0,
            bottom: 300, // Adjusted to be above the sheet
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FloatingActionButton(
                  heroTag: 'zoomIn',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () async {
                    final GoogleMapController controller = await _controller.future;
                    controller.animateCamera(CameraUpdate.zoomIn());
                  },
                  child: const Icon(Icons.add, color: Colors.black),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoomOut',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () async {
                    final GoogleMapController controller = await _controller.future;
                    controller.animateCamera(CameraUpdate.zoomOut());
                  },
                  child: const Icon(Icons.remove, color: Colors.black),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'myLocation',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _goToMyLocation,
                  child: const Icon(Icons.my_location, color: Colors.black),
                ),
              ],
            ),
          ),
          if (_isPlaceDetailsVisible)
            DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.95,
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [BoxShadow(blurRadius: 15, color: Colors.black.withOpacity(0.2))]
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: _buildPlaceDetailsSheet(scrollController),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceDetailsSheet(ScrollController scrollController) {
    if (_selectedPlace == null) return const SizedBox.shrink();

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedPlace!.name,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_selectedPlace!.imageUrl != null && _selectedPlace!.imageUrl!.isNotEmpty)
                       ClipOval(
                         child: Image.network(
                           _selectedPlace!.imageUrl!,
                           height: 40,
                           width: 40,
                           fit: BoxFit.cover,
                           errorBuilder: (context, error, stackTrace) =>
                               Container(height: 40, width: 40, color: Colors.grey[200], child: const Icon(Icons.image_not_supported, size: 20, color: Colors.grey)),
                         ),
                       )
                    else
                       Container(
                         height: 40,
                         width: 40,
                         decoration: BoxDecoration(
                           color: Colors.grey[100],
                           shape: BoxShape.circle,
                         ),
                         child: const Center(child: Icon(Icons.hotel, size: 20, color: Colors.blueGrey)),
                       ),
                  ],
                ),
              ),
              const Divider(indent: 20, endIndent: 20, height: 24),
            ],
          ),
        ),
        if (_isLoadingRooms)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_roomsForSelectedPlace.isEmpty)
           const SliverFillRemaining(
             hasScrollBody: false,
             child: Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.meeting_room_outlined, size: 64, color: Colors.grey),
                   SizedBox(height: 16),
                   Text('No rooms available', style: TextStyle(color: Colors.grey, fontSize: 18)),
                 ],
               ),
             ),
           )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildRoomCard(_roomsForSelectedPlace[index]),
              childCount: _roomsForSelectedPlace.length,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }

  Widget _buildRoomCard(Room room) {
      return Container(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        child: room.imageUrl != null && room.imageUrl!.isNotEmpty
                            ? Image.network(
                                room.imageUrl!, 
                                height: 200, 
                                width: double.infinity, 
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 200,
                                  width: double.infinity,
                                  color: Colors.grey[100],
                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              )
                            : Container(
                                height: 200,
                                width: double.infinity,
                                color: Colors.grey[100],
                                child: Icon(Icons.hotel, size: 50, color: Colors.grey[300]),
                              ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: room.isAvailable ? Colors.green.withOpacity(0.9) : Colors.red.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            room.isAvailable ? 'Available' : 'Occupied',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.meeting_room, size: 24, color: Colors.black87),
                                      const SizedBox(width: 8),
                                      Text(
                                        room.roomNumber ?? 'Room',
                                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.people_outline, size: 24, color: Colors.black87),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${room.capacity}',
                                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (room.description != null && room.description!.isNotEmpty)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.info_outline, size: 17, color: Colors.black87),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        room.description!,
                                        style: TextStyle(color: Colors.black87, fontSize: 15, height: 1.5),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Price per night', style: TextStyle(color: Colors.black87, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${NumberFormat("#,###").format(room.price).replaceAll(",", " ")} UZS', 
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF4A80F0)),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  ElevatedButton(
                                      onPressed: room.isAvailable ? () {
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => 
                                            CreateOrderScreen(
                                              masterId: _selectedPlace!.id,
                                              roomId: room.id,
                                            )));
                                      } : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4A80F0),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        disabledBackgroundColor: Colors.grey[200],
                                        disabledForegroundColor: Colors.grey[400],
                                      ),
                                      child: const Text('Enter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  )
                                ],
                              )
                          ],
                      ),
                  )
              ],
          ),
      );
  }
}
