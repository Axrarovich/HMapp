import 'dart:io';

import 'package:comply/config/constants.dart';
import 'package:comply/screens/services_screen/hotel_page.dart';
import 'package:comply/services/room_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddEditRoomScreen extends StatefulWidget {
  final Room? room;
  const AddEditRoomScreen({Key? key, this.room}) : super(key: key);

  @override
  State<AddEditRoomScreen> createState() => _AddEditRoomScreenState();
}

class _AddEditRoomScreenState extends State<AddEditRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _roomNumberController;
  late TextEditingController _capacityController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  File? _image;
  bool _isFormValid = false;
  bool _isEditing = false;
  final RoomService _roomService = RoomService();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.room == null;

    _roomNumberController = TextEditingController(text: widget.room?.roomNumber);
    _capacityController = TextEditingController(text: widget.room?.capacity.toString());
    _priceController = TextEditingController(text: widget.room?.price.toString());
    _descriptionController = TextEditingController(text: widget.room?.description);

    _roomNumberController.addListener(_validateForm);
    _capacityController.addListener(_validateForm);
    _priceController.addListener(_validateForm);

    WidgetsBinding.instance.addPostFrameCallback((_) => _validateForm());
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    _capacityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _validateForm() {
    if (_formKey.currentState != null) {
      setState(() {
        _isFormValid = _formKey.currentState!.validate();
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveOrUpdateRoom() async {
    if (!_formKey.currentState!.validate()) return;

    final roomData = {
      'room_number': _roomNumberController.text,
      'capacity': _capacityController.text,
      'price': _priceController.text,
      'description': _descriptionController.text,
      'is_available': '1', 
    };

    try {
      if (widget.room != null) {
        await _roomService.updateRoom(widget.room!.id, roomData, _image);
      } else {
        await _roomService.createRoom(roomData, _image);
      }
      if (mounted) {
          Navigator.of(context).pop();
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
       }
    }
  }

  Future<void> _deleteRoom() async {
    try {
      await _roomService.deleteRoom(widget.room!.id);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete room: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(widget.room == null ? 'Add Room' : 'Edit Room'),
        actions: [
          if (widget.room != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing && widget.room != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deleteRoom,
            ),
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.check_circle, color: _isFormValid ? Colors.blueAccent : Colors.grey, size: 28),
              onPressed: _isFormValid ? _saveOrUpdateRoom : null,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        onChanged: _validateForm,
        child: Column(
          children: [
            _buildImageHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildModernTextField(
                      controller: _roomNumberController,
                      label: 'Room Number',
                      icon: Icons.meeting_room_outlined,
                      validator: (value) => value!.isEmpty ? 'Please enter a room number' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernTextField(
                            controller: _capacityController,
                            label: 'Capacity',
                            icon: Icons.people_outline,
                            keyboardType: TextInputType.number,
                            validator: (value) => value!.isEmpty ? 'Please enter the capacity' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildModernTextField(
                            controller: _priceController,
                            label: 'Price',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                            validator: (value) => value!.isEmpty ? 'Please enter the price' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      icon: Icons.description_outlined,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader() {
    return GestureDetector(
      onTap: _isEditing ? _pickImage : null,
      child: Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          boxShadow: [
             BoxShadow(
               color: Colors.black.withValues(alpha: 0.05),
               blurRadius: 10,
               offset: const Offset(0, 4),
             )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_image != null)
              Image.file(_image!, fit: BoxFit.cover)
            else if (widget.room?.imageUrl != null && widget.room!.imageUrl!.isNotEmpty)
               Image.network(
                  Uri.parse(baseUrl.replaceAll('/api', '')).resolve(widget.room!.imageUrl!).toString(),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image_outlined, size: 50, color: Colors.grey)),
                )
            else
               Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.grey[500]),
                     const SizedBox(height: 8),
                     Text('Add Room Photo', style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500)),
                   ],
                 ),
               ),
             if (_isEditing)
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.blueAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: Colors.blueAccent.withValues(alpha: 0.7)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
