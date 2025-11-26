import 'dart:convert';
import 'package:http/http.dart' as http;

class CategoryService {
  final String _baseUrl = 'http://10.0.2.2:5000/api';

  Future<List<dynamic>> getCategories() async {
    final response = await http.get(Uri.parse('$_baseUrl/categories'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load categories');
    }
  }
}
