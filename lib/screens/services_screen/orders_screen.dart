import 'package:comply/screens/services_screen/dashboarding_screen.dart';
import 'package:comply/screens/services_screen/hotel_page.dart'; // This file now contains ManageRoomsScreen
import 'package:comply/screens/services_screen/master_messages_screen.dart';
import 'package:flutter/material.dart';
import 'master_settings.dart';

class OrdersPanelScreen extends StatefulWidget {
  const OrdersPanelScreen({Key? key}) : super(key: key);

  @override
  State<OrdersPanelScreen> createState() => _OrdersPanelScreenState();
}

class _OrdersPanelScreenState extends State<OrdersPanelScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    DashboardingScreen(),
    MasterMessagesScreen(),
    ManageRoomsScreen(),
    MasterSettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sms),
            label: 'Reviews',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hotel),
            label: 'Rooms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
