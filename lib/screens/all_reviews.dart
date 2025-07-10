import 'package:flutter/material.dart';

class AllReviewsPage extends StatelessWidget {
  final String hospitalName;
  final List<Map<String, dynamic>> reviews;

  const AllReviewsPage({
    Key? key,
    required this.hospitalName,
    required this.reviews,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$hospitalName Reviews'),
        backgroundColor: const Color(0xFF159BBD),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          final review = reviews[index];
          
          // Handle different review formats (Google Places vs regular)
          final authorName = review['author_name'] ?? review['name'] ?? 'Anonymous';
          final rating = review['rating']?.toString() ?? '0.0';
          final comment = review['text'] ?? review['comment'] ?? 'No comment provided';
          final date = review['relative_time_description'] ?? review['date'] ?? 'Recently';
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF159BBD).withOpacity(0.8),
                            const Color(0xFF0D5C73).withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          authorName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: [
                              Row(
                                children: List.generate(5, (index) {
                                  final ratingValue = double.tryParse(rating) ?? 0.0;
                                  return Icon(
                                    index < ratingValue.floor() ? Icons.star : Icons.star_border,
                                    color: const Color(0xFFFFD700),
                                    size: 16,
                                  );
                                }),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rating,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      date,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  comment,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 