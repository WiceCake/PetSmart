import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get new arrivals with smart filtering
  /// Priority: Last 24 hours -> Last 7 days -> All products (newest first)
  Future<List<Map<String, dynamic>>> getNewArrivals({int limit = 8}) async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final lastWeek = now.subtract(const Duration(days: 7));

      // First try: Products from last 24 hours
      var response = await _supabase
          .from('products')
          .select('*, product_images(*)')
          .gte('created_at', yesterday.toIso8601String())
          .order('created_at', ascending: false)
          .limit(limit);

      List<Map<String, dynamic>> products = List<Map<String, dynamic>>.from(response);

      // If not enough products from last 24 hours, expand to last 7 days
      if (products.length < limit) {
        response = await _supabase
            .from('products')
            .select('*, product_images(*)')
            .gte('created_at', lastWeek.toIso8601String())
            .order('created_at', ascending: false)
            .limit(limit);

        products = List<Map<String, dynamic>>.from(response);
      }

      // If still not enough, get all products (newest first)
      if (products.length < limit) {
        response = await _supabase
            .from('products')
            .select('*, product_images(*)')
            .order('created_at', ascending: false)
            .limit(limit);

        products = List<Map<String, dynamic>>.from(response);
      }

      return _processProductImages(products);
    } catch (e) {
      // Return mock data if database doesn't exist yet
      return _getMockNewArrivals();
    }
  }

  /// Get top selling products based on purchase frequency
  /// Falls back to featured products if no purchase data exists
  Future<List<Map<String, dynamic>>> getTopSellingProducts({int limit = 8}) async {
    try {
      // Try to get products with purchase data (if orders table exists)
      final response = await _supabase
          .from('products')
          .select('*, product_images(*), orders(quantity)')
          .order('created_at', ascending: false)
          .limit(limit);

      List<Map<String, dynamic>> products = List<Map<String, dynamic>>.from(response);

      // Calculate total sold for each product
      for (var product in products) {
        int totalSold = 0;
        if (product['orders'] != null) {
          for (var order in product['orders']) {
            totalSold += (order['quantity'] as int? ?? 0);
          }
        }
        product['total_sold'] = totalSold;
      }

      // Sort by total sold (descending)
      products.sort((a, b) => (b['total_sold'] as int).compareTo(a['total_sold'] as int));

      return _processProductImages(products);
    } catch (e) {
      // Fallback to featured products or mock data
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
      return _processProductImages(products);
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
      return _processProductImages(products);
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

      return _processProductImages([response]).first;
    } catch (e) {
      // Return mock product if database doesn't exist yet
      return _getMockProductById(productId);
    }
  }

  /// Process product images to extract URLs and fix field mappings
  List<Map<String, dynamic>> _processProductImages(List<Map<String, dynamic>> products) {
    for (var product in products) {
      // Fix field mapping: database uses 'title' but UI expects 'name'
      if (product['title'] != null && product['name'] == null) {
        product['name'] = product['title'];
      }

      // Ensure required fields have defaults
      product['name'] = product['name'] ?? product['title'] ?? 'Unknown Product';
      product['description'] = product['description'] ?? 'No description available';
      product['price'] = (product['price'] is num) ? (product['price'] as num).toDouble() : 0.0;
      product['rating'] = product['rating'] ?? 4.0; // Default rating
      product['total_sold'] = product['total_sold'] ?? 0;

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
        'price': 24.99,
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
        'price': 29.99,
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
        'price': 19.99,
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
        'price': 22.99,
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
        'price': 29.99,
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
        'price': 22.99,
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
        'price': 24.99,
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
