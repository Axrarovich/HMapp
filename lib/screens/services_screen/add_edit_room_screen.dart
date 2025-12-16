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

    // CRITICAL FIX: The logic that added the old image_url was removed.
    // The client should not decide what URL to send; the server will handle it.

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
      appBar: AppBar(
        title: Text(widget.room == null ? 'Add Room' : 'Edit Room'),
        actions: [
          if (widget.room != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing && widget.room != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteRoom,
            ),
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.check, color: _isFormValid ? Colors.black : Colors.grey),
              onPressed: _isFormValid ? _saveOrUpdateRoom : null,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          onChanged: _validateForm,
          child: ListView(
            children: [
              TextFormField(
                controller: _roomNumberController,
                decoration: const InputDecoration(labelText: 'Room number'),
                enabled: _isEditing,
                validator: (value) => value!.isEmpty ? 'Please enter a room number' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(labelText: 'Capacity'),
                keyboardType: TextInputType.number,
                enabled: _isEditing,
                validator: (value) => value!.isEmpty ? 'Please enter the capacity' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                enabled: _isEditing,
                validator: (value) => value!.isEmpty ? 'Please enter the price' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                enabled: _isEditing,
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              // Image display section
              if (_image != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Image.file(_image!, height: 200, width: double.infinity, fit: BoxFit.cover,),
                )
              else if (widget.room?.imageUrl != null && widget.room!.imageUrl!.isNotEmpty)
                 Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Image.network(baseUrl + widget.room!.imageUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
              // Add photo button
              ElevatedButton.icon(
                onPressed: _isEditing ? _pickImage : null,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Add Photo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}