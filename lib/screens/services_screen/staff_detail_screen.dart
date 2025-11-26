import 'package:flutter/material.dart';

class StaffDetailScreen extends StatefulWidget {
  final Map<String, String?>? staffMember;
  final bool isAdding;

  const StaffDetailScreen({Key? key, this.staffMember, this.isAdding = false})
      : assert(isAdding || staffMember != null),
        super(key: key);

  @override
  _StaffDetailScreenState createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends State<StaffDetailScreen> {
  late bool _isEditing;
  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _ageController;
  late TextEditingController _positionController;
  late TextEditingController _phone1Controller;
  late TextEditingController _phone2Controller;
  late TextEditingController _passportSeriesController;
  late TextEditingController _passportNumberController;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.isAdding;

    _nameController = TextEditingController(text: widget.staffMember?['name'] ?? '');
    _surnameController =
        TextEditingController(text: widget.staffMember?['surname'] ?? '');
    _ageController = TextEditingController(text: widget.staffMember?['age'] ?? '');
    _positionController =
        TextEditingController(text: widget.staffMember?['position'] ?? '');
    _phone1Controller =
        TextEditingController(text: widget.staffMember?['phone1'] ?? '');
    _phone2Controller =
        TextEditingController(text: widget.staffMember?['phone2'] ?? '');

    final passportData =
        widget.staffMember?['passport']?.replaceAll(' ', '') ?? '';
    String series = "";
    String number = "";
    if (passportData.length >= 2) {
      series = passportData.substring(0, 2);
      number = passportData.substring(2);
    } else {
      series = passportData;
    }

    _passportSeriesController = TextEditingController(text: series);
    _passportNumberController = TextEditingController(text: number);
    _imagePath = widget.staffMember?['imagePath'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _ageController.dispose();
    _positionController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    _passportSeriesController.dispose();
    _passportNumberController.dispose();
    super.dispose();
  }

  void _onSave() {
    // Basic validation to ensure required fields are not empty
    if (_nameController.text.isEmpty || _surnameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Surname cannot be empty.')),
      );
      return;
    }

    final staffData = {
      'name': _nameController.text,
      'surname': _surnameController.text,
      'age': _ageController.text,
      'position': _positionController.text,
      'phone1': _phone1Controller.text,
      'phone2': _phone2Controller.text,
      'passport':
          '${_passportSeriesController.text}${_passportNumberController.text}',
      'imagePath': _imagePath ?? 'assets/images/worker.jpg', // Default image
    };

    if (widget.isAdding) {
      Navigator.of(context).pop(staffData);
    } else {
      setState(() {
        widget.staffMember?.addAll(staffData);
        _isEditing = false;
      });
    }
  }

  void _toggleEditingOrSave() {
    if (_isEditing) {
      _onSave();
    } else {
      setState(() {
        _isEditing = true;
      });
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose new photo'),
                onTap: () {
                  // Placeholder for image picking logic
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Remove photo'),
                onTap: () {
                  setState(() {
                    _imagePath = ''; // Set to empty or a placeholder
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content:
              const Text('Are you sure you want to delete this staff member?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Delete'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                // Perform deletion logic here
                print('Staff member deleted'); // Placeholder
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(true); // Go back from detail screen
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String title;
    if (widget.isAdding) {
      title = 'Add New Staff';
    } else if (_isEditing) {
      title = 'Edit Profile';
    } else {
      title = '${_nameController.text} ${_surnameController.text}';
    }

    return Scaffold(
      appBar: AppBar(
        leading: widget.isAdding
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        automaticallyImplyLeading: !widget.isAdding,
        title: Text(
          title,
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit, color: Colors.black),
            onPressed: _toggleEditingOrSave,
          ),
          if (_isEditing && !widget.isAdding)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 80,
                      backgroundImage: _imagePath != null && _imagePath!.isNotEmpty
                          ? AssetImage(_imagePath!)
                          : null,
                      child: _imagePath == null || _imagePath!.isEmpty
                          ? const Icon(Icons.person, size: 80)
                          : null,
                    ),
                    if (_isEditing)
                      GestureDetector(
                        onTap: _showImageOptions,
                        child: const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.edit, color: Colors.black, size: 20),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!_isEditing)
                Text(
                  '${_nameController.text} ${_surnameController.text}',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
              if (_isEditing)
                Row(
                  children: [
                    Expanded(child: _buildEditableItem('Name', _nameController)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildEditableItem('Surname', _surnameController)),
                  ],
                ),
              const SizedBox(height: 20),
              _buildDetailItem(Icons.cake, 'Age', _ageController),
              _buildDetailItem(Icons.work, 'Position', _positionController),
              _buildDetailItem(Icons.phone, 'Phone 1', _phone1Controller),
              _buildDetailItem(
                  Icons.phone_android, 'Phone 2', _phone2Controller),
              _buildPassportItem(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassportItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.badge, size: 28, color: Colors.grey[700]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Passport',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                _isEditing
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _passportSeriesController,
                              decoration: const InputDecoration(
                                  labelText: 'Series', counterText: ""),
                              maxLength: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 5,
                            child: TextField(
                              controller: _passportNumberController,
                              decoration: const InputDecoration(
                                  labelText: 'Number', counterText: ""),
                              keyboardType: TextInputType.number,
                              maxLength: 7,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        ('${_passportSeriesController.text} ${_passportNumberController.text}')
                                .trim()
                                .isNotEmpty
                            ? '${_passportSeriesController.text} ${_passportNumberController.text}'
                                .trim()
                            : 'Not specified',
                        style: const TextStyle(fontSize: 16),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableItem(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildDetailItem(
      IconData icon, String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Colors.grey[700]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                _isEditing
                    ? TextField(
                        controller: controller,
                        style: const TextStyle(fontSize: 16),
                      )
                    : Text(
                        controller.text.isNotEmpty
                            ? controller.text
                            : 'Not specified',
                        style: const TextStyle(fontSize: 16),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
