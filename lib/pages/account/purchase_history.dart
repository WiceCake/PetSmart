import 'package:flutter/material.dart';
import 'package:pet_smart/services/order_service.dart';
import 'package:pet_smart/utils/currency_formatter.dart';
import 'package:intl/intl.dart';
import 'package:pet_smart/components/skeleton_screens.dart';
import 'package:pet_smart/components/optimized_image.dart';
import 'package:pet_smart/services/lazy_loading_service.dart';

// Enhanced color constants matching app design patterns
const Color primaryBlue = Color(0xFF233A63);     // Main primary color
const Color secondaryBlue = Color(0xFF3F51B5);   // Secondary blue
const Color primaryRed = Color(0xFFE57373);      // Light coral red
const Color accentRed = Color(0xFFEF5350);       // Brighter red for emphasis
const Color backgroundColor = Color(0xFFF8F9FA); // Light background
const Color cardColor = Colors.white;            // Card background
const Color successGreen = Color(0xFF4CAF50);    // Success green
const Color warningOrange = Color(0xFFFF9800);   // Warning orange
const Color textPrimary = Color(0xFF222222);     // Primary text
const Color textSecondary = Color(0xFF666666);   // Secondary text
const Color borderColor = Color(0xFFE0E0E0);     // Border color

class PurchaseHistoryPage extends StatefulWidget {
  final String? initialFilter;

  const PurchaseHistoryPage({super.key, this.initialFilter});

  @override
  State<PurchaseHistoryPage> createState() => _PurchaseHistoryPageState();
}

class _PurchaseHistoryPageState extends State<PurchaseHistoryPage> {
  final OrderService _orderService = OrderService();
  bool _isInitialLoading = true;
  String _selectedFilter = 'All';
  late LazyLoadingService<Map<String, dynamic>> _lazyLoadingService;

  final List<String> _filterOptions = ['All', 'Preparing', 'Pending Delivery', 'Order Confirmation', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter ?? 'All';

    // Initialize lazy loading service
    _lazyLoadingService = LazyLoadingService<Map<String, dynamic>>(
      loadData: _loadOrdersPage,
      pageSize: 20,
    );

    _loadInitialData();
  }

  @override
  void dispose() {
    _lazyLoadingService.dispose();
    super.dispose();
  }

  /// Load orders page for lazy loading
  Future<List<Map<String, dynamic>>> _loadOrdersPage(int page, int limit) async {
    try {
      final orders = await _orderService.getUserOrdersPaginated(
        page: page,
        limit: limit,
        status: _selectedFilter == 'All' ? null : _selectedFilter,
      );
      return orders;
    } catch (e) {
      debugPrint('Error loading orders page: $e');
      return [];
    }
  }

  /// Load initial data with skeleton loading
  Future<void> _loadInitialData() async {
    setState(() {
      _isInitialLoading = true;
    });

    // Load data immediately without delay
    await _lazyLoadingService.loadInitial();

    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }



  Future<void> _refreshOrders() async {
    // Trigger OrderService refresh to ensure real-time data sync
    await _orderService.refreshOrderData();
    // Then refresh the lazy loading service
    await _lazyLoadingService.refresh();
  }

  /// Handle pull-to-refresh with auto-progress
  Future<void> _handlePullToRefresh() async {
    // Trigger auto-progress and refresh when user explicitly pulls to refresh
    await _orderService.refreshWithAutoProgress();
    await _lazyLoadingService.refresh();
  }

  Future<void> _refreshWithNewFilter() async {
    // Reinitialize the lazy loading service with new filter
    _lazyLoadingService.dispose();
    _lazyLoadingService = LazyLoadingService<Map<String, dynamic>>(
      loadData: _loadOrdersPage,
      pageSize: 20,
    );
    await _lazyLoadingService.loadInitial();
  }

  Widget _buildOrdersList() {
    // Show skeleton loading during initial load
    if (_isInitialLoading) {
      return SkeletonScreens.listSkeleton(
        itemCount: 5,
        itemBuilder: () => SkeletonScreens.orderCardSkeleton(),
      );
    }

    // Use lazy loading for orders with custom refresh
    return RefreshIndicator(
      onRefresh: _handlePullToRefresh,
      child: LazyLoadingListView<Map<String, dynamic>>(
        service: _lazyLoadingService,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, order, index) {
          return _buildOrderCard(order);
        },
        loadingWidget: SkeletonScreens.orderCardSkeleton(),
        emptyWidget: _buildEmptyState(),
        errorWidget: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load orders',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pull to refresh and try again',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Purchase History',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: cardColor,
        foregroundColor: textPrimary,
        elevation: 0,
        shadowColor: Colors.grey.withValues(alpha: 0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list, color: primaryBlue),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
              // Refresh data when filter changes
              _refreshWithNewFilter();
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => _filterOptions.map((filter) {
              return PopupMenuItem<String>(
                value: filter,
                child: Row(
                  children: [
                    if (_selectedFilter == filter)
                      Icon(Icons.check, color: primaryBlue, size: 20),
                    if (_selectedFilter == filter) const SizedBox(width: 8),
                    Text(
                      filter,
                      style: TextStyle(
                        color: _selectedFilter == filter ? primaryBlue : textPrimary,
                        fontWeight: _selectedFilter == filter ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: _buildOrdersList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 64,
                color: primaryBlue.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _selectedFilter == 'All'
                  ? 'No orders yet'
                  : 'No ${_selectedFilter.toLowerCase()} orders',
              style: const TextStyle(
                fontSize: 20,
                color: textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _selectedFilter == 'All'
                  ? 'Start shopping to see your orders here!'
                  : 'Try changing the filter to see other orders.',
              style: const TextStyle(
                fontSize: 16,
                color: textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderDate = DateTime.parse(order['created_at']);
    final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(orderDate);
    final orderItems = order['order_items'] as List<dynamic>? ?? [];
    final totalAmount = (order['total_amount'] as num).toDouble();
    final status = order['status'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: borderColor.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showOrderDetails(order),
        splashColor: primaryBlue.withValues(alpha: 0.05),
        highlightColor: primaryBlue.withValues(alpha: 0.02),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order['id'].toString().substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStatusChip(status),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Order items preview
              if (orderItems.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${orderItems.length} item${orderItems.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 64,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: orderItems.length > 3 ? 3 : orderItems.length,
                    itemBuilder: (context, index) {
                      final item = orderItems[index];
                      return Container(
                        width: 64,
                        height: 64,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: backgroundColor,
                          border: Border.all(
                            color: borderColor.withValues(alpha: 0.5),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: OptimizedImage.product(
                          imageUrl: item['product_image'],
                          width: 64,
                          height: 64,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      );
                    },
                  ),
                ),
                if (orderItems.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '+${orderItems.length - 3} more items',
                      style: const TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatPeso(totalAmount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final statusInfo = OrderService.getOrderStatusInfo(status);
    final color = statusInfo['color'] as Color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) async {
    // Navigate to order details page or show bottom sheet
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _OrderDetailsSheet(order: order),
    );

    // Refresh orders if confirmation was successful
    if (result == true) {
      debugPrint('PurchaseHistory: Order confirmation successful, refreshing UI...');
      // Force a complete refresh to ensure UI updates
      await _refreshOrders();
      debugPrint('PurchaseHistory: Main refresh completed');
      // Also refresh the filter to ensure the order appears in the correct status
      if (_selectedFilter != 'All') {
        debugPrint('PurchaseHistory: Refreshing with filter: $_selectedFilter');
        await _refreshWithNewFilter();
      }
      debugPrint('PurchaseHistory: All refreshes completed');
    }
  }
}

class _OrderDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> order;

  const _OrderDetailsSheet({required this.order});

  @override
  State<_OrderDetailsSheet> createState() => _OrderDetailsSheetState();
}

class _OrderDetailsSheetState extends State<_OrderDetailsSheet> {
  final OrderService _orderService = OrderService();
  bool _isConfirming = false;

  @override
  Widget build(BuildContext context) {
    final orderDate = DateTime.parse(widget.order['created_at']);
    final formattedDate = DateFormat('MMMM dd, yyyy • hh:mm a').format(orderDate);
    final orderItems = widget.order['order_items'] as List<dynamic>? ?? [];
    final totalAmount = (widget.order['total_amount'] as num).toDouble();
    final status = widget.order['status'] as String;
    final statusInfo = OrderService.getOrderStatusInfo(status);

    debugPrint('OrderDetailsSheet: Order status: $status');
    debugPrint('OrderDetailsSheet: Status info: $statusInfo');
    debugPrint('OrderDetailsSheet: Show confirm button: ${statusInfo['showConfirmButton']}');

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Order Details',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: textSecondary),
                        iconSize: 20,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                color: borderColor.withValues(alpha: 0.5),
                thickness: 1,
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order info
                      _buildInfoSection('Order Information', [
                        _buildInfoRow('Order ID', '#${widget.order['id'].toString().substring(0, 8)}'),
                        _buildInfoRow('Date', formattedDate),
                        _buildInfoRow('Status', status, isStatus: true),
                        _buildInfoRow('Total', CurrencyFormatter.formatPeso(totalAmount)),
                      ]),

                      const SizedBox(height: 24),

                      // Order items
                      _buildItemsSection(orderItems),

                      const SizedBox(height: 24),

                      // Confirmation button for User Confirmation status
                      if (statusInfo['showConfirmButton'] == true)
                        _buildConfirmationButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfirmationButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton(
        onPressed: _isConfirming ? null : () {
          debugPrint('PurchaseHistory: Confirm button pressed!');
          _confirmOrder();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: successGreen,
          foregroundColor: cardColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
          shadowColor: successGreen.withValues(alpha: 0.3),
        ),
        child: _isConfirming
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Confirm Order Receipt',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _confirmOrder() async {
    debugPrint('=== PurchaseHistory: _confirmOrder method called ===');
    debugPrint('PurchaseHistory: Starting order confirmation for order: ${widget.order['id']}');
    debugPrint('PurchaseHistory: Current _isConfirming state: $_isConfirming');

    setState(() {
      _isConfirming = true;
    });

    try {
      debugPrint('PurchaseHistory: Calling confirmOrderReceipt...');
      final success = await _orderService.confirmOrderReceipt(widget.order['id']);
      debugPrint('PurchaseHistory: confirmOrderReceipt result: $success');

      if (success) {
        debugPrint('PurchaseHistory: Order confirmation successful');
        if (mounted) {
          // Add a small delay to ensure database update is processed
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            debugPrint('PurchaseHistory: Closing dialog and showing success message');
            Navigator.pop(context, true); // Return true to indicate refresh needed
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Order confirmed successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        debugPrint('PurchaseHistory: Order confirmation failed');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to confirm order. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('PurchaseHistory: Error during order confirmation: $e');
      debugPrint('PurchaseHistory: Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });
      }
    }
  }



  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryBlue,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: backgroundColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          isStatus
              ? _buildStatusChip(value)
              : Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final statusInfo = OrderService.getOrderStatusInfo(status);
    final color = statusInfo['color'] as Color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildItemsSection(List<dynamic> orderItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items (${orderItems.length})',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryBlue,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orderItems.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final item = orderItems[index];
            return _buildOrderItem(item);
          },
        ),
      ],
    );
  }

  Widget _buildOrderItem(dynamic item) {
    // Safely cast the item to Map<String, dynamic>
    final itemMap = Map<String, dynamic>.from(item as Map);
    final quantity = (itemMap['quantity'] as num?)?.toInt() ?? 1;
    final price = (itemMap['price'] as num?)?.toDouble() ?? 0.0;
    final itemTotal = price * quantity;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Product image
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: backgroundColor,
              border: Border.all(
                color: borderColor.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildProductImage(itemMap['product_image']?.toString()),
            ),
          ),

          const SizedBox(width: 16),

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemMap['product_title']?.toString() ?? 'Unknown Product',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Qty: $quantity',
                    style: TextStyle(
                      fontSize: 12,
                      color: primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.formatPeso(itemTotal),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Icon(Icons.image_not_supported, color: textSecondary, size: 28);
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.image_not_supported, color: textSecondary, size: 28),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
              strokeWidth: 2,
            ),
          );
        },
      );
    } else {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.image_not_supported, color: textSecondary, size: 28),
      );
    }
  }
}
