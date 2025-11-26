import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({Key? key}) : super(key: key);

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  // I will create a dummy list of rooms for demonstration
  List<Map<String, dynamic>> rooms = [
    {
      "roomNumber": 1,
      "roomInfo": "Single room",
      "price": "500,000 soums",
      "duration": "Daily",
      "additional": ["Wifi", "Lux"],
      "images": [
        'assets/images/hotel.jpg',
      ],
    },
    {
      "roomNumber": 2,
      "roomInfo": "Double room",
      "price": "700,000 soums",
      "duration": "Daily",
      "additional": ["Wifi"],
      "images": [
        'assets/images/hotel.jpg',
        'assets/images/hotel1.jpg',
      ],
    },
    {
      "roomNumber": 3,
      "roomInfo": "Triple room",
      "price": "1,200,000 soums",
      "duration": "Daily",
      "additional": ["Wifi", "Lux", "TV"],
      "images": [
        'assets/images/hotel.jpg',
        'assets/images/hotel1.jpg',
        'assets/images/hotel.jpg',
      ],
    },
    {
      "roomNumber": 4,
      "roomInfo": "For 4 people",
      "price": "1,200,000 soums",
      "duration": "Daily",
      "additional": ["Wifi", "TV"],
      "images": [
        'assets/images/hotel.jpg',
        'assets/images/hotel1.jpg',
        'assets/images/hotel.jpg',
        'assets/images/hotel1.jpg',
      ],
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: rooms.map((room) {
                  final int index = rooms.indexOf(room);
                  final String roomName =
                      '${room["roomNumber"]}-room, ${room["roomInfo"]}';
                  return Column(
                    children: [
                      _buildRoomItem(
                        context,
                        icon: Icons.hotel_outlined,
                        title: roomName,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GalleryScreen(room: room),
                            ),
                          );
                          if (result != null) {
                            if (result['deleted'] == true) {
                              setState(() {
                                rooms.remove(room);
                              });
                            } else {
                              setState(() {
                                final roomIndex = rooms.indexOf(room);
                                if (roomIndex != -1) {
                                  rooms[roomIndex] = result;
                                }
                              });
                            }
                          }
                        },
                      ),
                      if (index < rooms.length - 1)
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final newRoomData = {
                  "roomNumber": rooms.length + 1,
                  "roomInfo": "",
                  "price": "",
                  "duration": "",
                  "additional": <String>[],
                  "images": []
                };

                final newRoom = await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GalleryScreen(room: newRoomData, isNewRoom: true),
                  ),
                );

                if (newRoom != null) {
                  setState(() {
                    rooms.add(newRoom);
                  });
                }
              },
              icon: const Icon(Icons.add),
              label: const Text("Add a new room"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRoomItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        Widget? trailing,
        required VoidCallback onTap,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
              trailing ?? Icon(Icons.chevron_right, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }
}

class GalleryScreen extends StatefulWidget {
  final Map<String, dynamic> room;
  final bool isNewRoom;

  const GalleryScreen({Key? key, required this.room, this.isNewRoom = false}) : super(key: key);

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late Map<String, dynamic> _currentRoom;
  late List<dynamic> _images;
  final ImagePicker _picker = ImagePicker();
  late bool _isEditing;
  late TextEditingController _roomNumberController;
  late TextEditingController _roomInfoController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;
  late TextEditingController _additionalController;

  @override
  void initState() {
    super.initState();
    _currentRoom = Map<String, dynamic>.from(widget.room);
    _images = List.from(_currentRoom["images"]);
    _roomNumberController =
        TextEditingController(text: _currentRoom['roomNumber'].toString());
    _roomInfoController = TextEditingController(text: _currentRoom['roomInfo']);
    _priceController = TextEditingController(text: _currentRoom['price']);
    _durationController = TextEditingController(text: _currentRoom['duration']);
    _additionalController = TextEditingController(
        text: (_currentRoom['additional'] as List<String>).join(', '));
    _isEditing = widget.isNewRoom;
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    _roomInfoController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _additionalController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _images.add(File(image.path));
      });
    }
  }

  void _deletePhoto(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Widget _buildEditableInfoTile({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: !_isEditing,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blue),
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _isEditing ? Colors.blue : Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue),
        ),
      ),
    );
  }

  Future<bool> _onWillPop() {
    Navigator.pop(context, _currentRoom);
    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    final String roomName = widget.isNewRoom ? 'New room' : '${_currentRoom["roomNumber"]}-room';
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
          title: Text(
            roomName,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _currentRoom),
          ),
          actions: _isEditing
              ? [
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () {
                      final updatedRoom = {
                        "roomNumber": int.tryParse(_roomNumberController.text) ??
                            _currentRoom['roomNumber'],
                        "roomInfo": _roomInfoController.text,
                        "price": _priceController.text,
                        "duration": _durationController.text,
                        "additional": _additionalController.text
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList(),
                        "images": _images,
                      };

                      if (widget.isNewRoom) {
                        Navigator.pop(context, updatedRoom);
                      } else {
                        setState(() {
                          _currentRoom = updatedRoom;
                          _isEditing = false;
                        });
                      }
                    },
                  ),
                  if (!widget.isNewRoom)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Delete room'),
                              content: const Text(
                                  'Are you sure you want to delete this room?'),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: const Text('Delete'),
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pop(); // Close the dialog
                                    Navigator.pop(context,
                                        {'deleted': true}); // Pop GalleryScreen
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                ]
              : [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                  ),
                ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildEditableInfoTile(
                        label: 'Room Number',
                        controller: _roomNumberController,
                        icon: Icons.format_list_numbered,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildEditableInfoTile(
                        label: 'Room Information',
                        controller: _roomInfoController,
                        icon: Icons.info_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildEditableInfoTile(
                        label: 'Price',
                        controller: _priceController,
                        icon: Icons.monetization_on_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildEditableInfoTile(
                        label: 'Duration',
                        controller: _durationController,
                        icon: Icons.timelapse_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildEditableInfoTile(
                        label: 'Additional Features',
                        controller: _additionalController,
                        icon: Icons.add_circle_outline,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const Text(
                'Gallery',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _isEditing ? _images.length + 1 : _images.length,
                itemBuilder: (context, index) {
                  if (index == _images.length) {
                    return GestureDetector(
                      onTap: _addPhoto,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          color: Colors.grey[200],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                color: Colors.grey[800], size: 40),
                            const SizedBox(height: 8),
                            const Text(
                              "Add a picture",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final image = _images[index];
                  final heroTag = 'image$index';

                  return GestureDetector(
                    onTap: () {
                      if (!_isEditing) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullScreenImageViewer(
                              images: _images,
                              initialIndex: index,
                            ),
                          ),
                        );
                      }
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: heroTag,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: image is String
                                ? Image.asset(image, fit: BoxFit.cover)
                                : Image.file(image as File, fit: BoxFit.cover),
                          ),
                        ),
                        if (_isEditing)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _deletePhoto(index),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FullScreenImageViewer extends StatefulWidget {
  final List<dynamic> images;
  final int initialIndex;

  const FullScreenImageViewer(
      {Key? key, required this.images, required this.initialIndex})
      : super(key: key);

  @override
  _FullScreenImageViewerState createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          final image = widget.images[index];
          final heroTag = 'image$index';

          return GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Center(
              child: Hero(
                tag: heroTag,
                child: image is String
                    ? Image.asset(image)
                    : Image.file(image as File),
              ),
            ),
          );
        },
      ),
    );
  }
}
