import 'dart:convert';
import 'package:comply/config/constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String _registerUrl = '$baseUrl/users/register';
  final String _loginUrl = '$baseUrl/users/login';
  final String _updateUserUrl = '$baseUrl/users/'; // Will append user ID

  Future<Map<String, dynamic>> register(String firstName, String? lastName, String login, String password, String role) async {
    final response = await http.post(
      Uri.parse(_registerUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String?>{
        'first_name': firstName,
        'last_name': lastName,
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
      final errorBody = jsonDecode(response.body);
      throw Exception('Failed to register: ${errorBody['message']}');
    }
  }

  Future<Map<String, dynamic>> login(String login, String password) async {
    final response = await http.post(
      Uri.parse(_loginUrl),
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
      final errorBody = jsonDecode(response.body);
      throw Exception('Failed to login: ${errorBody['message']}');
    }
  }

  Future<Map<String, dynamic>> updateUser(int userId, String firstName, String? lastName, String login, String? password) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$_updateUserUrl$userId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String?>{
        'first_name': firstName,
        'last_name': lastName,
        'login': login,
        if (password != null && password.isNotEmpty) 'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveUserData(data);
      return data;
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception('Failed to update profile: ${errorBody['message']}');
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    if (data.containsKey('token')) {
          await prefs.setString('token', data['token']);
    }
    await prefs.setString('first_name', data['first_name']);
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

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
