import 'package:comply/services/order_service.dart';
import 'package:flutter/material.dart';

// Model for the order data from the backend
class Order {
  final int id;
  final int userId;
  final int masterId;
  final String? description;
  String status; // 'pending', 'accepted', 'in_progress', 'completed', 'cancelled'
  final String createdAt;
  final String updatedAt;

  // User details (optional, can be fetched separately or joined in backend)
  final String? userFirstName;
  final String? userLastName;


  Order({
    required this.id,
    required this.userId,
    required this.masterId,
    this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.userFirstName,
    this.userLastName,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      masterId: json['master_id'],
      description: json['description'],
      status: json['status'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
       // These might not be in the order object directly, handle nulls
      userFirstName: json['user_first_name'],
      userLastName: json['user_last_name'],
    );
  }
}

class DashboardingScreen extends StatefulWidget {
  const DashboardingScreen({Key? key}) : super(key: key);

  @override
  State<DashboardingScreen> createState() => _DashboardingScreenState();
}

class _DashboardingScreenState extends State<DashboardingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();

  Future<List<Order>>? _ordersFuture;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // pending, accepted, in_progress, completed, cancelled
    _fetchOrders();
  }

  void _fetchOrders() {
    setState(() {
      _ordersFuture = _orderService.getOrders().then((data) => data.map((item) => Order.fromJson(item)).toList());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateOrderStatus(Order order, String newStatus) async {
    try {
      await _orderService.updateOrderStatus(order.id, newStatus);
      _fetchOrders(); // Refresh the list after updating
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Orders Dashboard',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Accepted'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No orders found.'));
          }

          final allOrders = snapshot.data!;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList(allOrders, 'pending'),
              _buildOrderList(allOrders, 'accepted'),
              _buildOrderList(allOrders, 'in_progress'),
              _buildOrderList(allOrders, 'completed'),
              _buildOrderList(allOrders, 'cancelled'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderList(List<Order> allOrders, String status) {
    final filteredOrders =
    allOrders.where((order) => order.status == status).toList();

    if (filteredOrders.isEmpty) {
      return Center(child: Text("There are no $status orders."));
    }

    return ListView.builder(
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order ID: ${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                 // You might want to fetch user details to display name
                Text('User ID: ${order.userId}'),
                const SizedBox(height: 8),
                Text('Description: ${order.description ?? 'N/A'}'),
                const Divider(height: 32, thickness: 1),
                Text('Status: ${order.status}'),
                 const SizedBox(height: 8),
                Text('Created at: ${order.createdAt}'),
                const SizedBox(height: 16),
                _buildActionButtons(order),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(Order order) {
    // Depending on the user role (master) and order status, show different buttons.
    switch (order.status) {
      case 'pending':
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () => _updateOrderStatus(order, 'accepted'),
              child: const Text('Accept'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _updateOrderStatus(order, 'cancelled'),
              child: const Text('Cancel'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        );
      case 'accepted':
        return Row(
           mainAxisAlignment: MainAxisAlignment.end,
           children: [
            ElevatedButton(
              onPressed: () => _updateOrderStatus(order, 'in_progress'),
              child: const Text('Start Work'),
            ),
             const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _updateOrderStatus(order, 'cancelled'),
              child: const Text('Cancel'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
           ]
        );
      case 'in_progress':
         return Row(
           mainAxisAlignment: MainAxisAlignment.end,
           children: [
            ElevatedButton(
              onPressed: () => _updateOrderStatus(order, 'completed'),
              child: const Text('Complete'),
            ),
           ]
        );
      default:
        return const SizedBox.shrink(); // No actions for 'completed' or 'cancelled'
    }
  }
}
