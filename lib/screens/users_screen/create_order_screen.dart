import 'package:comply/services/order_service.dart';
import 'package:flutter/material.dart';

class CreateOrderScreen extends StatefulWidget {
  final int masterId;
  final int roomId; // Added roomId parameter

  const CreateOrderScreen({
    Key? key,
    required this.masterId,
    required this.roomId, // Make it required
  }) : super(key: key);

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _orderService = OrderService();
  bool _isSending = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSending = true;
      });

      try {
        // Calling the updated service method with named parameters
        await _orderService.createOrder(
          masterId: widget.masterId,
          roomId: widget.roomId, 
          description: _descriptionController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order created successfully! You can track it in the History tab.')),
          );
          // Pop two times to go back to the map screen
          int count = 0;
          Navigator.of(context).popUntil((_) => count++ >= 2);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create order: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSending = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Booking'), // Changed title
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please enter any special requests for your booking (optional):',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Special Requests',
                  hintText: 'e.g., late check-in, extra towels',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                // Validator is removed, as the description is now optional
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: _isSending
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _submitOrder,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Confirm and Book'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
