import 'dart:convert';
import 'package:comply/config/constants.dart';
import 'package:comply/services/auth_service.dart';
import 'package:http/http.dart' as http;

class RoomService {
  final String _roomsUrl = '$baseUrl/rooms';
  final AuthService _authService = AuthService();

  // For Masters: Get their own rooms
  Future<List<dynamic>> getMyRooms() async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('$_roomsUrl/master'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load rooms: ${response.body}');
    }
  }

  // For Users: Get rooms for a specific place
  Future<List<dynamic>> getRoomsForPlace(int masterId) async {
    final response = await http.get(Uri.parse('$_roomsUrl/place/$masterId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load rooms: ${response.body}');
    }
  }

  // For Masters: Create a room
  Future<void> createRoom(Map<String, dynamic> roomData) async {
     final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse(_roomsUrl),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(roomData),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create room: ${response.body}');
    }
  }

  // For Masters: Update a room
  Future<void> updateRoom(int roomId, Map<String, dynamic> roomData) async {
    final token = await _authService.getToken();
    final response = await http.put(
      Uri.parse('$_roomsUrl/$roomId'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(roomData),
    );
     if (response.statusCode != 200) {
      throw Exception('Failed to update room: ${response.body}');
    }
  }

   // For Masters: Delete a room
  Future<void> deleteRoom(int roomId) async {
    final token = await _authService.getToken();
    final response = await http.delete(
      Uri.parse('$_roomsUrl/$roomId'),
       headers: {'Authorization': 'Bearer $token'},
    );
     if (response.statusCode != 200) {
      throw Exception('Failed to delete room: ${response.body}');
    }
  }
}
