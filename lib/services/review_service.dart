import 'dart:convert';
import 'package:comply/config/constants.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ReviewService {
  final String _reviewsUrl = '$baseUrl/reviews';
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> createReview(int masterId, int orderId, int rating, String comment) async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse(_reviewsUrl),
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
      final errorBody = jsonDecode(response.body);
      throw Exception('Failed to create review: ${errorBody['message']}');
    }
  }

  Future<List<dynamic>> getReviewsForMaster(int masterId) async {
    final response = await http.get(Uri.parse('$_reviewsUrl/$masterId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load reviews');
    }
  }
}
