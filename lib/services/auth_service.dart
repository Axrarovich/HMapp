import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String _baseUrl = 'http://10.0.2.2:5000/api'; // For Android Emulator

  // Changed `String lastName` to `String? lastName` to make it optional
  Future<Map<String, dynamic>> register(String firstName, String? lastName, String login, String password, String role) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String?>{
        'first_name': firstName,
        'last_name': lastName, // Can now be null
        'login': login,
        'password': password,
        'role': role,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await _saveUserData(data);
      return data;
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> login(String login, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'login': login,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveUserData(data);
      return data;
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['token']);
    await prefs.setString('first_name', data['first_name']);
    // last_name can be null, so we handle it
    if (data['last_name'] != null) {
      await prefs.setString('last_name', data['last_name']);
    } else {
      await prefs.remove('last_name');
    }
    await prefs.setString('login', data['login']);
    await prefs.setString('role', data['role']);
    await prefs.setInt('user_id', data['id']);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all data on logout
  }
}
