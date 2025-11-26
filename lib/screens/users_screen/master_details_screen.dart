import 'package:comply/services/master_service.dart';
import 'package:comply/services/review_service.dart';
import 'package:flutter/material.dart';

// Placeholder for CreateOrderScreen
class CreateOrderScreen extends StatelessWidget {
  final int masterId;
  const CreateOrderScreen({Key? key, required this.masterId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Order')),
      body: Center(
        child: Text('Order creation form for master #$masterId'),
      ),
    );
  }
}


class MasterDetailsScreen extends StatefulWidget {
  final int masterId;

  const MasterDetailsScreen({Key? key, required this.masterId}) : super(key: key);

  @override
  State<MasterDetailsScreen> createState() => _MasterDetailsScreenState();
}

class _MasterDetailsScreenState extends State<MasterDetailsScreen> {
  final MasterService _masterService = MasterService();
  final ReviewService _reviewService = ReviewService();

  late Future<Map<String, dynamic>> _masterDetailsFuture;

  @override
  void initState() {
    super.initState();
    _loadMasterDetails();
  }

  void _loadMasterDetails() {
    setState(() {
      _masterDetailsFuture = _fetchDetails();
    });
  }

  Future<Map<String, dynamic>> _fetchDetails() async {
    // Fetch master details and reviews in parallel
    final masterFuture = _masterService.getMasterById(widget.masterId);
    final reviewsFuture = _reviewService.getReviewsForMaster(widget.masterId);

    final results = await Future.wait([masterFuture, reviewsFuture]);

    return {
      'master': results[0],
      'reviews': results[1],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Profile'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _masterDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Master not found.'));
          }

          final master = snapshot.data!['master'];
          final reviews = snapshot.data!['reviews'] as List;
          final bool isAvailable = master['is_available'] == 1;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Master Info Header
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: master['image_url'] != null
                                ? NetworkImage(master['image_url'])
                                : null,
                            child: master['image_url'] == null
                                ? const Icon(Icons.person, size: 40)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${master['first_name']} ${master['last_name']}',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  master['place_name'] ?? 'Location not specified',
                                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${double.tryParse(master['rating'].toString())?.toStringAsFixed(1) ?? '0.0'} (${reviews.length} reviews)',
                                       style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Description',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        master['description'] ?? 'No description available.',
                        style: const TextStyle(fontSize: 16),
                      ),

                      const Divider(height: 40),

                      // Reviews Section
                      Text(
                        'Reviews',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      reviews.isEmpty
                          ? const Text('No reviews yet.')
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: reviews.length,
                              itemBuilder: (context, index) {
                                final review = reviews[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  child: ListTile(
                                    title: Text('${review['first_name']} ${review['last_name']}'),
                                    subtitle: Text(review['comment'] ?? ''),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(review['rating'].toString()),
                                        const Icon(Icons.star, color: Colors.amber, size: 16),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
              // Bottom Action Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isAvailable ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CreateOrderScreen(masterId: widget.masterId)),
                      );
                    } : null, // Disable button if not available
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isAvailable ? Colors.blue : Colors.grey,
                    ),
                    child: Text(isAvailable ? 'Request Service' : 'Master is Busy'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
