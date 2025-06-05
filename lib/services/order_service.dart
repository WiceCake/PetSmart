import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_smart/services/notification_helper.dart';
import 'package:pet_smart/utils/currency_formatter.dart';
import 'dart:async';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  final SupabaseClient _supabase = Supabase.instance.client;

  factory OrderService() {
    return _instance;
  }

  OrderService._internal();

  // Stream controllers for real-time updates
  final StreamController<List<Map<String, dynamic>>> _ordersController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<Map<String, dynamic>> _orderStatsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _recentOrdersController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  // Subscriptions for cleanup
  RealtimeChannel? _ordersSubscription;
  RealtimeChannel? _orderItemsSubscription;



  /// Get orders stream for real-time updates
  Stream<List<Map<String, dynamic>>> get ordersStream => _ordersController.stream;

  /// Get order statistics stream for real-time updates
  Stream<Map<String, dynamic>> get orderStatsStream => _orderStatsController.stream;

  /// Get recent orders stream for real-time updates
  Stream<List<Map<String, dynamic>>> get recentOrdersStream => _recentOrdersController.stream;

  /// Initialize real-time subscriptions for orders
  Future<void> initializeRealtimeSubscriptions() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('OrderService: User not authenticated, skipping real-time initialization');
      return;
    }

    debugPrint('OrderService: Initializing real-time subscriptions for user: ${user.id}');

    try {
      // Auto-progress orders on initialization
      await autoProgressOrders();

      await _setupRealtimeSubscriptions();
      debugPrint('OrderService: Real-time subscriptions initialized successfully');
    } catch (e) {
      debugPrint('OrderService: Error initializing real-time subscriptions: $e');
    }
  }

  /// Setup real-time subscriptions for orders and order_items
  Future<void> _setupRealtimeSubscriptions() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Unsubscribe from previous subscriptions
    await _ordersSubscription?.unsubscribe();
    await _orderItemsSubscription?.unsubscribe();

    // Subscribe to orders changes for current user
    _ordersSubscription = _supabase
        .channel('orders:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => _handleOrderChange(payload),
        )
        .subscribe();

    // Subscribe to order_items changes (for orders belonging to current user)
    _orderItemsSubscription = _supabase
        .channel('order_items:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'order_items',
          callback: (payload) => _handleOrderItemChange(payload),
        )
        .subscribe();

    debugPrint('OrderService: Subscribed to orders and order_items changes for user $userId');
  }

  /// Handle order changes from real-time subscription
  void _handleOrderChange(PostgresChangePayload payload) {
    debugPrint('OrderService: Order change detected: ${payload.eventType}');
    debugPrint('OrderService: Payload details - oldRecord: ${payload.oldRecord}, newRecord: ${payload.newRecord}');

    // Check if this is a status change
    if (payload.eventType == PostgresChangeEvent.update) {
      final newStatus = payload.newRecord['status'];
      final oldStatus = payload.oldRecord?['status'];
      if (newStatus != oldStatus) {
        debugPrint('OrderService: Order status changed from $oldStatus to $newStatus');
      }
    }

    // Refresh all order-related data when any order changes
    _refreshOrderData();
  }

  /// Handle order_items changes from real-time subscription
  void _handleOrderItemChange(PostgresChangePayload payload) {
    debugPrint('OrderService: Order item change detected: ${payload.eventType}');
    debugPrint('OrderService: Payload details - oldRecord: ${payload.oldRecord}, newRecord: ${payload.newRecord}');

    // Refresh all order-related data when any order item changes
    _refreshOrderData();
  }

  /// Refresh all order-related data and emit to streams
  Future<void> _refreshOrderData() async {
    debugPrint('OrderService: Refreshing order data due to real-time change');

    try {
      // Add a small delay to ensure database consistency
      await Future.delayed(const Duration(milliseconds: 100));

      // Refresh orders, stats, and recent orders in parallel
      await Future.wait([
        _loadAndEmitOrders(),
        _loadAndEmitOrderStats(),
        _loadAndEmitRecentOrders(),
      ]);

      debugPrint('OrderService: Order data refreshed successfully');
    } catch (e) {
      debugPrint('OrderService: Error refreshing order data: $e');
    }
  }

  /// Refresh order data manually (for pull-to-refresh)
  Future<void> refreshOrderData() async {
    await _refreshOrderData();
  }

  /// Manually trigger auto-progress and refresh (for pull-to-refresh)
  Future<void> refreshWithAutoProgress() async {
    await autoProgressOrders();
    await _refreshOrderData();
  }

  /// Load orders and emit to stream
  Future<void> _loadAndEmitOrders() async {
    try {
      final orders = await getUserOrders();
      if (!_ordersController.isClosed) {
        _ordersController.add(orders);
        debugPrint('OrderService: Emitted ${orders.length} orders to stream');
      }
    } catch (e) {
      debugPrint('OrderService: Error loading orders for stream: $e');
      if (!_ordersController.isClosed) {
        _ordersController.addError(e);
      }
    }
  }

  /// Load order statistics and emit to stream
  Future<void> _loadAndEmitOrderStats() async {
    try {
      final stats = await getOrderStats();
      if (!_orderStatsController.isClosed) {
        _orderStatsController.add(stats);
        debugPrint('OrderService: Emitted order stats to stream: $stats');
      }
    } catch (e) {
      debugPrint('OrderService: Error loading order stats for stream: $e');
      if (!_orderStatsController.isClosed) {
        _orderStatsController.addError(e);
      }
    }
  }

  /// Load recent orders and emit to stream
  Future<void> _loadAndEmitRecentOrders() async {
    try {
      // Get recent completed orders with product details (limit to 5 orders for dashboard)
      final recentOrders = await getUserOrders(
        limit: 5,
        status: 'Completed',
      );

      // Process orders to include summary information (same logic as account page)
      List<Map<String, dynamic>> processedOrders = [];

      for (final order in recentOrders) {
        final orderItems = order['order_items'] as List<dynamic>? ?? [];

        // Skip orders with no items
        if (orderItems.isEmpty) continue;

        // Calculate order summary
        int totalItems = 0;
        double totalAmount = order['total_amount']?.toDouble() ?? 0.0;
        List<String> productNames = [];
        String primaryImage = 'assets/logo_sample.png';

        for (final item in orderItems) {
          totalItems += (item['quantity'] as int? ?? 1);
          productNames.add(item['product_title'] ?? 'Unknown Product');

          // Use the first product's image as the primary image
          if (primaryImage == 'assets/logo_sample.png' && item['product_image'] != null) {
            primaryImage = item['product_image'];
          }
        }

        // Create order summary
        processedOrders.add({
          'id': order['id'],
          'order_date': order['created_at'],
          'total_amount': totalAmount,
          'total_items': totalItems,
          'item_count': orderItems.length,
          'product_names': productNames,
          'primary_image': primaryImage,
          'delivery_address': order['delivery_address'] ?? 'No address provided',
          'status': order['status'],
          'order_items': orderItems, // Keep full order items for detail view
          // Create a summary string for display
          'items_summary': _createItemsSummary(orderItems),
        });
      }

      if (!_recentOrdersController.isClosed) {
        _recentOrdersController.add(processedOrders);
        debugPrint('OrderService: Emitted ${processedOrders.length} recent orders to stream');
      }
    } catch (e) {
      debugPrint('OrderService: Error loading recent orders for stream: $e');
      if (!_recentOrdersController.isClosed) {
        _recentOrdersController.addError(e);
      }
    }
  }

  /// Helper method to create items summary (moved from account page)
  String _createItemsSummary(List<dynamic> orderItems) {
    if (orderItems.isEmpty) return 'No items';

    if (orderItems.length == 1) {
      final item = orderItems.first;
      final quantity = item['quantity'] ?? 1;
      final name = item['product_title'] ?? 'Unknown Product';
      return quantity > 1 ? '$quantity × $name' : name;
    } else if (orderItems.length == 2) {
      final item1 = orderItems[0];
      final item2 = orderItems[1];
      final name1 = item1['product_title'] ?? 'Unknown';
      final name2 = item2['product_title'] ?? 'Unknown';
      return '$name1, $name2';
    } else {
      final firstName = orderItems.first['product_title'] ?? 'Unknown';
      final remainingCount = orderItems.length - 1;
      return '$firstName + $remainingCount more';
    }
  }

  /// Create a new order with order items
  Future<Map<String, dynamic>?> createOrder({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    String status = 'Preparing', // Changed from 'Pending' to 'Preparing' to match DB constraint
  }) async {
    try {
      debugPrint('OrderService: Starting order creation...');
      debugPrint('OrderService: Items count: ${items.length}');
      debugPrint('OrderService: Total amount: $totalAmount');

      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('OrderService: User not authenticated');
        throw Exception('User not authenticated');
      }
      debugPrint('OrderService: User ID: ${user.id}');

      // Validate items before processing
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        debugPrint('OrderService: Item $i: ${item.toString()}');

        final productId = item['id']?.toString();
        if (productId == null || productId.isEmpty) {
          debugPrint('OrderService: Invalid product ID for item $i: $productId');
          throw Exception('Product ID is required for order item ${i + 1}');
        }

        // Validate product ID format (should be UUID or valid string for mock data)
        final isUuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$').hasMatch(productId);
        final isValidMockId = RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(productId);

        if (!isUuid && !isValidMockId) {
          debugPrint('OrderService: Invalid product ID format: $productId');
          throw Exception('Invalid product ID format for item ${i + 1}');
        }

        debugPrint('OrderService: Product ID validation passed - ID: $productId, isUuid: $isUuid, isMockId: $isValidMockId');
      }

      // Start a transaction-like operation
      // First, create the order
      debugPrint('OrderService: Creating order record...');
      debugPrint('OrderService: Order data - user_id: ${user.id}, total_amount: $totalAmount, status: $status');

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
      debugPrint('OrderService: Order created with ID: $orderId');

      // Then, create order items
      final orderItems = items.map((item) {
        final price = CurrencyFormatter.parsePeso(item['price'].toString());
        final productId = item['id']?.toString();

        debugPrint('OrderService: Processing item - Product ID: $productId, Price: ${item['price']}, Parsed Price: $price, Quantity: ${item['quantity']}');

        return {
          'order_id': orderId,
          'product_id': productId,
          'quantity': item['quantity'] ?? 1,
          'price': price,
        };
      }).toList();

      debugPrint('OrderService: Creating ${orderItems.length} order items...');
      await _supabase
          .from('order_items')
          .insert(orderItems);

      debugPrint('OrderService: Order creation completed successfully');

      // Send notification for order confirmation
      try {
        await NotificationHelper.notifyOrderConfirmed(
          orderId: orderId,
          totalAmount: totalAmount,
        );
      } catch (notificationError) {
        debugPrint('Failed to send order confirmation notification: $notificationError');
        // Don't fail the order creation if notification fails
      }

      return {
        'order_id': orderId,
        'order': orderResponse,
        'items': orderItems,
      };
    } catch (e) {
      debugPrint('OrderService: Error creating order: $e');
      debugPrint('OrderService: Error type: ${e.runtimeType}');
      if (e is PostgrestException) {
        debugPrint('OrderService: Postgrest error details: ${e.details}');
        debugPrint('OrderService: Postgrest error message: ${e.message}');
        debugPrint('OrderService: Postgrest error code: ${e.code}');

        // Check if it's a table not found error (common during development)
        if (e.message.contains('relation') && e.message.contains('does not exist')) {
          debugPrint('OrderService: Database tables not found, creating mock order for development');
          return _createMockOrder(items, totalAmount, status);
        }
      }
      return null;
    }
  }

  /// Create a mock order for development when database tables don't exist
  Map<String, dynamic> _createMockOrder(
    List<Map<String, dynamic>> items,
    double totalAmount,
    String status,
  ) {
    final mockOrderId = 'mock_${DateTime.now().millisecondsSinceEpoch}';
    final user = _supabase.auth.currentUser;

    debugPrint('OrderService: Creating mock order with ID: $mockOrderId');

    final mockOrder = {
      'id': mockOrderId,
      'user_id': user?.id ?? 'mock_user',
      'total_amount': totalAmount,
      'status': status,
      'created_at': DateTime.now().toIso8601String(),
    };

    final mockOrderItems = items.map((item) {
      final price = CurrencyFormatter.parsePeso(item['price'].toString());
      return {
        'id': 'mock_item_${DateTime.now().millisecondsSinceEpoch}_${items.indexOf(item)}',
        'order_id': mockOrderId,
        'product_id': item['id']?.toString(),
        'quantity': item['quantity'] ?? 1,
        'price': price,
      };
    }).toList();

    debugPrint('OrderService: Mock order created successfully');

    return {
      'order_id': mockOrderId,
      'order': mockOrder,
      'items': mockOrderItems,
    };
  }

  /// Get user's order history with pagination
  Future<List<Map<String, dynamic>>> getUserOrdersPaginated({
    required int page,
    required int limit,
    String? status,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      final offset = (page - 1) * limit;

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

      // Add ordering, offset, and limit
      final response = await queryBuilder
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // Process the response similar to getUserOrders
      return (response as List<dynamic>).map<Map<String, dynamic>>((order) {
        final orderItems = (order['order_items'] as List<dynamic>? ?? []).map<Map<String, dynamic>>((item) {
          final product = item['product'] as Map<String, dynamic>? ?? {};
          final productImages = product['product_images'] as List<dynamic>? ?? [];

          String productImage = 'assets/placeholder.png';
          if (productImages.isNotEmpty) {
            final thumbnailImage = productImages.firstWhere(
              (img) => img['is_thumbnail'] == true,
              orElse: () => productImages.first,
            );
            productImage = thumbnailImage['image_url'] ?? 'assets/placeholder.png';
          }

          return {
            ...item,
            'product_title': product['title'] ?? 'Unknown Product',
            'product_image': productImage,
          };
        }).toList();

        return {
          ...order,
          'order_items': orderItems,
        };
      }).toList();
    } catch (e) {
      debugPrint('OrderService: Error fetching paginated user orders: $e');
      return [];
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
      debugPrint('OrderService: Error fetching user orders: $e');
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
      debugPrint('OrderService: Error fetching order: $e');
      return null;
    }
  }

  /// Update order status with history tracking
  Future<bool> updateOrderStatus(String orderId, String status, {String? notes}) async {
    try {
      debugPrint('OrderService: Starting updateOrderStatus - orderId: $orderId, status: $status');

      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('OrderService: User not authenticated');
        return false;
      }

      debugPrint('OrderService: User authenticated: ${user.id}');

      // Update the order status
      final updateData = {'status': status};

      // Add timestamp fields based on status
      switch (status) {
        case 'Pending Delivery':
          // Order is ready for delivery
          debugPrint('OrderService: Setting status to Pending Delivery');
          break;
        case 'Order Confirmation':
          updateData['delivered_at'] = DateTime.now().toIso8601String();
          debugPrint('OrderService: Setting status to Order Confirmation with delivered_at');
          break;
        case 'Completed':
          updateData['confirmed_at'] = DateTime.now().toIso8601String();
          debugPrint('OrderService: Setting status to Completed with confirmed_at');
          break;
      }

      debugPrint('OrderService: Update data: $updateData');

      final updateResult = await _supabase
          .from('orders')
          .update(updateData)
          .eq('id', orderId)
          .eq('user_id', user.id)
          .select();

      debugPrint('OrderService: Update result: $updateResult');
      debugPrint('OrderService: Successfully updated order $orderId to status: $status');

      // Force refresh of order data to ensure UI updates
      await Future.delayed(const Duration(milliseconds: 100));
      await _refreshOrderData();

      // Add to status history (optional - only if table exists)
      try {
        await _supabase.from('order_status_history').insert({
          'order_id': orderId,
          'status': status,
          'changed_by': user.id,
          'notes': notes,
        });
      } catch (historyError) {
        // Continue even if history insert fails (table might not exist)
        debugPrint('OrderService: Status history insert failed (table might not exist): $historyError');
      }

      // Send notification for status change
      try {
        await NotificationHelper.notifyOrderStatusChanged(
          orderId: orderId,
          newStatus: status,
        );
      } catch (notificationError) {
        debugPrint('Failed to send order status notification: $notificationError');
        // Don't fail the status update if notification fails
      }

      debugPrint('OrderService: updateOrderStatus completed successfully');
      return true;
    } catch (e, stackTrace) {
      debugPrint('OrderService: Error updating order status: $e');
      debugPrint('OrderService: Stack trace: $stackTrace');
      return false;
    }
  }

  /// Get enhanced order statistics for user
  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {
          'total_orders': 0,
          'preparing_orders': 0,
          'pending_delivery_orders': 0,
          'user_confirmation_orders': 0,
          'completed_orders': 0,
          'total_spent': 0.0,
        };
      }

      final orders = await getUserOrders();

      int totalOrders = orders.length;
      int preparingOrders = orders.where((order) => order['status'] == 'Preparing').length;
      int pendingDeliveryOrders = orders.where((order) => order['status'] == 'Pending Delivery').length;
      int orderConfirmationOrders = orders.where((order) => order['status'] == 'Order Confirmation').length;
      int completedOrders = orders.where((order) => order['status'] == 'Completed').length;
      // Calculate total spent from completed orders only
      double totalSpent = orders
          .where((order) => order['status'] == 'Completed')
          .fold(0.0, (sum, order) => sum + (order['total_amount'] as num).toDouble());

      return {
        'total_orders': totalOrders,
        'preparing_orders': preparingOrders,
        'pending_delivery_orders': pendingDeliveryOrders,
        'order_confirmation_orders': orderConfirmationOrders,
        'completed_orders': completedOrders,
        'total_spent': totalSpent,
      };
    } catch (e) {
      debugPrint('OrderService: Error getting order stats: $e');
      return {
        'total_orders': 0,
        'preparing_orders': 0,
        'pending_delivery_orders': 0,
        'order_confirmation_orders': 0,
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
      debugPrint('OrderService: Error cancelling order: $e');
      return false;
    }
  }

  /// Confirm order receipt by user
  Future<bool> confirmOrderReceipt(String orderId) async {
    try {
      debugPrint('=== OrderService: confirmOrderReceipt called ===');
      debugPrint('OrderService: Confirming order receipt for order: $orderId');

      final user = _supabase.auth.currentUser;
      debugPrint('OrderService: Current user: ${user?.id}');

      final result = await updateOrderStatus(orderId, 'Completed', notes: 'Order confirmed by user');
      debugPrint('OrderService: Order confirmation result: $result');
      return result;
    } catch (e, stackTrace) {
      debugPrint('OrderService: Error confirming order: $e');
      debugPrint('OrderService: Stack trace: $stackTrace');
      return false;
    }
  }

  /// Progress order to next status (for admin or testing purposes)
  Future<bool> progressOrderToNextStatus(String orderId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      // Get current order status
      final orderResponse = await _supabase
          .from('orders')
          .select('status')
          .eq('id', orderId)
          .eq('user_id', user.id)
          .single();

      final currentStatus = orderResponse['status'] as String;
      String? nextStatus;

      // Determine next status based on current status
      switch (currentStatus) {
        case 'Preparing':
          nextStatus = 'Pending Delivery';
          break;
        case 'Pending Delivery':
          nextStatus = 'Order Confirmation';
          break;
        case 'Order Confirmation':
          nextStatus = 'Completed';
          break;
        default:
          debugPrint('OrderService: Cannot progress order from status: $currentStatus');
          return false;
      }

      debugPrint('OrderService: Progressing order $orderId from $currentStatus to $nextStatus');
      return await updateOrderStatus(orderId, nextStatus, notes: 'Order progressed to next stage');
    } catch (e) {
      debugPrint('OrderService: Error progressing order: $e');
      return false;
    }
  }

  /// Auto-progress orders for demo purposes (simulate admin actions)
  Future<void> autoProgressOrders() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Get orders that can be progressed (older than 30 seconds for demo)
      final cutoffTime = DateTime.now().subtract(const Duration(seconds: 30));

      final orders = await _supabase
          .from('orders')
          .select('id, status, created_at')
          .eq('user_id', user.id)
          .inFilter('status', ['Preparing', 'Pending Delivery'])
          .lt('created_at', cutoffTime.toIso8601String());

      for (final order in orders) {
        final orderId = order['id'] as String;
        final status = order['status'] as String;

        debugPrint('OrderService: Auto-progressing order $orderId from $status');
        await progressOrderToNextStatus(orderId);

        // Add small delay between progressions
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      debugPrint('OrderService: Error in auto-progress: $e');
    }
  }

  /// Get orders by status for better organization
  Future<Map<String, List<Map<String, dynamic>>>> getOrdersByStatus() async {
    try {
      final orders = await getUserOrders();

      final Map<String, List<Map<String, dynamic>>> ordersByStatus = {
        'Preparing': [],
        'Pending Delivery': [],
        'Order Confirmation': [],
        'Completed': [],
        'Cancelled': [],
      };

      for (final order in orders) {
        final status = order['status'] as String;
        if (ordersByStatus.containsKey(status)) {
          ordersByStatus[status]!.add(order);
        }
      }

      return ordersByStatus;
    } catch (e) {
      debugPrint('OrderService: Error getting orders by status: $e');
      return {
        'Preparing': [],
        'Pending Delivery': [],
        'Order Confirmation': [],
        'Completed': [],
        'Cancelled': [],
      };
    }
  }

  /// Get all recently bought products from completed orders with pagination
  /// This method is specifically for the "View All" recently bought page
  Future<List<Map<String, dynamic>>> getAllRecentlyBoughtProducts({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      final offset = (page - 1) * limit;

      // Get completed orders with product details, with pagination
      final recentOrders = await _supabase
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
          .eq('user_id', user.id)
          .eq('status', 'Completed')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // Extract products from order items
      List<Map<String, dynamic>> recentProducts = [];

      for (final order in recentOrders) {
        final orderItems = order['order_items'] as List<dynamic>? ?? [];
        for (final item in orderItems) {
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

          recentProducts.add({
            'id': item['product_id'],
            'name': item['product_title'] ?? product['title'] ?? 'Unknown Product',
            'image': imageUrl,
            'price': item['price'] ?? 0.0,
            'soldCount': item['quantity'] ?? 1,
            'order_date': order['created_at'],
            'rating': null, // Recently bought items don't need ratings
          });
        }
      }

      // Sort by order date (most recent first)
      recentProducts.sort((a, b) =>
        DateTime.parse(b['order_date']).compareTo(DateTime.parse(a['order_date']))
      );

      return recentProducts;
    } catch (e) {
      debugPrint('OrderService: Error fetching all recently bought products: $e');
      return [];
    }
  }

  /// Get order status display information
  static Map<String, dynamic> getOrderStatusInfo(String status) {
    switch (status) {
      case 'Preparing':
        return {
          'title': 'Order Preparation',
          'description': 'Your order is being prepared by our store',
          'icon': Icons.kitchen,
          'color': Colors.orange,
          'canCancel': true,
          'showConfirmButton': false,
        };
      case 'Pending Delivery':
        return {
          'title': 'Pending Delivery',
          'description': 'Your order is ready and waiting to be delivered',
          'icon': Icons.local_shipping,
          'color': Colors.blue,
          'canCancel': false,
          'showConfirmButton': false,
        };
      case 'Order Confirmation':
        return {
          'title': 'Order Confirmation',
          'description': 'Order delivered - Please confirm receipt',
          'icon': Icons.check_circle_outline,
          'color': Colors.purple,
          'canCancel': false,
          'showConfirmButton': true,
        };
      case 'Completed':
        return {
          'title': 'Completed',
          'description': 'Order completed successfully',
          'icon': Icons.check_circle,
          'color': Colors.green,
          'canCancel': false,
          'showConfirmButton': false,
        };
      case 'Cancelled':
        return {
          'title': 'Cancelled',
          'description': 'Order has been cancelled',
          'icon': Icons.cancel,
          'color': Colors.red,
          'canCancel': false,
          'showConfirmButton': false,
        };
      default:
        return {
          'title': 'Unknown',
          'description': 'Unknown order status',
          'icon': Icons.help,
          'color': Colors.grey,
          'canCancel': false,
          'showConfirmButton': false,
        };
    }
  }

  /// Format order date for display
  static String formatOrderDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown date';
    }
  }

  /// Dispose of resources and clean up subscriptions
  void dispose() {
    debugPrint('OrderService: Disposing resources...');

    // Unsubscribe from real-time subscriptions
    _ordersSubscription?.unsubscribe();
    _orderItemsSubscription?.unsubscribe();

    // Close stream controllers
    _ordersController.close();
    _orderStatsController.close();
    _recentOrdersController.close();

    debugPrint('OrderService: Disposed successfully');
  }
}
