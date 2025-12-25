
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({Key? key}) : super(key: key);

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late GoogleMapController mapController;
  Marker? _selectedMarker;
  LatLng? _selectedPosition;

  final LatLng _center = const LatLng(41.311081, 69.240562);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _onTap(LatLng position) {
    setState(() {
      _selectedPosition = position;
      _selectedMarker = Marker(
        markerId: const MarkerId('selected-location'),
        position: position,
      );
    });
  }

  void _confirmSelection() {
    if (_selectedMarker != null) {
      Navigator.of(context).pop(_selectedMarker!.position);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a location on the map first.')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Location permissions are permanently denied, we cannot request permissions.')),
      );
      return;
    }

    final Position position = await Geolocator.getCurrentPosition();
    final LatLng currentLatLng = LatLng(position.latitude, position.longitude);

    setState(() {
      _selectedPosition = currentLatLng;
      _selectedMarker = Marker(
        markerId: const MarkerId('selected-location'),
        position: currentLatLng,
      );
    });

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: currentLatLng,
          zoom: 19.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 11.0,
            ),
            onTap: _onTap,
            markers: _selectedMarker != null ? {_selectedMarker!} : {},
            zoomControlsEnabled: false,
          ),
          Positioned(
            right: 10,
            top: 0,
            bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    mapController.animateCamera(CameraUpdate.zoomIn());
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    mapController.animateCamera(CameraUpdate.zoomOut());
                  },
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _getCurrentLocation,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
          if (_selectedPosition != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Selected Location',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lat: ${_selectedPosition!.latitude.toStringAsFixed(6)}, Lng: ${_selectedPosition!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Confirm', style: TextStyle(fontSize: 16)),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
