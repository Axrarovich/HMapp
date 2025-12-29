import 'package:comply/services/order_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
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

  List<Order> _allOrders = [];
  bool _isLoading = true;

  // Selection and Deletion state
  List<String> _hiddenOrderIds = [];
  Set<int> _selectedOrderIds = {};
  bool _isSelectionMode = false;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // All, Approved, Cancelled
    _tabController.addListener(() {
      if (mounted) {
        // Automatically exit selection mode if switching to All tab
        if (_tabController.index == 0 && _isSelectionMode) {
           _isSelectionMode = false;
           _selectedOrderIds.clear();
        }
        setState(() {});
      }
    });
    _loadHiddenOrders();
    _fetchOrders();
  }

  Future<String> _getPrefsKey() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId != null) {
      return 'hidden_dashboard_ids_$userId';
    }
    return 'hidden_dashboard_ids_general';
  }

  Future<void> _loadHiddenOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getPrefsKey();
      final loadedIds = prefs.getStringList(key) ?? [];
      
      if (mounted) {
        setState(() {
          _hiddenOrderIds = loadedIds;
        });
      }
    } catch (e) {
      debugPrint('Error loading hidden orders: $e');
    }
  }

  Future<void> _saveHiddenOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getPrefsKey();
      await prefs.setStringList(key, _hiddenOrderIds);
    } catch (e) {
      debugPrint('Error saving hidden orders: $e');
    }
  }

  void _fetchOrders() {
    setState(() {
      _isLoading = true;
    });
    _orderService.getOrders().then((data) {
      if (mounted) {
        setState(() {
          _allOrders = data.map((item) => Order.fromJson(item)).toList();
          _isLoading = false;
        });
      }
    }).catchError((e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load orders: $e')),
        );
      }
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

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedOrderIds.contains(id)) {
        _selectedOrderIds.remove(id);
      } else {
        _selectedOrderIds.add(id);
      }
    });
  }

  List<Order> _getVisibleOrdersForCurrentTab() {
    List<String>? statuses;
    if (_tabController.index == 0) {
      statuses = ['pending', 'accepted', 'in_progress'];
    } else if (_tabController.index == 1) {
      statuses = ['completed'];
    } else if (_tabController.index == 2) {
      statuses = ['cancelled'];
    }

    return _allOrders.where((order) {
      bool statusMatch = statuses == null || statuses.contains(order.status);
      bool notHidden = !_hiddenOrderIds.contains(order.id.toString());
      return statusMatch && notHidden;
    }).toList();
  }

  void _selectAll() {
    final visible = _getVisibleOrdersForCurrentTab();
    setState(() {
      bool allSelected = visible.isNotEmpty && visible.every((o) => _selectedOrderIds.contains(o.id));
      
      if (allSelected) {
        for (var o in visible) _selectedOrderIds.remove(o.id);
      } else {
        for (var o in visible) _selectedOrderIds.add(o.id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedOrderIds.isEmpty) return;
    
    final newHiddenIds = _selectedOrderIds.map((id) => id.toString()).toList();
    final updatedHiddenList = {..._hiddenOrderIds, ...newHiddenIds}.toList();

    setState(() {
      _hiddenOrderIds = updatedHiddenList;
      _selectedOrderIds.clear();
      _isSelectionMode = false;
    });
    
    await _saveHiddenOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        automaticallyImplyLeading: false,
        leading: (_isSelectionMode && _tabController.index != 0) ? IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            setState(() {
              _isSelectionMode = false;
              _selectedOrderIds.clear();
            });
          },
        ) : null,
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: _tabController.index == 0 ? [] : [
          if (_isSelectionMode)
            TextButton(
              onPressed: _selectAll,
              child: const Text('All', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          TextButton(
            onPressed: () {
              if (_isSelectionMode) {
                _deleteSelected();
              } else {
                setState(() {
                  _isSelectionMode = true;
                });
              }
            },
            child: Text(
              _isSelectionMode ? 'Clear' : 'Clear', 
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Approved'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList(['pending', 'accepted', 'in_progress']), // All: New and Unfinished
              _buildOrderList(['completed']), // Approved: Finished
              _buildOrderList(['cancelled']), // Cancelled: Rejected
            ],
          ),
    );
  }

  Widget _buildOrderList(List<String>? statuses) {
    // Filter by status
    final statusFilteredOrders = statuses == null 
        ? _allOrders 
        : _allOrders.where((order) => statuses.contains(order.status)).toList();

    // Filter by hidden
    final filteredOrders = statusFilteredOrders.where((order) => !_hiddenOrderIds.contains(order.id.toString())).toList();

    if (filteredOrders.isEmpty) {
      String statusText = "orders";
      if (statuses != null) {
        if (statuses.contains('cancelled') && statuses.length == 1) statusText = "cancelled orders";
        else if (statuses.contains('completed') && statuses.length == 1) statusText = "completed orders";
      }
      return Center(child: Text("There are no $statusText."));
    }

    return ListView.builder(
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        final isSelected = _selectedOrderIds.contains(order.id);

        return GestureDetector(
          onTap: _isSelectionMode ? () => _toggleSelection(order.id) : null,
          child: Card(
            margin: const EdgeInsets.all(8.0),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order: ${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                      if (!_isSelectionMode) _buildActionButtons(order),
                    ],
                  ),
                ),
                if (_isSelectionMode)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.blue : Colors.transparent,
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: isSelected 
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : const Icon(null, size: 16), 
                        ),
                      ),
                    ),
                  ),
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
              onPressed: () => _updateOrderStatus(order, 'completed'),
              child: const Text('Finish'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
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
