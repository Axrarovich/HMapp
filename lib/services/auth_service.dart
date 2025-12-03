import 'dart:convert';
import 'dart:io';
import 'package:comply/config/constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String _registerUrl = '$baseUrl/users/register';
  final String _loginUrl = '$baseUrl/users/login';
  final String _updateUserUrl = '$baseUrl/users/profile';
  final String _deleteUserUrl = '$baseUrl/users/profile'; // Same URL, but DELETE method
  final String _checkLoginUrl = '$baseUrl/users/check-login';

  Future<bool> checkLogin(String login) async {
    final response = await http.get(Uri.parse('$_checkLoginUrl/$login'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['exists'];
    } else {
      throw Exception('Failed to check login');
    }
  }

  Future<Map<String, dynamic>> register(
    String firstName,
    String? lastName,
    String login,
    String password,
    String role, {
    Map<String, dynamic>? masterData,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse(_registerUrl));

    request.fields['first_name'] = firstName;
    if (lastName != null) {
      request.fields['last_name'] = lastName;
    }
    request.fields['login'] = login;
    request.fields['password'] = password;
    request.fields['role'] = role;

    if (masterData != null) {
      masterData.forEach((key, value) {
        if (key != 'image' && value != null) {
          request.fields[key] = value.toString();
        }
      });

      if (masterData.containsKey('image') && masterData['image'] is File) {
        File imageFile = masterData['image'];
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      }
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

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

  Future<Map<String, dynamic>> updateUser(String firstName, String? lastName, String login, String? password) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse(_updateUserUrl),
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
      try {
        final errorBody = jsonDecode(response.body);
        throw Exception('Failed to update profile: ${errorBody['message']}');
      } catch (e) {
        throw Exception('Failed to update profile: ${response.body}');
      }
    }
  }

  Future<void> deleteUser() async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse(_deleteUserUrl),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      try {
        final errorBody = jsonDecode(response.body);
        throw Exception('Failed to delete account: ${errorBody['message']}');
      } catch (e) {
        throw Exception('Failed to delete account: ${response.body}');
      }
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    if (data.containsKey('token')) {
          await prefs.setString('token', data['token']);
    }
    if (data.containsKey('first_name')) {
      await prefs.setString('first_name', data['first_name']);
    }
    if (data.containsKey('last_name') && data['last_name'] != null) {
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
