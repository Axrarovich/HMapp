import 'package:comply/config/constants.dart';
import 'package:comply/screens/auth/master_signin_screen.dart';
import 'package:comply/services/master_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MasterEditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialProfileData;
  const MasterEditProfileScreen({Key? key, required this.initialProfileData}) : super(key: key);

  @override
  State<MasterEditProfileScreen> createState() =>
      _MasterEditProfileScreenState();
}

class _MasterEditProfileScreenState extends State<MasterEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _masterService = MasterService();

  // Controllers for profile data
  final _loginController = TextEditingController();
  final _placeNameController = TextEditingController();

  // Controllers for password change
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  String? _imageUrl;
  bool _showNewPasswordFields = false;
  bool _isSaving = false;
  bool _isLoading = false;
  bool _isFormChanged = false;

  @override
  void initState() {
    super.initState();
    _loginController.text = widget.initialProfileData['login'] ?? '';
    _placeNameController.text = widget.initialProfileData['place_name'] ?? '';
    _imageUrl = widget.initialProfileData['image_url'];

    _loginController.addListener(_onFormChange);
    _placeNameController.addListener(_onFormChange);
    _oldPasswordController.addListener(_onFormChange);
    _newPasswordController.addListener(_onFormChange);
    _confirmPasswordController.addListener(_onFormChange);

    _oldPasswordController.addListener(() {
      if (mounted) {
        setState(() {
          _showNewPasswordFields = _oldPasswordController.text.isNotEmpty;
        });
      }
    });
  }

  void _onFormChange() {
    final hasChanged = _loginController.text != (widget.initialProfileData['login'] ?? '') ||
        _placeNameController.text != (widget.initialProfileData['place_name'] ?? '') ||
        _oldPasswordController.text.isNotEmpty;

    if (_isFormChanged != hasChanged) {
      if (mounted) {
        setState(() {
          _isFormChanged = hasChanged;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (mounted) setState(() { _isSaving = true; });

    try {
      final profileData = {
        'login': _loginController.text,
        'place_name': _placeNameController.text,
        'phone_number_1': '', 
        'phone_number_2': '', 
        'description': '',      
        'is_available': true,
        'image_url': _imageUrl,
      };
      await _masterService.updateMasterProfile(profileData);

      if (_oldPasswordController.text.isNotEmpty) {
        if (_newPasswordController.text != _confirmPasswordController.text) {
          throw Exception('New passwords do not match');
        }
        if (_oldPasswordController.text == _newPasswordController.text) {
          throw Exception('New password cannot be the same as the old password');
        }
        if (_newPasswordController.text.length < 6) {
          throw Exception('Password must be at least 6 characters');
        }

        await _masterService.updateMasterPassword(
            _oldPasswordController.text, _newPasswordController.text);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${e.toString().replaceFirst("Exception: ", "")}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isSaving = false; });
      }
    }
  }
  
  Future<void> _deleteAccount() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? A deleted account cannot be restored.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _passwordConfirmController.clear();
    final String? password = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Confirm Deletion'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Please enter your current password to proceed.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordConfirmController,
                    obscureText: true,
                    decoration: _inputDecoration('Current Password'),
                    autofocus: true,
                    onChanged: (value) => setState(() {}),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: _passwordConfirmController.text.isNotEmpty
                      ? () {
                          Navigator.of(context).pop(_passwordConfirmController.text);
                        }
                      : null,
                  child: const Text('Confirm', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
    );

    if (password != null && password.isNotEmpty) {
      if (mounted) setState(() => _isLoading = true);

      try {
        await _masterService.deleteMasterAccount(password);

        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted successfully')),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MasterSignInScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid password. Account not deleted.')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _loginController.removeListener(_onFormChange);
    _placeNameController.removeListener(_onFormChange);
    _oldPasswordController.removeListener(_onFormChange);
    _newPasswordController.removeListener(_onFormChange);
    _confirmPasswordController.removeListener(_onFormChange);

    _loginController.dispose();
    _placeNameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteAccount,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: _buildEditForm(context),
        ),
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
                  child: (_imageUrl != null && _imageUrl!.isNotEmpty)
                      ? Image.network(
                          Uri.parse(baseUrl).resolve(_imageUrl!).toString(),
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.person, size: 200),
                        )
                      : Image.asset(
                          "assets/images/logo.jpg",
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
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
                  decoration: _inputDecoration('Enter place name'),
                   validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'This field cannot be empty';
                      }
                      return null;
                    },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Login',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _loginController,
                  decoration: _inputDecoration('Enter login'),
                  validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'This field cannot be empty';
                      }
                      return null;
                    },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Current Password',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _oldPasswordController,
                  obscureText: true,
                  decoration: _inputDecoration('Enter your current password'),
                ),
                if (_showNewPasswordFields)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'New Password',
                          style: TextStyle(fontSize: 15, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: true,
                          decoration: _inputDecoration('Enter new password'),
                          validator: (value) {
                            if (_showNewPasswordFields && (value == null || value.isEmpty)) {
                              return 'Please enter a new password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Confirm New Password',
                          style: TextStyle(fontSize: 15, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: _inputDecoration('Confirm your new password'),
                          validator: (value) {
                            if (_showNewPasswordFields && value != _newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                 _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _isFormChanged && !_isSaving ? _saveChanges : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009688),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Save', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Theme.of(context).primaryColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
