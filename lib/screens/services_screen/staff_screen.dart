import 'package:comply/screens/services_screen/staff_detail_screen.dart';
import 'package:flutter/material.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({Key? key}) : super(key: key);

  @override
  _StaffScreenState createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final List<Map<String, String?>> staffList = [
    {
      'name': 'John',
      'surname': 'Doe',
      'imagePath': 'assets/images/worker.jpg',
      'age': '35',
      'position': 'Software Engineer',
      'phone1': '+998 90 123 45 67',
      'phone2': '+998 90 765 43 21',
      'passport': 'AB 1234567'
    },
    {
      'name': 'Jane',
      'surname': 'Smith',
      'imagePath': 'assets/images/worker.jpg',
      'age': '28',
      'position': 'Project Manager',
      'phone1': '+998 91 234 56 78',
      'phone2': '+998 91 876 54 32',
      'passport': 'AC 8765432'
    },
    {
      'name': 'Peter',
      'surname': 'Jones',
      'imagePath': 'assets/images/worker.jpg',
      'age': '42',
      'position': 'Lead Designer',
      'phone1': '+998 93 456 78 90',
      'phone2': '+998 93 098 76 54',
      'passport': 'AD 3456789'
    },
    {
      'name': 'Alice',
      'surname': 'Williams',
      'imagePath': 'assets/images/worker.jpg',
      'age': '31',
      'position': 'QA Specialist',
      'phone1': '+998 94 567 89 01',
      'phone2': '+998 94 109 87 65',
      'passport': 'AE 4567890'
    },
  ];

  void _addNewStaff(Map<String, String?> newStaff) {
    setState(() {
      staffList.add(newStaff);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Staff',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: staffList.length,
              separatorBuilder: (BuildContext context, int index) => const Divider(),
              itemBuilder: (context, index) {
                final staffMember = staffList[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage(staffMember['imagePath']!),
                  ),
                  title: Text('${staffMember['name']} ${staffMember['surname']}'),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            StaffDetailScreen(staffMember: staffMember),
                      ),
                    );

                    if (result == true) {
                      setState(() {
                        staffList.removeAt(index);
                      });
                    }
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final newStaff = await Navigator.push<Map<String, String?>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StaffDetailScreen(isAdding: true),
                    ),
                  );
                  if (newStaff != null) {
                    _addNewStaff(newStaff);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Add New Staff'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
