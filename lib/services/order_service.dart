import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_smart/utils/currency_formatter.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  final SupabaseClient _supabase = Supabase.instance.client;

  factory OrderService() {
    return _instance;
  }

  OrderService._internal();

  /// Create a new order with order items
  Future<Map<String, dynamic>?> createOrder({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    String status = 'Preparing', // Changed from 'Pending' to 'Preparing' to match DB constraint
  }) async {
    try {
      print('OrderService: Starting order creation...');
      print('OrderService: Items count: ${items.length}');
      print('OrderService: Total amount: $totalAmount');

      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('OrderService: User not authenticated');
        throw Exception('User not authenticated');
      }
      print('OrderService: User ID: ${user.id}');

      // Validate items before processing
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        print('OrderService: Item $i: ${item.toString()}');

        final productId = item['id']?.toString();
        if (productId == null || productId.isEmpty) {
          print('OrderService: Invalid product ID for item $i: $productId');
          throw Exception('Product ID is required for order item ${i + 1}');
        }

        // Validate product ID format (should be UUID)
        if (!RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$').hasMatch(productId)) {
          print('OrderService: Invalid UUID format for product ID: $productId');
          throw Exception('Invalid product ID format for item ${i + 1}');
        }
      }

      // Start a transaction-like operation
      // First, create the order
      print('OrderService: Creating order record...');
      final orderResponse = await _supabase
          .from('orders')
          .insert({
            'user_id': user.id,
            'total_amount': totalAmount,
            'status': status,
          })
          .select()
          .single();

      final orderId = orderResponse['id'];
      print('OrderService: Order created with ID: $orderId');

      // Then, create order items
      final orderItems = items.map((item) {
        final price = CurrencyFormatter.parsePeso(item['price'].toString());
        final productId = item['id']?.toString();

        print('OrderService: Processing item - Product ID: $productId, Price: ${item['price']}, Parsed Price: $price, Quantity: ${item['quantity']}');

        return {
          'order_id': orderId,
          'product_id': productId,
          'quantity': item['quantity'] ?? 1,
          'price': price,
        };
      }).toList();

      print('OrderService: Creating ${orderItems.length} order items...');
      await _supabase
          .from('order_items')
          .insert(orderItems);

      print('OrderService: Order creation completed successfully');
      return {
        'order_id': orderId,
        'order': orderResponse,
        'items': orderItems,
      };
    } catch (e) {
      print('OrderService: Error creating order: $e');
      print('OrderService: Error type: ${e.runtimeType}');
      if (e is PostgrestException) {
        print('OrderService: Postgrest error details: ${e.details}');
        print('OrderService: Postgrest error message: ${e.message}');
        print('OrderService: Postgrest error code: ${e.code}');
      }
      return null;
    }
  }

  /// Get user's order history
  Future<List<Map<String, dynamic>>> getUserOrders({
    int limit = 50,
    String? status,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      // Build the base query
      var queryBuilder = _supabase
          .from('orders')
          .select('''
            *,
            order_items (
              *,
              product:product_id (
                id,
                title,
                product_images (
                  image_url,
                  is_thumbnail
                )
              )
            )
          ''')
          .eq('user_id', user.id);

      // Add status filter if provided
      if (status != null) {
        queryBuilder = queryBuilder.eq('status', status);
      }

      // Add ordering and limit
      final response = await queryBuilder
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response).map((order) {
        // Process order items to include product details
        final orderItems = (order['order_items'] as List<dynamic>? ?? []).map((item) {
          final product = item['product'] ?? {};
          final images = product['product_images'] as List<dynamic>? ?? [];

          String imageUrl = 'assets/placeholder.png';
          if (images.isNotEmpty) {
            try {
              final thumbnailImage = images.firstWhere(
                (img) => img['is_thumbnail'] == true,
                orElse: () => images.first,
              );
              imageUrl = thumbnailImage['image_url'] ?? 'assets/placeholder.png';
            } catch (e) {
              imageUrl = images.first['image_url'] ?? 'assets/placeholder.png';
            }
          }

          return {
            ...item,
            'product_title': product['title'] ?? 'Unknown Product',
            'product_image': imageUrl,
          };
        }).toList();

        return {
          ...order,
          'order_items': orderItems,
        };
      }).toList();
    } catch (e) {
      print('OrderService: Error fetching user orders: $e');
      return [];
    }
  }

  /// Get order by ID
  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return null;
      }

      final response = await _supabase
          .from('orders')
          .select('''
            *,
            order_items (
              *,
              product:product_id (
                id,
                title,
                product_images (
                  image_url,
                  is_thumbnail
                )
              )
            )
          ''')
          .eq('id', orderId)
          .eq('user_id', user.id)
          .single();

      // Process order items to include product details
      final orderItems = (response['order_items'] as List<dynamic>? ?? []).map((item) {
        final product = item['product'] ?? {};
        final images = product['product_images'] as List<dynamic>? ?? [];

        String imageUrl = 'assets/placeholder.png';
        if (images.isNotEmpty) {
          try {
            final thumbnailImage = images.firstWhere(
              (img) => img['is_thumbnail'] == true,
              orElse: () => images.first,
            );
            imageUrl = thumbnailImage['image_url'] ?? 'assets/placeholder.png';
          } catch (e) {
            imageUrl = images.first['image_url'] ?? 'assets/placeholder.png';
          }
        }

        return {
          ...item,
          'product_title': product['title'] ?? 'Unknown Product',
          'product_image': imageUrl,
        };
      }).toList();

      return {
        ...response,
        'order_items': orderItems,
      };
    } catch (e) {
      print('OrderService: Error fetching order: $e');
      return null;
    }
  }

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      await _supabase
          .from('orders')
          .update({'status': status})
          .eq('id', orderId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      print('OrderService: Error updating order status: $e');
      return false;
    }
  }

  /// Get order statistics for user
  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {
          'total_orders': 0,
          'pending_orders': 0,
          'completed_orders': 0,
          'total_spent': 0.0,
        };
      }

      final orders = await getUserOrders();

      int totalOrders = orders.length;
      int pendingOrders = orders.where((order) => order['status'] == 'Pending').length;
      int completedOrders = orders.where((order) => order['status'] == 'Completed').length;
      double totalSpent = orders.fold(0.0, (sum, order) => sum + (order['total_amount'] as num).toDouble());

      return {
        'total_orders': totalOrders,
        'pending_orders': pendingOrders,
        'completed_orders': completedOrders,
        'total_spent': totalSpent,
      };
    } catch (e) {
      print('OrderService: Error getting order stats: $e');
      return {
        'total_orders': 0,
        'pending_orders': 0,
        'completed_orders': 0,
        'total_spent': 0.0,
      };
    }
  }

  /// Cancel an order
  Future<bool> cancelOrder(String orderId) async {
    try {
      return await updateOrderStatus(orderId, 'Cancelled');
    } catch (e) {
      print('OrderService: Error cancelling order: $e');
      return false;
    }
  }
}
