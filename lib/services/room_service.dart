import 'dart:convert';
import 'dart:io';
import 'package:comply/config/constants.dart';
import 'package:comply/services/auth_service.dart';
import 'package:http/http.dart' as http;

class RoomService {
  final String _roomsUrl = '$baseUrl/rooms';
  final AuthService _authService = AuthService();

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

  Future<List<dynamic>> getRoomsForPlace(int masterId) async {
    final response = await http.get(Uri.parse('$_roomsUrl/place/$masterId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load rooms: ${response.body}');
    }
  }

  Future<void> createRoom(Map<String, String> roomData, File? image) async {
    final token = await _authService.getToken();
    var request = http.MultipartRequest('POST', Uri.parse(_roomsUrl));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(roomData);
    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }

    var response = await request.send();
    if (response.statusCode != 201) {
      final responseBody = await response.stream.bytesToString();
      throw Exception('Failed to create room: $responseBody');
    }
  }

  Future<void> updateRoom(int roomId, Map<String, String> roomData, File? image) async {
    final token = await _authService.getToken();
    final uri = Uri.parse('$_roomsUrl/$roomId');

    // Always send as multipart, even if the image isn't changing.
    var request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(roomData);

    // Add the new image file if it exists.
    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }

    var streamedResponse = await request.send();

    if (streamedResponse.statusCode != 200) {
      // Consume the stream to get the response body
      final responseBody = await streamedResponse.stream.bytesToString();
      throw Exception('Failed to update room: $responseBody');
    } else {
      // Important: even on success, we must consume the stream if we don't return the body,
      // though typically stream.bytesToString() is used for reading body.
      // If we don't read it, it's generally okay for small responses, but reading it ensures full completion.
       await streamedResponse.stream.bytesToString();
    }
  }

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
