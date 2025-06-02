import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get new arrivals with strict 7-day filtering
  /// Only shows products created within the last 7 days
  Future<List<Map<String, dynamic>>> getNewArrivals({int limit = 8}) async {
    try {
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));

      debugPrint('ProductService: Fetching new arrivals from ${lastWeek.toIso8601String()} to ${now.toIso8601String()}');

      // Get products from last 7 days only
      final response = await _supabase
          .from('products')
          .select('*, product_images(*)')
          .gte('created_at', lastWeek.toIso8601String())
          .order('created_at', ascending: false)
          .limit(limit);

      List<Map<String, dynamic>> products = List<Map<String, dynamic>>.from(response);

      debugPrint('ProductService: Found ${products.length} new arrivals within last 7 days');

      return await _processProductImages(products);
    } catch (e) {
      debugPrint('ProductService: Error fetching new arrivals: $e');
      // Return mock data if database doesn't exist yet
      return _getMockNewArrivals();
    }
  }

  /// Get top selling products based on actual sales from completed orders
  /// Falls back to featured products if no purchase data exists
  Future<List<Map<String, dynamic>>> getTopSellingProducts({int limit = 8}) async {
    try {
      debugPrint('ProductService: Attempting to load top selling products...');

      // Get products with sales data from completed orders only
      List<Map<String, dynamic>> products;

      try {
        debugPrint('ProductService: Trying to get products with completed order sales data...');

        // First, get all products with their images
        final productsResponse = await _supabase
            .from('products')
            .select('*, product_images(*)')
            .order('created_at', ascending: false);

        products = List<Map<String, dynamic>>.from(productsResponse);
        debugPrint('ProductService: Got ${products.length} products');

        // Calculate sales for each product from completed orders only
        for (var product in products) {
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
                .eq('order.status', 'Completed'); // Only count completed orders

            int totalSold = 0;
            for (var item in salesResponse) {
              totalSold += (item['quantity'] as int? ?? 0);
            }
            product['total_sold'] = totalSold;

            debugPrint('ProductService: Product ${product['title']} - Total sold: $totalSold');
          } catch (e) {
            debugPrint('ProductService: Error calculating sales for product ${product['id']}: $e');
            product['total_sold'] = 0;
          }
        }

        // Sort by total sold (descending) and take the top sellers
        products.sort((a, b) => (b['total_sold'] as int).compareTo(a['total_sold'] as int));

        // Filter out products with 0 sales, but keep at least some products for display
        final productsWithSales = products.where((p) => (p['total_sold'] as int) > 0).toList();

        if (productsWithSales.isNotEmpty) {
          products = productsWithSales.take(limit).toList();
          debugPrint('ProductService: Using ${products.length} products with real sales data');
        } else {
          // If no products have sales, take the newest products
          products = products.take(limit).toList();
          debugPrint('ProductService: No sales data found, using newest products');
        }

      } catch (e) {
        debugPrint('ProductService: Sales calculation failed: $e');
        debugPrint('ProductService: Falling back to regular products...');

        // If sales calculation fails, just get regular products
        final response = await _supabase
            .from('products')
            .select('*, product_images(*)')
            .order('created_at', ascending: false)
            .limit(limit);

        products = List<Map<String, dynamic>>.from(response);
        debugPrint('ProductService: Got ${products.length} regular products');

        // Set total_sold to 0 for all products
        for (var product in products) {
          product['total_sold'] = 0;
        }
        debugPrint('ProductService: Using real products with zero sales data');
      }

      return await _processProductImages(products);
    } catch (e) {
      debugPrint('ProductService: All database queries failed: $e');
      debugPrint('ProductService: Falling back to mock data');
      // Fallback to mock data if database doesn't exist yet
      return _getMockTopSelling();
    }
  }

  /// Get all products with pagination
  Future<List<Map<String, dynamic>>> getAllProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? sortBy = 'created_at',
    bool ascending = false,
  }) async {
    try {
      final offset = (page - 1) * limit;
      final sortColumn = sortBy ?? 'created_at';

      // Build query with proper type handling
      var queryBuilder = _supabase
          .from('products')
          .select('*, product_images(*)');

      // Add category filter if specified
      if (category != null && category.isNotEmpty) {
        queryBuilder = queryBuilder.eq('category', category);
      }

      // Execute query with sorting and pagination
      final response = await queryBuilder
          .order(sortColumn, ascending: ascending)
          .range(offset, offset + limit - 1);

      List<Map<String, dynamic>> products = List<Map<String, dynamic>>.from(response);

      // Calculate sales for each product from completed orders only
      for (var product in products) {
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

          int totalSold = 0;
          for (var item in salesResponse) {
            totalSold += (item['quantity'] as int? ?? 0);
          }
          product['total_sold'] = totalSold;
        } catch (e) {
          product['total_sold'] = 0;
        }
      }

      return await _processProductImages(products);
    } catch (e) {
      // Return mock data if database doesn't exist yet
      return _getMockProducts(page: page, limit: limit);
    }
  }

  /// Search products by title or description
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      if (query.isEmpty) return [];

      final response = await _supabase
          .from('products')
          .select('*, product_images(*)')
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> products = List<Map<String, dynamic>>.from(response);

      // Calculate sales for each product from completed orders only
      for (var product in products) {
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

          int totalSold = 0;
          for (var item in salesResponse) {
            totalSold += (item['quantity'] as int? ?? 0);
          }
          product['total_sold'] = totalSold;
        } catch (e) {
          product['total_sold'] = 0;
        }
      }

      return await _processProductImages(products);
    } catch (e) {
      // Fallback to mock search
      return _getMockSearchResults(query);
    }
  }

  /// Get product by ID
  Future<Map<String, dynamic>?> getProductById(String productId) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, product_images(*)')
          .eq('id', productId)
          .single();

      final processedProducts = await _processProductImages([response]);
      return processedProducts.first;
    } catch (e) {
      // Return mock product if database doesn't exist yet
      return _getMockProductById(productId);
    }
  }

  /// Get all new arrivals for "See All" page (only products from last 7 days)
  Future<List<Map<String, dynamic>>> getAllNewArrivals({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final offset = (page - 1) * limit;
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));

      debugPrint('ProductService: Fetching all new arrivals from ${lastWeek.toIso8601String()} (page: $page, limit: $limit)');

      final response = await _supabase
          .from('products')
          .select('*, product_images(*)')
          .gte('created_at', lastWeek.toIso8601String()) // Only last 7 days
          .order('created_at', ascending: false) // Newest first
          .range(offset, offset + limit - 1);

      List<Map<String, dynamic>> products = List<Map<String, dynamic>>.from(response);

      debugPrint('ProductService: Found ${products.length} new arrivals for page $page');

      // Calculate sales for each product from completed orders only
      for (var product in products) {
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

          int totalSold = 0;
          for (var item in salesResponse) {
            totalSold += (item['quantity'] as int? ?? 0);
          }
          product['total_sold'] = totalSold;
        } catch (e) {
          product['total_sold'] = 0;
        }
      }

      return await _processProductImages(products);
    } catch (e) {
      debugPrint('ProductService: Error fetching all new arrivals: $e');
      return [];
    }
  }

  /// Get all top selling products for "See All" page (sorted by sales volume)
  Future<List<Map<String, dynamic>>> getAllTopSellingProducts({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      debugPrint('ProductService: Fetching all top selling products (page: $page, limit: $limit)');

      // Get all products first
      final productsResponse = await _supabase
          .from('products')
          .select('*, product_images(*)')
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> products = List<Map<String, dynamic>>.from(productsResponse);

      // Calculate sales for each product from completed orders only
      for (var product in products) {
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

          int totalSold = 0;
          for (var item in salesResponse) {
            totalSold += (item['quantity'] as int? ?? 0);
          }
          product['total_sold'] = totalSold;
        } catch (e) {
          product['total_sold'] = 0;
        }
      }

      // Sort by total sold (descending)
      products.sort((a, b) => (b['total_sold'] as int).compareTo(a['total_sold'] as int));

      // Apply pagination
      final offset = (page - 1) * limit;
      final endIndex = offset + limit;
      if (offset >= products.length) {
        return [];
      }

      final paginatedProducts = products.sublist(
        offset,
        endIndex > products.length ? products.length : endIndex,
      );

      return await _processProductImages(paginatedProducts);
    } catch (e) {
      debugPrint('ProductService: Error fetching all top selling products: $e');
      return [];
    }
  }

  /// Calculate average rating for a product from reviews
  Future<double> _calculateAverageRating(String productId) async {
    try {
      final response = await _supabase
          .from('product_reviews')
          .select('rating')
          .eq('product_id', productId);

      if (response.isEmpty) {
        return 0.0; // No reviews yet
      }

      final ratings = response.map<int>((review) => review['rating'] as int).toList();
      final average = ratings.reduce((a, b) => a + b) / ratings.length;
      return double.parse(average.toStringAsFixed(1));
    } catch (e) {
      debugPrint('ProductService: Error calculating rating for product $productId: $e');
      return 0.0;
    }
  }

  /// Process product images to extract URLs and calculate real ratings
  Future<List<Map<String, dynamic>>> _processProductImages(List<Map<String, dynamic>> products) async {
    for (var product in products) {
      // Ensure required fields have defaults
      product['title'] = product['title'] ?? 'Unknown Product';
      product['description'] = product['description'] ?? 'No description available';
      product['price'] = (product['price'] is num) ? (product['price'] as num).toDouble() : 0.0;
      product['total_sold'] = product['total_sold'] ?? 0;

      // Calculate real average rating from reviews
      try {
        final averageRating = await _calculateAverageRating(product['id']);
        product['rating'] = averageRating;
        debugPrint('ProductService: Product ${product['title']} - Average rating: $averageRating');
      } catch (e) {
        debugPrint('ProductService: Error calculating rating for ${product['title']}: $e');
        product['rating'] = 0.0;
      }

      // Process images
      final images = (product['product_images'] as List<dynamic>? ?? []);
      if (images.isNotEmpty) {
        // Sort images to prioritize thumbnails
        images.sort((a, b) {
          final aIsThumbnail = a['is_thumbnail'] == true;
          final bIsThumbnail = b['is_thumbnail'] == true;
          if (aIsThumbnail && !bIsThumbnail) return -1;
          if (!aIsThumbnail && bIsThumbnail) return 1;
          return 0;
        });

        product['image_urls'] = images.map<String>((img) => img['image_url'] as String).toList();
        product['image'] = product['image_urls'][0];
      } else {
        product['image_urls'] = ['assets/placeholder.png'];
        product['image'] = 'assets/placeholder.png';
      }
    }
    return products;
  }

  /// Mock data for new arrivals (fallback when database doesn't exist)
  List<Map<String, dynamic>> _getMockNewArrivals() {
    return [
      {
        'id': '1',
        'title': 'Tuna Delight',
        'description': 'Premium tuna cat food',
        'price': 1249.50, // Converted from $24.99 to ₱1,249.50
        'image': 'assets/new1.png',
        'image_urls': ['assets/new1.png'],
        'rating': 4.8,
        'total_sold': 120,
        'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'id': '2',
        'title': 'Chicken Feast',
        'description': 'Delicious chicken meal for dogs',
        'price': 1499.50, // Converted from $29.99 to ₱1,499.50
        'image': 'assets/new2.png',
        'image_urls': ['assets/new2.png'],
        'rating': 4.5,
        'total_sold': 350,
        'created_at': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      },
      {
        'id': '3',
        'title': 'Salmon Bites',
        'description': 'Healthy salmon treats',
        'price': 999.50, // Converted from $19.99 to ₱999.50
        'image': 'assets/new3.png',
        'image_urls': ['assets/new3.png'],
        'rating': 4.2,
        'total_sold': 89,
        'created_at': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
      },
      {
        'id': '4',
        'title': 'Beef & Veggies',
        'description': 'Nutritious beef and vegetable mix',
        'price': 1149.50, // Converted from $22.99 to ₱1,149.50
        'image': 'assets/new4.png',
        'image_urls': ['assets/new4.png'],
        'rating': 4.7,
        'total_sold': 230,
        'created_at': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
      },
    ];
  }

  /// Mock data for top selling products
  List<Map<String, dynamic>> _getMockTopSelling() {
    return [
      {
        'id': '2',
        'title': 'Chicken Feast',
        'description': 'Delicious chicken meal for dogs',
        'price': 1499.50, // Converted from $29.99 to ₱1,499.50
        'image': 'assets/new2.png',
        'image_urls': ['assets/new2.png'],
        'rating': 4.5,
        'total_sold': 350,
        'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      },
      {
        'id': '4',
        'title': 'Beef & Veggies',
        'description': 'Nutritious beef and vegetable mix',
        'price': 1149.50, // Converted from $22.99 to ₱1,149.50
        'image': 'assets/new4.png',
        'image_urls': ['assets/new4.png'],
        'rating': 4.7,
        'total_sold': 230,
        'created_at': DateTime.now().subtract(const Duration(days: 45)).toIso8601String(),
      },
      {
        'id': '1',
        'title': 'Tuna Delight',
        'description': 'Premium tuna cat food',
        'price': 1249.50, // Converted from $24.99 to ₱1,249.50
        'image': 'assets/new1.png',
        'image_urls': ['assets/new1.png'],
        'rating': 4.8,
        'total_sold': 120,
        'created_at': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
      },
    ];
  }

  /// Mock data for all products with pagination
  List<Map<String, dynamic>> _getMockProducts({int page = 1, int limit = 20}) {
    final allMockProducts = [..._getMockNewArrivals(), ..._getMockTopSelling()];
    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;

    if (startIndex >= allMockProducts.length) return [];

    return allMockProducts.sublist(
      startIndex,
      endIndex > allMockProducts.length ? allMockProducts.length : endIndex,
    );
  }

  /// Mock search results
  List<Map<String, dynamic>> _getMockSearchResults(String query) {
    final allProducts = [..._getMockNewArrivals(), ..._getMockTopSelling()];
    return allProducts.where((product) =>
      product['title'].toString().toLowerCase().contains(query.toLowerCase()) ||
      product['description'].toString().toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  /// Mock product by ID
  Map<String, dynamic>? _getMockProductById(String productId) {
    final allProducts = [..._getMockNewArrivals(), ..._getMockTopSelling()];
    try {
      return allProducts.firstWhere((product) => product['id'] == productId);
    } catch (e) {
      return null;
    }
  }
}
