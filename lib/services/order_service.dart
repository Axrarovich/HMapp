import 'dart:convert';
import 'package:comply/config/constants.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class OrderService {
  final String _ordersUrl = '$baseUrl/orders';
  final AuthService _authService = AuthService();

  Future<void> createOrder({required int masterId, required int roomId, String? description}) async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse(_ordersUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'master_id': masterId,
        'room_id': roomId,
        'description': description,
      }),
    );

    if (response.statusCode != 201) {
      final errorBody = jsonDecode(response.body);
      throw Exception('Failed to create order: ${errorBody['message']}');
    }
  }

  Future<List<dynamic>> getOrders() async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse(_ordersUrl),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load orders: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status) async {
    final token = await _authService.getToken();
    final response = await http.put(
      Uri.parse('$_ordersUrl/$orderId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'status': status,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update order status: ${response.body}');
    }
  }
}
