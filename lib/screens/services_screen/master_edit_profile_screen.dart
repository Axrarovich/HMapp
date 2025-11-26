import 'package:comply/services/master_service.dart';
import 'package:flutter/material.dart';

class MasterEditProfileScreen extends StatefulWidget {
  const MasterEditProfileScreen({Key? key, required String login}) : super(key: key);

  @override
  State<MasterEditProfileScreen> createState() =>
      _MasterEditProfileScreenState();
}

class _MasterEditProfileScreenState extends State<MasterEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _masterService = MasterService();

  // Controllers for master's own data (name, etc. - not implemented in this screen)

  // Controllers for master service details
  final _phone1Controller = TextEditingController();
  final _phone2Controller = TextEditingController();
  final _descriptionController = TextEditingController();
  final _placeNameController = TextEditingController();
  bool _isAvailable = true;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadMasterProfile();
  }

  Future<void> _loadMasterProfile() async {
    setState(() { _isLoading = true; });
    try {
      final profileData = await _masterService.getMasterProfile();
      setState(() {
        _phone1Controller.text = profileData['phone_number_1'] ?? '';
        _phone2Controller.text = profileData['phone_number_2'] ?? '';
        _descriptionController.text = profileData['description'] ?? '';
        _placeNameController.text = profileData['place_name'] ?? '';
        _isAvailable = profileData['is_available'] == 1;
      });
    } catch (e) {
       if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
       }
    } finally {
       if(mounted) {
        setState(() { _isLoading = false; });
       }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isSaving = true; });

      final dataToUpdate = {
        'phone_number_1': _phone1Controller.text,
        'phone_number_2': _phone2Controller.text,
        'description': _descriptionController.text,
        'place_name': _placeNameController.text,
        'is_available': _isAvailable,
        // lat/lon/image_url are not handled in this form for simplicity
      };

      try {
        await _masterService.updateMasterProfile(dataToUpdate);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
         if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save profile: $e')),
          );
         }
      } finally {
        if(mounted) {
          setState(() { _isSaving = false; });
        }
      }
    }
  }


  @override
  void dispose() {
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    _descriptionController.dispose();
    _placeNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Edit Service Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: _buildEditForm(context),
              ),
            ),
    );
  }

  Widget _buildEditForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _phone1Controller,
          decoration: const InputDecoration(labelText: 'Primary Phone Number'),
          keyboardType: TextInputType.phone,
          validator: (value) => value!.isEmpty ? 'Please enter a phone number' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phone2Controller,
          decoration: const InputDecoration(labelText: 'Secondary Phone Number (Optional)'),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _placeNameController,
          decoration: const InputDecoration(labelText: 'Workplace Name / Address'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(labelText: 'Service Description'),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Available for new orders'),
          value: _isAvailable,
          onChanged: (bool value) {
            setState(() {
              _isAvailable = value;
            });
          },
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: _isSaving
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save Changes'),
                ),
        ),
      ],
    );
  }
}
