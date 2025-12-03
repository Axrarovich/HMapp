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

    Room({ required this.id, this.roomNumber, this.description, required this.price, this.imageUrl, required this.isAvailable });

    factory Room.fromJson(Map<String, dynamic> json) {
        return Room(
            id: json['id'],
            roomNumber: json['room_number'],
            description: json['description'],
            price: double.tryParse(json['price'].toString()) ?? 0.0,
            imageUrl: json['image_url'],
            isAvailable: json['is_available'] == 1,
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

  Future<void> _deleteRoom(int roomId) async {
      try {
          await _roomService.deleteRoom(roomId);
          _fetchRooms(); // Refresh list
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room deleted')));
      } catch(e) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete room: $e')));
      }
  }

  void _showEditRoomDialog({Room? room}) {
    final _formKey = GlobalKey<FormState>();
    final _roomNumberController = TextEditingController(text: room?.roomNumber);
    final _priceController = TextEditingController(text: room?.price.toString());
    final _descriptionController = TextEditingController(text: room?.description);
    bool isAvailable = room?.isAvailable ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(room == null ? 'Add Room' : 'Edit Room'),
          content: StatefulBuilder( // To update the switch inside the dialog
            builder: (BuildContext context, StateSetter setState) {
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _roomNumberController,
                        decoration: const InputDecoration(labelText: 'Room Name / Number'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'Price per night (UZS)'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Description'),
                      ),
                      SwitchListTile(
                        title: const Text('Available'),
                        value: isAvailable,
                        onChanged: (val) => setState(() => isAvailable = val),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final roomData = {
                    'room_number': _roomNumberController.text,
                    'price': _priceController.text,
                    'description': _descriptionController.text,
                    'is_available': isAvailable,
                  };

                  try {
                    if (room == null) { // Create new room
                      await _roomService.createRoom(roomData);
                    } else { // Update existing room
                      await _roomService.updateRoom(room.id, roomData);
                    }
                     _fetchRooms(); // Refresh the list
                     Navigator.of(context).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
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
            onPressed: () => _showEditRoomDialog(),
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: room.isAvailable ? Colors.green : Colors.grey, size: 14),
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showEditRoomDialog(room: room)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteRoom(room.id)),
                    ],
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
