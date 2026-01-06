import 'dart:io';
import 'package:comply/screens/users_screen/empty_screen.dart';
import 'package:comply/services/master_service.dart';
import 'package:comply/services/order_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final _dateController = TextEditingController();
  final _orderService = OrderService();
  final _masterService = MasterService();
  
  bool _isSending = false;
  Map<String, dynamic>? _masterData;
  
  DateTime _bookingDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd.MM.yyyy').format(_bookingDate);
    _fetchMasterData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _fetchMasterData() async {
    try {
      final data = await _masterService.getMasterById(widget.masterId);
      if (mounted) {
        setState(() {
          _masterData = data;
        });
      }
    } catch (e) {
      debugPrint('Error fetching master data: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year, now.month, now.day);
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _bookingDate,
      firstDate: firstDate,
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _bookingDate) {
      setState(() {
        _bookingDate = picked;
        _dateController.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
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
          phone1: '+998 ${_phone1Controller.text}',
          phone2: _phone2Controller.text.isEmpty ? null : '+998 ${_phone2Controller.text}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order created successfully! You can track it in the History tab.')),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const EmptyScreen(initialIndex: 1)),
            (route) => false,
          );
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber.replaceAll(RegExp(r'[^\d+]'), ''),
    );
    try {
      if (!await launchUrl(launchUri)) {
        throw Exception('Could not launch $launchUri');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not call $phoneNumber')),
        );
      }
    }
  }

  Future<void> _openMap() async {
    if (_masterData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Master info not loaded yet')),
      );
      return;
    }

    double? lat;
    double? lng;

    try {
      if (_masterData!['latitude'] != null) {
         lat = double.tryParse(_masterData!['latitude'].toString());
      }
      if (_masterData!['longitude'] != null) {
         lng = double.tryParse(_masterData!['longitude'].toString());
      }
    } catch(e) {
      print('Error parsing lat/lng: $e');
    }

    if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
        _showMapSelectionDialog(lat, lng);
        return;
    }

    // Fallback if only address is available
    var address = _masterData!['address'];
    
    if (address == null || address.toString().isEmpty) {
       address = _masterData!['location'];
    }

    if (address != null && address.toString().isNotEmpty) {
        final Uri url = Uri.https('www.google.com', '/maps/dir/', {
          'api': '1',
          'destination': address.toString(),
        });

        try {
          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
            throw Exception('Could not launch $url');
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open maps: $e')),
            );
          }
        }
    } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location not available for this master')),
          );
        }
    }
  }

  void _showMapSelectionDialog(double lat, double lng) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.map, color: Colors.blue),
                title: const Text('Google Maps'),
                onTap: () async {
                  Navigator.pop(context);
                  final Uri googleMapsUrl = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
                  final Uri webUrl = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$lat,$lng");
                  if (await canLaunchUrl(googleMapsUrl)) {
                    await launchUrl(googleMapsUrl);
                  } else {
                    await launchUrl(webUrl, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              if (Platform.isIOS)
                ListTile(
                  leading: const Icon(Icons.map_outlined, color: Colors.grey),
                  title: const Text('Apple Maps'),
                  onTap: () async {
                    Navigator.pop(context);
                    final Uri appleMapsUrl = Uri.parse("https://maps.apple.com/?daddr=$lat,$lng");
                    if (await canLaunchUrl(appleMapsUrl)) {
                      await launchUrl(appleMapsUrl);
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.local_taxi, color: Colors.amber),
                title: const Text('Yandex Maps'),
                onTap: () async {
                  Navigator.pop(context);
                  final Uri yandexMapsUrl = Uri.parse("yandexmaps://maps.yandex.ru/?pt=$lng,$lat&z=12&l=map");
                  final Uri yandexNaviUrl = Uri.parse("yandexnavi://build_route_on_map?lat_to=$lat&lon_to=$lng");
                  
                  if (await canLaunchUrl(yandexNaviUrl)) {
                     await launchUrl(yandexNaviUrl);
                  } else if (await canLaunchUrl(yandexMapsUrl)) {
                     await launchUrl(yandexMapsUrl);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_taxi_outlined, color: Colors.black),
                title: const Text('Yandex Go'),
                onTap: () async {
                  Navigator.pop(context);
                  final Uri yandexGoUrl = Uri.parse("yandex-taxi://route?end-lat=$lat&end-lon=$lng");
                  if (await canLaunchUrl(yandexGoUrl)) {
                     await launchUrl(yandexGoUrl);
                  }
                },
              ),
               ListTile(
                leading: const Icon(Icons.directions_car, color: Colors.blue),
                title: const Text('Waze'),
                onTap: () async {
                  Navigator.pop(context);
                  final Uri wazeUrl = Uri.parse("waze://?ll=$lat,$lng&navigate=yes");
                   if (await canLaunchUrl(wazeUrl)) {
                      await launchUrl(wazeUrl);
                   }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showConnectionDialog() {
    if (_masterData == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading contact info...')),
      );
      return;
    }

    final phone1 = _masterData!['phone_number_1'];
    final phone2 = _masterData!['phone_number_2'];
    final hotelName = _masterData!['first_name'] ?? 'Contact Hotel';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text(hotelName, style: const TextStyle(fontWeight: FontWeight.bold))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               if (phone1 != null && phone1.toString().isNotEmpty)
                 ListTile(
                   leading: const Icon(Icons.call, color: Colors.green),
                   title: Text(phone1.toString(), style: const TextStyle(fontSize: 18)),
                   onTap: () => _makePhoneCall(phone1.toString()),
                 ),
               if (phone2 != null && phone2.toString().isNotEmpty)
                 ListTile(
                   leading: const Icon(Icons.call, color: Colors.green),
                   title: Text(phone2.toString(), style: const TextStyle(fontSize: 18)),
                   onTap: () => _makePhoneCall(phone2.toString()),
                 ),
               if ((phone1 == null || phone1.toString().isEmpty) && (phone2 == null || phone2.toString().isEmpty))
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("No phone numbers available."),
                  ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
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
                         controller: _dateController,
                         readOnly: true,
                         onTap: () => _selectDate(context),
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
                         inputFormatters: [
                           PhoneNumberFormatter(),
                         ],
                         decoration: const InputDecoration(
                           labelText: 'Phone number 1 (Required)',
                           border: OutlineInputBorder(),
                           prefixText: '+998 ',
                         ),
                         validator: (value) {
                           if (value == null || value.isEmpty) {
                             return 'Please enter a phone number';
                           }
                           final digits = value.replaceAll(RegExp(r'\D'), '');
                           if (digits.length != 9) {
                             return 'Please enter 9 digits';
                           }
                           return null;
                       },
                     ),
                     const SizedBox(height: 16),

                     // Phone 2
                     TextFormField(
                       controller: _phone2Controller,
                       keyboardType: TextInputType.phone,
                       inputFormatters: [
                         PhoneNumberFormatter(),
                       ],
                       decoration: const InputDecoration(
                         labelText: 'Phone number 2 (Optional)',
                         border: OutlineInputBorder(),
                         prefixText: '+998 ',
                       ),
                       validator: (value) {
                         if (value != null && value.isNotEmpty) {
                           final digits = value.replaceAll(RegExp(r'\D'), '');
                           if (digits.length != 9) {
                             return 'Please enter 9 digits';
                           }
                         }
                         return null;
                       },
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
                            onPressed: _showConnectionDialog,
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
                            onPressed: _openMap,
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
      ),
    );
  }
}

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    
    // Allow empty
    if (newValue.text.isEmpty) {
       return newValue;
    }

    // Only allow digits
    String cleaned = newValue.text.replaceAll(RegExp(r'\D'), '');
    
    // Limit to 9 digits
    if (cleaned.length > 9) {
      cleaned = cleaned.substring(0, 9);
    }

    // Format: XX XXX XX XX
    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      if (i == 2 || i == 5 || i == 7) {
        buffer.write(' ');
      }
      buffer.write(cleaned[i]);
    }

    final newText = buffer.toString();
    
    // Return with cursor at the end
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
