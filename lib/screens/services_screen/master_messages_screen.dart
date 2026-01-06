import 'package:comply/services/master_service.dart';
import 'package:comply/services/review_service.dart';
import 'package:flutter/material.dart';

class MasterMessagesScreen extends StatefulWidget {
  const MasterMessagesScreen({super.key});

  @override
  State<MasterMessagesScreen> createState() => _MasterMessagesScreenState();
}

class _MasterMessagesScreenState extends State<MasterMessagesScreen> {
  final MasterService _masterService = MasterService();
  final ReviewService _reviewService = ReviewService();

  bool _isLoading = true;
  String? _error;
  List<dynamic> _reviews = [];
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await _masterService.getMasterProfile();
      final masterId = profile['id'];

      final reviews = await _reviewService.getReviewsForMaster(masterId);

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Color _getRatingColor(num rating) {
    if (rating <= 2) return Colors.red;
    if (rating <= 3.9) return Colors.amber;
    return Colors.green;
  }

  Widget _buildStatItem(int count, Color color, IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    int redCount = 0;
    int amberCount = 0;
    int greenCount = 0;

    for (var review in _reviews) {
      double rating = review['rating'] is num
          ? (review['rating'] as num).toDouble()
          : double.tryParse(review['rating'].toString()) ?? 0.0;
      
      if (rating > 5.0) rating = 5.0;

      if (rating <= 2.0) {
        redCount++;
      } else if (rating <= 3.9) {
        amberCount++;
      } else {
        greenCount++;
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Reviews & Ratings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(redCount, Colors.red, Icons.sentiment_dissatisfied_rounded, 'Bad'),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey[200],
                ),
                _buildStatItem(amberCount, Colors.orange, Icons.sentiment_neutral_rounded, 'Normal'),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey[200],
                ),
                _buildStatItem(greenCount, Colors.green, Icons.sentiment_satisfied_rounded, 'Good'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : _reviews.isEmpty
                        ? const Center(
                            child: Text(
                              'No reviews yet',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchReviews,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: _showAll || _reviews.length <= 5
                                  ? _reviews.length
                                  : 6,
                              itemBuilder: (context, index) {
                                if (!_showAll && _reviews.length > 5 && index == 5) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Center(
                                      child: TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _showAll = true;
                                          });
                                        },
                                        child: const Text(
                                          'See all',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final review = _reviews[index];
                                double rating = review['rating'] is num
                                    ? (review['rating'] as num).toDouble()
                                    : double.tryParse(review['rating'].toString()) ?? 0.0;
                                
                                if (rating > 5.0) rating = 5.0;
                                
                                final color = _getRatingColor(rating);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 2,
                                  shadowColor: Colors.black.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${review['first_name'] ?? 'User'} ${review['last_name'] ?? ''}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: color.withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    rating.toString(), // Use capped rating
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: color,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(Icons.star,
                                                      color: color, size: 16),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          review['comment'] ?? '',
                                          style: const TextStyle(
                                              fontSize: 14, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
