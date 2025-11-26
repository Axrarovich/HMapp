import 'dart:convert';
import 'package:http/http.dart' as http;
import 'place.dart';

class ApiService {
  static const String _baseUrl = 'localhost'; // O'zingizning server manzilingizni yozing

  Future<List<Place>> getPlaces() async {
    final response = await http.get(Uri.parse('$_baseUrl/places'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Place.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load places');
    }
  }
}
