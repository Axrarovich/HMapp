import 'package:comply/screens/services_screen/add_edit_room_screen.dart';
import 'package:comply/services/room_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
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
            padding: const EdgeInsets.only(top: 10, bottom: 20),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddEditRoomScreen(room: room)),
                    ).then((_) => _fetchRooms());
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.meeting_room_outlined, color: Colors.blue, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    room.roomNumber ?? 'No Number',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (room.capacity != null && room.capacity!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.people_outline, size: 14, color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Text(
                                            room.capacity!,
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${NumberFormat("#,###").format(room.price).replaceAll(",", " ")} UZS',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.circle, 
                          color: room.isAvailable ? Colors.green : Colors.grey.shade300, 
                          size: 12
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
