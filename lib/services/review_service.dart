import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ReviewService {
  final String _baseUrl = 'http://10.0.2.2:5000/api';
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> createReview(int masterId, int orderId, int rating, String comment) async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/reviews'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'master_id': masterId,
        'order_id': orderId,
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create review: ${response.body}');
    }
  }

  Future<List<dynamic>> getReviewsForMaster(int masterId) async {
    final response = await http.get(Uri.parse('$_baseUrl/reviews/$masterId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load reviews');
    }
  }
}
