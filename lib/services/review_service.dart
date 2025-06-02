import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get reviews for a specific product
  Future<List<Map<String, dynamic>>> getProductReviews(String productId) async {
    try {
      debugPrint('ReviewService: Fetching reviews for product: $productId');

      final response = await _supabase
          .from('product_reviews')
          .select('''
            *,
            profiles:user_id (
              first_name,
              last_name,
              username
            )
          ''')
          .eq('product_id', productId)
          .order('created_at', ascending: false);

      debugPrint('ReviewService: Found ${response.length} reviews for product $productId');

      // Log the first review for debugging
      if (response.isNotEmpty) {
        debugPrint('ReviewService: First review: ${response.first}');
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('ReviewService: Error fetching reviews: $e');
      return [];
    }
  }

  /// Get paginated reviews for a specific product
  Future<List<Map<String, dynamic>>> getProductReviewsPaginated(
    String productId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      debugPrint('ReviewService: Fetching paginated reviews for product: $productId (page: $page, limit: $limit)');

      final offset = (page - 1) * limit;

      final response = await _supabase
          .from('product_reviews')
          .select('''
            *,
            profiles:user_id (
              first_name,
              last_name,
              username
            )
          ''')
          .eq('product_id', productId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      debugPrint('ReviewService: Found ${response.length} reviews for product $productId (page $page)');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('ReviewService: Error fetching paginated reviews: $e');
      return [];
    }
  }

  /// Get average rating for a product
  Future<Map<String, dynamic>> getProductRating(String productId) async {
    try {
      final response = await _supabase
          .from('product_reviews')
          .select('rating')
          .eq('product_id', productId);

      if (response.isEmpty) {
        return {
          'average_rating': 0.0,
          'total_reviews': 0,
        };
      }

      final ratings = response.map((r) => r['rating'] as int).toList();
      final averageRating = ratings.reduce((a, b) => a + b) / ratings.length;

      return {
        'average_rating': averageRating,
        'total_reviews': ratings.length,
      };
    } catch (e) {
      debugPrint('ReviewService: Error calculating rating: $e');
      return {
        'average_rating': 0.0,
        'total_reviews': 0,
      };
    }
  }

  /// Add a new review
  Future<bool> addReview({
    required String productId,
    required int rating,
    required String comment,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('ReviewService: User not authenticated');
        throw Exception('User not authenticated');
      }

      debugPrint('ReviewService: Adding review for product $productId by user ${user.id}');
      debugPrint('ReviewService: Rating: $rating, Comment: $comment');

      final response = await _supabase.from('product_reviews').insert({
        'user_id': user.id,
        'product_id': productId,
        'rating': rating,
        'comment': comment,
        // Let the database handle created_at with DEFAULT NOW()
      }).select().single();

      debugPrint('ReviewService: Review added successfully: ${response['id']}');
      return true;
    } catch (e) {
      debugPrint('ReviewService: Error adding review: $e');
      return false;
    }
  }

  /// Check if user has already reviewed a product
  Future<bool> hasUserReviewed(String productId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('product_reviews')
          .select('id')
          .eq('product_id', productId)
          .eq('user_id', user.id)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      debugPrint('ReviewService: Error checking user review: $e');
      return false;
    }
  }

  /// Update an existing review
  Future<bool> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('product_reviews')
          .update({
            'rating': rating,
            'comment': comment,
          })
          .eq('id', reviewId)
          .eq('user_id', user.id); // Ensure user can only update their own review

      return true;
    } catch (e) {
      debugPrint('ReviewService: Error updating review: $e');
      return false;
    }
  }

  /// Delete a review
  Future<bool> deleteReview(String reviewId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('product_reviews')
          .delete()
          .eq('id', reviewId)
          .eq('user_id', user.id); // Ensure user can only delete their own review

      return true;
    } catch (e) {
      debugPrint('ReviewService: Error deleting review: $e');
      return false;
    }
  }

  /// Format review data for display
  static Map<String, dynamic> formatReviewForDisplay(Map<String, dynamic> review) {
    final profile = review['profiles'] as Map<String, dynamic>?;
    final firstName = profile?['first_name'] as String? ?? '';
    final lastName = profile?['last_name'] as String? ?? '';
    final username = profile?['username'] as String? ?? '';

    // Create display name
    String displayName;
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      displayName = '$firstName ${lastName[0]}.'; // e.g., "John D."
    } else if (username.isNotEmpty) {
      displayName = username;
    } else {
      displayName = 'Anonymous User';
    }

    // Format date with proper timezone handling
    String timeAgo;
    try {
      final createdAtString = review['created_at'] as String;
      debugPrint('ReviewService: Parsing created_at: $createdAtString');

      // Parse the created_at timestamp from Supabase (UTC) and convert to local time
      final createdAtUtc = DateTime.parse(createdAtString).toUtc();
      final createdAtLocal = createdAtUtc.toLocal();
      final now = DateTime.now();
      final difference = now.difference(createdAtLocal);

      debugPrint('ReviewService: Created at (UTC): $createdAtUtc, Local: $createdAtLocal, Now: $now, Difference: ${difference.inMinutes} minutes');

      if (difference.inDays > 0) {
        timeAgo = '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        timeAgo = '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        timeAgo = '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        timeAgo = 'Just now';
      }

      debugPrint('ReviewService: Formatted time ago: $timeAgo');
    } catch (e) {
      debugPrint('ReviewService: Error parsing date: $e');
      timeAgo = 'Unknown time';
    }

    return {
      'id': review['id'],
      'name': displayName,
      'rating': review['rating'],
      'comment': review['comment'],
      'date': timeAgo,
      'user_id': review['user_id'],
      'created_at': review['created_at'], // Keep original for debugging
    };
  }
}
