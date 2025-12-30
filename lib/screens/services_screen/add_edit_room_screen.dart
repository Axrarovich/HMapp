import 'dart:io';

import 'package:comply/config/constants.dart';
import 'package:comply/screens/services_screen/hotel_page.dart';
import 'package:comply/services/room_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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
  bool _deleteImage = false;
  bool _isFormValid = false;
  bool _isEditing = false;
  bool _hasChanges = false;
  final RoomService _roomService = RoomService();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.room == null;

    _roomNumberController = TextEditingController(text: widget.room?.roomNumber);
    _capacityController = TextEditingController(text: widget.room?.capacity.toString());
    
    String initialPrice = '';
    if (widget.room != null) {
      // Format price: 500000 -> 500 000
      initialPrice = NumberFormat("#,###", "en_US").format(widget.room!.price).replaceAll(",", " ");
    }
    _priceController = TextEditingController(text: initialPrice);
    
    _descriptionController = TextEditingController(text: widget.room?.description);

    _roomNumberController.addListener(_validateForm);
    _capacityController.addListener(_validateForm);
    _priceController.addListener(_validateForm);
    _descriptionController.addListener(_validateForm);

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
      final isValid = _formKey.currentState!.validate();
      bool changes = false;
      
      if (widget.room == null) {
        changes = true;
      } else {
        // Remove spaces for comparison
        String currentPriceStr = _priceController.text.replaceAll(' ', '');
        double? currentPrice = double.tryParse(currentPriceStr);
        
        // Simple change detection
        bool priceChanged = false;
        if (currentPrice != null) {
            priceChanged = currentPrice != widget.room!.price;
        } else {
            // If empty or invalid and was not empty before, it's a change (though validation might fail)
            priceChanged = _priceController.text != (widget.room?.price.toString() ?? '');
        }

        changes = _image != null ||
            _deleteImage ||
            _roomNumberController.text != (widget.room?.roomNumber ?? '') ||
            _capacityController.text != (widget.room?.capacity.toString() ?? '') ||
            priceChanged ||
            _descriptionController.text != (widget.room?.description ?? '');
      }

      setState(() {
        _isFormValid = isValid;
        _hasChanges = changes;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _deleteImage = false;
        _validateForm();
      });
    }
  }

  void _removeImage() {
    setState(() {
      _image = null;
      if (widget.room?.imageUrl != null) {
        _deleteImage = true;
      }
      _validateForm();
    });
  }

  Future<void> _saveOrUpdateRoom() async {
    if (!_formKey.currentState!.validate()) return;

    final roomData = {
      'room_number': _roomNumberController.text,
      'capacity': _capacityController.text,
      'price': _priceController.text.replaceAll(' ', ''), // Clean the price
      'description': _descriptionController.text,
      'is_available': '1', 
    };

    if (_deleteImage) {
      roomData['delete_image'] = 'true';
    }

    try {
      if (widget.room != null) {
        await _roomService.updateRoom(widget.room!.id, roomData, _image);
        if (mounted) {
          setState(() {
            _isEditing = false;
            _hasChanges = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated successfully')));
        }
      } else {
        await _roomService.createRoom(roomData, _image);
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
       }
    }
  }

  Future<void> _deleteRoom() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Room'),
          content: const Text('Are you sure you want to delete this room?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _roomService.deleteRoom(widget.room!.id);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete room: $e')));
        }
      }
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
        leading: (widget.room != null && _isEditing)
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _roomNumberController.text = widget.room?.roomNumber ?? '';
                    _capacityController.text = widget.room?.capacity.toString() ?? '';
                    _priceController.text = widget.room != null
                        ? NumberFormat("#,###", "en_US").format(widget.room!.price).replaceAll(",", " ")
                        : '';
                    _descriptionController.text = widget.room?.description ?? '';
                    _image = null;
                    _deleteImage = false;
                    _validateForm();
                  });
                },
              )
            : null,
        title: Text(widget.room == null ? 'Add Room' : (_isEditing ? 'Edit Room' : 'Room'),
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),),
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
              icon: Icon(Icons.check_circle, color: (_isFormValid && _hasChanges) ? Colors.blueAccent : Colors.grey, size: 28),
              onPressed: (_isFormValid && _hasChanges) ? _saveOrUpdateRoom : null,
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
    bool hasImage = _image != null || (widget.room?.imageUrl != null && widget.room!.imageUrl!.isNotEmpty && !_deleteImage);

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
               color: Colors.black.withOpacity(0.05),
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
            else if (widget.room?.imageUrl != null && widget.room!.imageUrl!.isNotEmpty && !_deleteImage)
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasImage) ...[
                      GestureDetector(
                        onTap: _removeImage,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.blueAccent),
                    ),
                  ],
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
            color: Colors.black.withOpacity(0.03),
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
          prefixIcon: Icon(icon, color: Colors.blueAccent.withOpacity(0.7)),
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
