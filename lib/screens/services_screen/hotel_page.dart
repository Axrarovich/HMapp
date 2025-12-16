import 'package:comply/screens/services_screen/add_edit_room_screen.dart';
import 'package:comply/services/room_service.dart';
import 'package:flutter/material.dart';

// Re-using the Room model from map_screen.dart would be better, but for simplicity, defining it here.
class Room {
    final int id;
    final String? roomNumber;
    final String? description;
    final double price;
    final String? imageUrl;
    final bool isAvailable;
    final String? capacity;

    Room({ required this.id, this.roomNumber, this.description, required this.price, this.imageUrl, required this.isAvailable, this.capacity });

    factory Room.fromJson(Map<String, dynamic> json) {
        return Room(
            id: json['id'],
            roomNumber: json['room_number'],
            description: json['description'],
            price: double.tryParse(json['price'].toString()) ?? 0.0,
            imageUrl: json['image_url'],
            isAvailable: json['is_available'] == 1,
            capacity: json['capacity']?.toString(),
        );
    }
}

class ManageRoomsScreen extends StatefulWidget {
  const ManageRoomsScreen({Key? key}) : super(key: key);

  @override
  State<ManageRoomsScreen> createState() => _ManageRoomsScreenState();
}

class _ManageRoomsScreenState extends State<ManageRoomsScreen> {
  final RoomService _roomService = RoomService();
  late Future<List<Room>> _roomsFuture;

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  void _fetchRooms() {
    setState(() {
      _roomsFuture = _roomService.getMyRooms().then((data) => data.map((r) => Room.fromJson(r)).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Rooms',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddEditRoomScreen()),
              ).then((_) => _fetchRooms());
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Room>>(
        future: _roomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('You have not added any rooms yet.'));
          }

          final rooms = snapshot.data!;
          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(room.roomNumber ?? 'No name'),
                  subtitle: Text('${room.price.toStringAsFixed(0)} UZS'),
                  trailing: Icon(Icons.circle, color: room.isAvailable ? Colors.green : Colors.grey, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddEditRoomScreen(room: room)),
                    ).then((_) => _fetchRooms());
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
