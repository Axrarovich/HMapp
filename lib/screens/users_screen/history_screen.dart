import 'package:comply/screens/users_screen/create_review_screen.dart';
import 'package:comply/services/order_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserOrder {
  final int id;
  final String status;
  final String createdAt;
  final String? description;
  final String masterFirstName;
  final String masterLastName;
  final int masterId;

  UserOrder({
    required this.id,
    required this.status,
    required this.createdAt,
    this.description,
    required this.masterFirstName,
    required this.masterLastName,
    required this.masterId
  });

  factory UserOrder.fromJson(Map<String, dynamic> json) {
    return UserOrder(
      id: json['id'],
      status: json['status'],
      createdAt: json['created_at'],
      description: json['description'],
      masterFirstName: json['master_first_name'] ?? 'Master',
      masterLastName: json['master_last_name'] ?? '',
      masterId: json['master_id'],
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final OrderService _orderService = OrderService();
  late Future<List<UserOrder>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  void _fetchOrders() {
     setState(() {
      _ordersFuture = _orderService.getOrders()
          .then((data) => data.map((item) => UserOrder.fromJson(item)).toList());
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'accepted':
      case 'in_progress':
        return Colors.blue;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

 String _formatDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      return DateFormat.yMMMd().add_jm().format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Order History',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<UserOrder>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'You have no orders yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final orders = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => _fetchOrders(),
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Text(
                              'Order #${order.id}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order.status).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                order.status.toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(order.status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          ],
                        ),
                        const Divider(height: 20),
                        Text(
                          'Master: ${order.masterFirstName} ${order.masterLastName}',
                           style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${order.description}',
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        Text(
                           _formatDate(order.createdAt),
                           style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        if (order.status == 'completed') ...[
                           const SizedBox(height: 16),
                           SizedBox(
                            width: double.infinity,
                             child: OutlinedButton.icon(
                               icon: const Icon(Icons.rate_review_outlined),
                               label: const Text('Leave a Review'),
                               onPressed: () async {
                                 final result = await Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                     builder: (context) => CreateReviewScreen(
                                       masterId: order.masterId,
                                       orderId: order.id,
                                     ),
                                   ),
                                 );
                                 // We could refresh if a review was successfully posted,
                                 // but for now, we just wait for the user to pull-to-refresh.
                               },
                               style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Theme.of(context).primaryColor),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                               ),
                             ),
                           )
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
