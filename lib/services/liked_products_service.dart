import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LikedProductsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Check if a product is liked by the current user
  Future<bool> isProductLiked(String productId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('liked_items')
          .select('id')
          .eq('user_id', user.id)
          .eq('product_id', productId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('LikedProductsService: Error checking if product is liked: $e');
      return false;
    }
  }

  /// Like a product
  Future<bool> likeProduct(String productId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('LikedProductsService: User not authenticated');
        return false;
      }

      // Check if already liked to prevent duplicate entries
      final isAlreadyLiked = await isProductLiked(productId);
      if (isAlreadyLiked) {
        debugPrint('LikedProductsService: Product already liked');
        return true; // Return true since the desired state is achieved
      }

      await _supabase.from('liked_items').insert({
        'user_id': user.id,
        'product_id': productId,
      });

      debugPrint('LikedProductsService: Successfully liked product $productId');
      return true;
    } catch (e) {
      debugPrint('LikedProductsService: Error liking product: $e');
      return false;
    }
  }

  /// Unlike a product
  Future<bool> unlikeProduct(String productId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('LikedProductsService: User not authenticated');
        return false;
      }

      // Check if the product is actually liked before trying to unlike
      final isCurrentlyLiked = await isProductLiked(productId);
      if (!isCurrentlyLiked) {
        debugPrint('LikedProductsService: Product not in liked list');
        return true; // Return true since the desired state is achieved
      }

      await _supabase
          .from('liked_items')
          .delete()
          .eq('user_id', user.id)
          .eq('product_id', productId);

      debugPrint('LikedProductsService: Successfully unliked product $productId');
      return true;
    } catch (e) {
      debugPrint('LikedProductsService: Error unliking product: $e');
      return false;
    }
  }

  /// Toggle like status for a product
  Future<bool> toggleLike(String productId) async {
    try {
      final isLiked = await isProductLiked(productId);
      if (isLiked) {
        return await unlikeProduct(productId);
      } else {
        return await likeProduct(productId);
      }
    } catch (e) {
      debugPrint('LikedProductsService: Error toggling like: $e');
      return false;
    }
  }

  /// Get all liked products for the current user
  Future<List<Map<String, dynamic>>> getLikedProducts({int limit = 50}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      final response = await _supabase
          .from('liked_items')
          .select('''
            *,
            product:product_id (
              id,
              title,
              description,
              price,
              original_price,
              discount_percentage,
              is_on_sale,
              product_images (
                image_url,
                is_thumbnail
              )
            )
          ''')
          .eq('user_id', user.id)
          .order('id', ascending: false)
          .limit(limit);

      List<Map<String, dynamic>> processedProducts = [];

      for (var item in List<Map<String, dynamic>>.from(response)) {
        final product = item['product'] ?? {};
        final images = product['product_images'] as List<dynamic>? ?? [];

        String imageUrl = 'assets/logo_sample.png';
        if (images.isNotEmpty) {
          try {
            final thumbnailImage = images.firstWhere(
              (img) => img['is_thumbnail'] == true,
              orElse: () => images.first,
            );
            imageUrl = thumbnailImage['image_url'] ?? 'assets/logo_sample.png';
          } catch (e) {
            imageUrl = images.first['image_url'] ?? 'assets/logo_sample.png';
          }
        }

        // Calculate display price (considering discounts)
        double displayPrice = (product['price'] as num?)?.toDouble() ?? 0.0;
        double? originalPrice;
        bool isOnSale = product['is_on_sale'] == true;

        if (isOnSale && product['original_price'] != null) {
          originalPrice = (product['original_price'] as num).toDouble();
          displayPrice = (product['price'] as num?)?.toDouble() ?? originalPrice;
        }

        // Calculate sales data for this product
        int totalSold = 0;
        try {
          final salesResponse = await _supabase
              .from('order_items')
              .select('''
                quantity,
                order:order_id!inner (
                  status
                )
              ''')
              .eq('product_id', product['id'])
              .eq('order.status', 'Completed');

          for (var salesItem in salesResponse) {
            totalSold += (salesItem['quantity'] as int? ?? 0);
          }
        } catch (e) {
          debugPrint('LikedProductsService: Error calculating sales for product ${product['id']}: $e');
          totalSold = 0;
        }

        // Calculate average rating for this product
        double rating = 4.0; // Default rating
        try {
          final reviewsResponse = await _supabase
              .from('product_reviews')
              .select('rating')
              .eq('product_id', product['id']);

          if (reviewsResponse.isNotEmpty) {
            double totalRating = 0;
            for (var review in reviewsResponse) {
              totalRating += (review['rating'] as num?)?.toDouble() ?? 0.0;
            }
            rating = totalRating / reviewsResponse.length;
          }
        } catch (e) {
          debugPrint('LikedProductsService: Error calculating rating for product ${product['id']}: $e');
          rating = 4.0;
        }

        processedProducts.add({
          'id': product['id'],
          'title': product['title'] ?? 'Unknown Product',
          'description': product['description'] ?? 'No description available',
          'price': displayPrice,
          'original_price': originalPrice,
          'is_on_sale': isOnSale,
          'discount_percentage': product['discount_percentage'],
          'image_url': imageUrl,
          'rating': rating,
          'total_sold': totalSold,
          'liked_at': item['created_at'],
        });
      }

      return processedProducts;
    } catch (e) {
      debugPrint('LikedProductsService: Error fetching liked products: $e');
      return [];
    }
  }

  /// Get count of liked products for the current user
  Future<int> getLikedProductsCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0;

      final response = await _supabase
          .from('liked_items')
          .select('id')
          .eq('user_id', user.id);

      return response.length;
    } catch (e) {
      debugPrint('LikedProductsService: Error getting liked products count: $e');
      return 0;
    }
  }
}
