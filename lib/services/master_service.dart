import 'dart:convert';
import 'dart:io';
import 'package:comply/config/constants.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class MasterService {
  final String _mastersUrl = '$baseUrl/masters';
  final AuthService _authService = AuthService();

  Future<List<dynamic>> getMasters() async {
    final response = await http.get(Uri.parse(_mastersUrl));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load masters');
    }
  }

  Future<Map<String, dynamic>> getMasterById(int id) async {
    final response = await http.get(Uri.parse('$_mastersUrl/$id'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load master');
    }
  }

  Future<Map<String, dynamic>> getMasterProfile() async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('$_mastersUrl/profile'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load master profile: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateMasterProfile(Map<String, dynamic> data) async {
    final token = await _authService.getToken();
    final response = await http.put(
      Uri.parse('$_mastersUrl/profile'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  Future<void> updateMasterPassword(String oldPassword, String newPassword) async {
    final token = await _authService.getToken();
    final response = await http.put(
      Uri.parse('$_mastersUrl/profile/password'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final responseBody = jsonDecode(response.body);
      throw Exception('Failed to update password: ${responseBody['message']}');
    }
  }

  Future<String> uploadImage(File imageFile) async {
    final token = await _authService.getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      return jsonDecode(responseBody)['imageUrl'];
    } else {
      throw Exception('Failed to upload image');
    }
  }

  Future<void> deleteMasterAccount(String password) async {
    final token = await _authService.getToken();
    final response = await http.delete(
      Uri.parse('$_mastersUrl/profile'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'password': password}),
    );

    if (response.statusCode != 200) {
      final responseBody = jsonDecode(response.body);
      throw Exception('Failed to delete account: ${responseBody['message']}');
    }
  }
}
