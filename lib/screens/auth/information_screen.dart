import 'dart:io';
import 'package:comply/services/auth_service.dart';
import 'package:comply/services/location_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../services_screen/orders_screen.dart';

class InformationScreen extends StatefulWidget {
  final String placeName;
  final String login;
  final String password;

  const InformationScreen({
    Key? key,
    required this.placeName,
    required this.login,
    required this.password,
  }) : super(key: key);

  @override
  State<InformationScreen> createState() => _InformationScreenState();
}

class _InformationScreenState extends State<InformationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _phone2Controller = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _authService = AuthService();
  File? _image;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController.text = '+998 ';
    _phone2Controller.text = '+998 ';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phone2Controller.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image')),
        );
        return;
      }
      setState(() {
        _isLoading = true;
      });

      try {
        final phone2 = _phone2Controller.text.trim();
        final masterData = <String, dynamic>{
          'phone_number_1': _phoneController.text.trim(),
          'phone_number_2': (phone2 == '+998' || phone2 == '+998 ') ? '' : phone2,
          'address': _addressController.text.trim(),
          'description': _descriptionController.text.trim(),
        };

        if (_image != null) {
          masterData['image'] = _image;
        }

        await _authService.register(
          widget.placeName,
          null, // No last name for masters
          widget.login,
          widget.password,
          'master',
          masterData: masterData,
        );

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const OrdersPanelScreen()),
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Information',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                        TextFormField(
                          initialValue: widget.placeName,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Place Name',
                            filled: true,
                            fillColor: Colors.grey[300],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [PhoneInputFormatter()],
                          decoration: InputDecoration(
                            labelText: 'Phone number 1 (Required)',
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty || value.trim() == '+998') {
                              return 'Please enter your phone number';
                            }
                            if (value.length != 17) {
                              return 'Please enter a complete phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _phone2Controller,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [PhoneInputFormatter()],
                          decoration: InputDecoration(
                            labelText: "Phone number 2 (Optional)",
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty || value.trim() == '+998') {
                              return null;
                            }
                            if (value.length != 17) {
                              return 'Please enter a complete phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _addressController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Select location',
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
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
                                    _addressController.text =
                                        '${selectedLocation.latitude}, ${selectedLocation.longitude}';
                                  });
                                }
                              },
                            ),
                          ),
                           validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please select a location';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          maxLength: 120,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12.0),
                              border: _image == null ? Border.all(color: Colors.grey) : null,
                            ),
                            child: _image != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12.0),
                                    child: Image.file(_image!, fit: BoxFit.cover),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_alt, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('Add Image'),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: const Text(
                            'Finish Sign Up',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text;
    String digits = text.replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('998')) {
      digits = digits.substring(3);
    }
    
    if (digits.length > 9) {
      digits = digits.substring(0, 9);
    }

    final buffer = StringBuffer();
    buffer.write('+998');
    
    if (digits.isNotEmpty) {
      buffer.write(' ');
      
      for (int i = 0; i < digits.length; i++) {
        if (i == 2 || i == 5 || i == 7) {
          buffer.write(' ');
        }
        buffer.write(digits[i]);
      }
    }

    final String formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
