import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/review_service.dart';
import 'package:intl/intl.dart';

class DriverReviewsScreen extends StatefulWidget {
  final String driverId;
  final String driverName;
  final double averageRating;

  const DriverReviewsScreen({
    super.key,
    required this.driverId,
    required this.driverName,
    required this.averageRating,
  });

  @override
  State<DriverReviewsScreen> createState() => _DriverReviewsScreenState();
}

class _DriverReviewsScreenState extends State<DriverReviewsScreen> {
  final ReviewService _reviewService = ReviewService();
  late Future<List<dynamic>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _reviewService.getUserReviews(widget.driverId);
  }

  Widget _buildAverageRatingHeader(List<dynamic> reviews) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.averageRating > 0 ? widget.averageRating.toStringAsFixed(1) : '—',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < widget.averageRating.round() ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                      size: 20,
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  '${reviews.length} review${reviews.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          /* We could add rating distribution bars here for Google-like feel if backend supported */
        ],
      ),
    );
  }

  Widget _buildReviewCard(dynamic reviewData) {
    final reviewerName = reviewData['reviewer']?['fullName'] ?? 'Anonymous';
    final int rating = reviewData['rating'] ?? 0;
    final String comment = reviewData['comment'] ?? '';
    final String dateString = reviewData['createdAt'] ?? '';
    final DateTime? date = DateTime.tryParse(dateString);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: kAccentColor.withOpacity(0.1),
                child: Text(
                  reviewerName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: kAccentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    if (date != null)
                      Text(
                        DateFormat('MMM dd, yyyy').format(date),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.orange,
                size: 16,
              );
            }),
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comment,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text(
          '${widget.driverName}\'s Reviews',
          style: const TextStyle(color: kPrimaryTextColor, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: kPrimaryTextColor),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _reviewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: kAccentColor),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error.toString().replaceAll('Exception: ', '')}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final reviews = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildAverageRatingHeader(reviews),
              ),
              SliverToBoxAdapter(
                child: Container(height: 8, color: Colors.grey.shade100),
              ),
              if (reviews.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No reviews yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildReviewCard(reviews[index]),
                    childCount: reviews.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
