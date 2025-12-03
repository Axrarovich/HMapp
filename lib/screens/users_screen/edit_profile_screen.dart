
import 'package:comply/screens/auth/signin_screen.dart';
import 'package:comply/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _loginController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  final _authService = AuthService();
  bool _isLoading = false;
  bool _showNewPasswordFields = false;
  bool _isChanged = false;

  String _initialFirstName = '';
  String _initialLastName = '';
  String _initialLogin = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _firstNameController.addListener(_checkForChanges);
    _lastNameController.addListener(_checkForChanges);
    _loginController.addListener(_checkForChanges);
    _oldPasswordController.addListener(() {
      if (mounted) {
        setState(() {
          _showNewPasswordFields = _oldPasswordController.text.isNotEmpty;
        });
      }
      _checkForChanges();
    });
    _newPasswordController.addListener(_checkForChanges);
    _confirmPasswordController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final isChanged = _firstNameController.text != _initialFirstName ||
        _lastNameController.text != _initialLastName ||
        _loginController.text != _initialLogin ||
        _oldPasswordController.text.isNotEmpty ||
        _newPasswordController.text.isNotEmpty ||
        _confirmPasswordController.text.isNotEmpty;
    if (isChanged != _isChanged) {
      if (mounted) {
        setState(() {
          _isChanged = isChanged;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _initialFirstName = prefs.getString('first_name') ?? '';
        _initialLastName = prefs.getString('last_name') ?? '';
        _initialLogin = prefs.getString('login') ?? '';
        _firstNameController.text = _initialFirstName;
        _lastNameController.text = _initialLastName;
        _loginController.text = _initialLogin;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_oldPasswordController.text.isNotEmpty) {
        try {
          final currentLogin = (await SharedPreferences.getInstance()).getString('login') ?? '';
          await _authService.login(currentLogin, _oldPasswordController.text);
        } catch (e) {
          throw Exception('Invalid old password');
        }

        if (_newPasswordController.text != _confirmPasswordController.text) {
          throw Exception('New passwords do not match');
        }
        if (_newPasswordController.text.length < 6) {
          throw Exception('Password must be at least 6 characters');
        }
        if (_oldPasswordController.text == _newPasswordController.text) {
          throw Exception('New password cannot be the same as the old password');
        }
      }

      await _authService.updateUser(
        _firstNameController.text,
        _lastNameController.text,
        _loginController.text,
        _newPasswordController.text.isNotEmpty ? _newPasswordController.text : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
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
        final currentLogin = (await SharedPreferences.getInstance()).getString('login') ?? '';
        await _authService.login(currentLogin, password);

        await _authService.deleteUser();

        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted successfully')),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const SignInScreen()),
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _loginController.dispose();
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
            onPressed: _deleteAccount,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
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
          Container(
            height: 100,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/onboarding.jpg"),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.all(Radius.circular(12.0)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('First Name', style: TextStyle(fontSize: 15, color: Colors.black54)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _firstNameController,
                  decoration: _inputDecoration('Enter your first name'),
                  validator: (value) => value!.isEmpty ? 'Please enter your first name' : null,
                ),
                const SizedBox(height: 16),
                const Text('Last Name', style: TextStyle(fontSize: 15, color: Colors.black54)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _lastNameController,
                  decoration: _inputDecoration('Enter your last name'),
                   validator: (value) => value!.isEmpty ? 'Please enter your last name' : null,
                ),
                const SizedBox(height: 16),
                const Text('Login', style: TextStyle(fontSize: 15, color: Colors.black54)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _loginController,
                  decoration: _inputDecoration('Your login'),
                   validator: (value) => value!.isEmpty ? 'Please enter your login' : null,
                ),
                const SizedBox(height: 16),
                const Text('Old Password', style: TextStyle(fontSize: 15, color: Colors.black54)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _oldPasswordController,
                  obscureText: true,
                  decoration: _inputDecoration('Enter your old password'),
                ),
                const SizedBox(height: 16),
                if (_showNewPasswordFields) ...[
                  const Text('New Password', style: TextStyle(fontSize: 15, color: Colors.black54)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: _inputDecoration('Enter your new password'),
                    validator: (value) {
                      if (_oldPasswordController.text.isNotEmpty && (value == null || value.isEmpty)) {
                        return 'Please enter a new password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Confirm New Password', style: TextStyle(fontSize: 15, color: Colors.black54)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: _inputDecoration('Confirm your new password'),
                     validator: (value) {
                      if (_newPasswordController.text.isNotEmpty && value != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                ],
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _isChanged ? _saveChanges : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009688),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Save', style: TextStyle(color: Colors.white, fontSize: 16)),
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
