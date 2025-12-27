import 'package:comply/services/order_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateOrderScreen extends StatefulWidget {
  final int masterId;
  final int roomId;

  const CreateOrderScreen({
    Key? key,
    required this.masterId,
    required this.roomId,
  }) : super(key: key);

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _phone1Controller = TextEditingController();
  final _phone2Controller = TextEditingController();
  final _orderService = OrderService();
  bool _isSending = false;
  
  final DateTime _bookingDate = DateTime.now();

  @override
  void dispose() {
    _descriptionController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSending = true;
      });

      try {
        await _orderService.createOrder(
          masterId: widget.masterId,
          roomId: widget.roomId, 
          description: _descriptionController.text,
          bookingDate: DateFormat('yyyy-MM-dd').format(_bookingDate),
          phone1: _phone1Controller.text,
          phone2: _phone2Controller.text.isEmpty ? null : _phone2Controller.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order created successfully! You can track it in the History tab.')),
          );
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
        title: const Text('Registration',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     // Date Field
                     TextFormField(
                       initialValue: DateFormat('dd.MM.yyyy').format(_bookingDate),
                       readOnly: true,
                       decoration: const InputDecoration(
                         labelText: 'Date',
                         border: OutlineInputBorder(),
                         suffixIcon: Icon(Icons.calendar_today),
                       ),
                     ),
                     const SizedBox(height: 16),
                     
                     // Phone 1
                     TextFormField(
                       controller: _phone1Controller,
                       keyboardType: TextInputType.phone,
                       decoration: const InputDecoration(
                         labelText: 'Phone number 1 (Required)',
                         border: OutlineInputBorder(),
                         prefixText: '+998 ',
                       ),
                       validator: (value) {
                         if (value == null || value.isEmpty) {
                           return 'Please enter a phone number';
                         }
                         return null;
                       },
                     ),
                     const SizedBox(height: 16),

                     // Phone 2
                     TextFormField(
                       controller: _phone2Controller,
                       keyboardType: TextInputType.phone,
                       decoration: const InputDecoration(
                         labelText: 'Phone number 2 (Optional)',
                         border: OutlineInputBorder(),
                         prefixText: '+998 ',
                       ),
                     ),
                     const SizedBox(height: 16),

                     // Description
                    const Text(
                      "Special requests (optional):",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Note',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    
                    // Two buttons: Bog'lanish, Lokatsiya
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Implement contact functionality
                            },
                            icon: const Icon(Icons.phone),
                            label: const Text("Connection"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                               // TODO: Implement location functionality
                            },
                            icon: const Icon(Icons.location_on),
                            label: const Text("Location"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: _isSending
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitOrder,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Send'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
