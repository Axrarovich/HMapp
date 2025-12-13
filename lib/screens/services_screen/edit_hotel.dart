import 'dart:io';
import 'package:comply/config/constants.dart';
import 'package:comply/services/master_service.dart';
import '../../services/location_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

class EditHotelScreen extends StatefulWidget {
  final Map<String, dynamic> initialProfileData;
  const EditHotelScreen({Key? key, required this.initialProfileData}) : super(key: key);

  @override
  State<EditHotelScreen> createState() =>
      _MasterEditProfileScreenState();
}

class _MasterEditProfileScreenState extends State<EditHotelScreen> {
  final _masterService = MasterService();
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _phone1Controller;
  late final TextEditingController _phone2Controller;
  late final TextEditingController _placeNameController;
  String? _imageUrl;
  File? _imageFile;
  bool _isSaving = false;
  bool _isFormChanged = false;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: '${widget.initialProfileData['latitude'] ?? ''}, ${widget.initialProfileData['longitude'] ?? ''}');
    _descriptionController = TextEditingController(text: widget.initialProfileData['description'] ?? '');
    _phone1Controller = TextEditingController(text: widget.initialProfileData['phone_number_1'] ?? '');
    _phone2Controller = TextEditingController(text: widget.initialProfileData['phone_number_2'] ?? '');
    _placeNameController = TextEditingController(text: widget.initialProfileData['place_name'] ?? '');
    _imageUrl = widget.initialProfileData['image_url'];

    _placeNameController.addListener(_checkFormChanges);
    _phone1Controller.addListener(_checkFormChanges);
    _phone2Controller.addListener(_checkFormChanges);
    _descriptionController.addListener(_checkFormChanges);
    _locationController.addListener(_checkFormChanges);
  }

  @override
  void dispose() {
    _placeNameController.removeListener(_checkFormChanges);
    _phone1Controller.removeListener(_checkFormChanges);
    _phone2Controller.removeListener(_checkFormChanges);
    _descriptionController.removeListener(_checkFormChanges);
    _locationController.removeListener(_checkFormChanges);

    _locationController.dispose();
    _descriptionController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    _placeNameController.dispose();
    super.dispose();
  }

  void _checkFormChanges() {
    final initialLocation = '${widget.initialProfileData['latitude'] ?? ''}, ${widget.initialProfileData['longitude'] ?? ''}';

    final hasTextChanged = _placeNameController.text != (widget.initialProfileData['place_name'] ?? '') ||
        _phone1Controller.text != (widget.initialProfileData['phone_number_1'] ?? '') ||
        _phone2Controller.text != (widget.initialProfileData['phone_number_2'] ?? '') ||
        _descriptionController.text != (widget.initialProfileData['description'] ?? '') ||
        _locationController.text != initialLocation;

    final hasImageChanged = _imageFile != null || _imageUrl != widget.initialProfileData['image_url'];

    if (mounted) {
      setState(() {
        _isFormChanged = hasTextChanged || hasImageChanged;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _imageUrl = null; // Clear network image if a local file is picked
      });
      _checkFormChanges();
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _imageUrl = ''; // Set to empty to represent no image
    });
    _checkFormChanges();
  }

  Future<void> _saveChanges() async {
    setState(() { _isSaving = true; });

    try {
      String? uploadedImageUrl = _imageUrl;
      if (_imageFile != null) {
        uploadedImageUrl = await _masterService.uploadImage(_imageFile!);
      }

      final profileData = {
        'login': widget.initialProfileData['login'], // Keep the login same
        'place_name': _placeNameController.text,
        'phone_number_1': _phone1Controller.text, 
        'phone_number_2': _phone2Controller.text, 
        'description': _descriptionController.text,      
        'is_available': true,   
        'image_url': uploadedImageUrl,
      };

      await _masterService.updateMasterProfile(profileData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isSaving = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Edit Service Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _buildEditForm(context),
      ),
    );
  }

  Widget _buildEditForm(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: Column(
              children: [
                ClipOval(
                  child: _imageFile != null
                      ? Image.file(
                          _imageFile!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        )
                      : (_imageUrl != null && _imageUrl!.isNotEmpty)
                          ? Image.network(
                              Uri.parse(baseUrl).resolve(_imageUrl!).toString(),
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                  const Icon(Icons.business, size: 200),
                            )
                          : Image.asset(
                              "assets/images/logo.jpg",
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                ),
                 const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                        onPressed: _pickImage,
                        child: const Text("Change picture")),
                    const SizedBox(width: 8.0),
                    TextButton(
                      onPressed: _removeImage,
                      child: const Text("Remove",
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Place name',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _placeNameController,
                  decoration: InputDecoration(
                    hintText: 'Enter place name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Edit phone number 1',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phone1Controller,
                  decoration: InputDecoration(
                    hintText: 'Enter phone number 1',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Edit phone number 2',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phone2Controller,
                  decoration: InputDecoration(
                    hintText: 'Enter phone number 2',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Location',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: 'Select location',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.location_on),
                      onPressed: () async {
                        final selectedLocation = await Navigator.push<LatLng>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LocationPickerScreen(),
                          ),
                        );

                        if (selectedLocation != null) {
                          setState(() {
                            _locationController.text =
                            '${selectedLocation.latitude}, ${selectedLocation.longitude}';
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Description',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLength: 120,
                  decoration: InputDecoration(
                    hintText: 'Enter description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (_isSaving || !_isFormChanged) ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009688),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
