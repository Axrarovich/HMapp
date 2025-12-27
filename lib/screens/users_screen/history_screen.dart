import 'package:comply/screens/users_screen/create_review_screen.dart';
import 'package:comply/services/order_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] ?? '',
      description: json['description'],
      masterFirstName: json['master_first_name'] ?? 'Master',
      masterLastName: json['master_last_name'] ?? '',
      masterId: json['master_id'] ?? 0,
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
  List<UserOrder> _orders = [];
  bool _isLoading = true;
  String? _error;
  
  // Selection and Deletion state
  List<String> _hiddenOrderIds = [];
  Set<int> _selectedOrderIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadHiddenOrders();
    _fetchOrders();
  }

  Future<void> _loadHiddenOrders() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hiddenOrderIds = prefs.getStringList('hidden_history_ids') ?? [];
    });
  }

  Future<void> _saveHiddenOrders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('hidden_history_ids', _hiddenOrderIds);
  }

  void _fetchOrders() {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    _orderService.getOrders().then((data) {
      if (mounted) {
        setState(() {
          _orders = data.map((item) => UserOrder.fromJson(item)).toList();
          _isLoading = false;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      }
    });
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

  void _selectAll() {
    final visibleOrders = _getVisibleOrders();
    setState(() {
      if (_selectedOrderIds.length == visibleOrders.length) {
        // Optional: Deselect all if already all selected, but requirement says "All puts checks"
        // so maybe just ensure all are selected.
        // If user presses All again, usually it doesn't toggle off unless logic says so.
        // I'll ensure all are selected.
      }
      _selectedOrderIds = visibleOrders.map((o) => o.id).toSet();
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedOrderIds.isEmpty) return;
    
    setState(() {
      _hiddenOrderIds.addAll(_selectedOrderIds.map((id) => id.toString()));
      _selectedOrderIds.clear();
      _isSelectionMode = false;
    });
    await _saveHiddenOrders();
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
    if (dateStr.isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      return DateFormat.yMMMd().add_jm().format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }
  
  List<UserOrder> _getVisibleOrders() {
    // Filter orders to show only Approved (accepted, in_progress, completed) and Cancelled
    // And exclude hidden ones
    return _orders.where((order) {
      final isStatusRelevant = ['accepted', 'in_progress', 'completed', 'cancelled'].contains(order.status);
      final isNotHidden = !_hiddenOrderIds.contains(order.id.toString());
      return isStatusRelevant && isNotHidden;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibleOrders = _getVisibleOrders();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: _isSelectionMode ? IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            setState(() {
              _isSelectionMode = false;
              _selectedOrderIds.clear();
            });
          },
        ) : null,
        title: const Text('History',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
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
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _error != null 
          ? Center(child: Text('Error: $_error'))
          : visibleOrders.isEmpty
            ? const Center(
                child: Text(
                  'You have no orders in history.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => _fetchOrders(),
                child: ListView.builder(
                  itemCount: visibleOrders.length,
                  itemBuilder: (context, index) {
                    final order = visibleOrders[index];
                    final isSelected = _selectedOrderIds.contains(order.id);

                    return GestureDetector(
                      onTap: _isSelectionMode ? () => _toggleSelection(order.id) : null,
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Stack(
                          children: [
                            Padding(
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
                                      if (!_isSelectionMode) // Hide status badge if selection mode to avoid overlap? Or keep it?
                                                             // User said "yuqori o'ng burchagiga galochka".
                                                             // If I put checkbox at top right, it might overlap status.
                                                             // I'll keep status but maybe move it or just let checkbox cover it/sit next to it.
                                                             // To follow request strictly, checkmark field appears.
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
                                      else
                                        const SizedBox(height: 24), // Placeholder to prevent jumping layout too much
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  Text(
                                    'Master: ${order.masterFirstName} ${order.masterLastName}',
                                     style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${order.description ?? 'No description'}',
                                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                     _formatDate(order.createdAt),
                                     style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  if (order.status == 'completed' && !_isSelectionMode) ...[
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
                            if (_isSelectionMode)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: InkWell(
                                  onTap: () => _toggleSelection(order.id),
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
                                        : const Icon(null, size: 16), // Empty space
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
