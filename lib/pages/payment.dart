import 'package:flutter/material.dart';
import 'package:pet_smart/components/cart_service.dart';
import 'package:pet_smart/components/status_banner.dart';
import 'package:pet_smart/utils/currency_formatter.dart';
import 'package:pet_smart/services/order_service.dart';
import 'package:pet_smart/services/address_service.dart';
import 'package:pet_smart/pages/setting/address_book.dart';

// Add color constants to match with cart.dart
const Color primaryRed = Color(0xFFE57373);
const Color primaryBlue = Color(0xFF3F51B5);
const Color accentRed = Color(0xFFEF5350);
const Color backgroundColor = Color(0xFFF6F7FB);

class PaymentPage extends StatefulWidget {
  // Add a parameter to accept a direct purchase item
  final Map<String, dynamic>? directPurchaseItem;

  const PaymentPage({super.key, this.directPurchaseItem});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final CartService _cartService = CartService();
  final OrderService _orderService = OrderService();
  final AddressService _addressService = AddressService();
  Map<String, dynamic>? _selectedAddress;
  bool _isProcessing = false;
  bool _isLoadingAddresses = true;
  // List to hold all items being purchased (from cart or direct purchase)
  late List<Map<String, dynamic>> _itemsForPurchase;
  // Real addresses from Supabase
  List<Map<String, dynamic>> _availableAddresses = [];

  @override
  void initState() {
    super.initState();
    // Initialize items for purchase
    _initializeItemsForPurchase();
    // Load user addresses
    _loadAddresses();
  }

  void _initializeItemsForPurchase() {
    if (widget.directPurchaseItem != null) {
      // If direct purchase, use that item
      // Add quantity if not present
      final directItem = Map<String, dynamic>.from(widget.directPurchaseItem!);
      if (!directItem.containsKey('quantity')) {
        directItem['quantity'] = 1;
      }
      _itemsForPurchase = [directItem];
    } else {
      // Otherwise use cart items
      _itemsForPurchase = List<Map<String, dynamic>>.from(_cartService.items);
    }
  }

  // Calculate subtotal for the purchase
  double _calculateSubtotal() {
    return _itemsForPurchase.fold(0, (total, item) {
      final price = CurrencyFormatter.parsePeso(item['price'].toString());
      return total + (price * (item['quantity'] ?? 1));
    });
  }

  // Load user addresses from Supabase
  Future<void> _loadAddresses() async {
    try {
      setState(() {
        _isLoadingAddresses = true;
      });

      final addresses = await _addressService.getUserAddresses();

      if (mounted) {
        setState(() {
          _availableAddresses = addresses.map((address) =>
            AddressService.toUIFormat(address)
          ).toList();
          _isLoadingAddresses = false;

          // Set default address if available
          if (_availableAddresses.isNotEmpty) {
            _selectedAddress = _availableAddresses.firstWhere(
              (address) => address['isDefault'] == true,
              orElse: () => _availableAddresses.first,
            );
          }
        });
      }
    } catch (e) {
      print('PaymentPage: Error loading addresses: $e');
      if (mounted) {
        setState(() {
          _isLoadingAddresses = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = _calculateSubtotal();
    final deliveryFee = 149.50; // Converted from $2.99 to ₱149.50
    final tax = subtotal * 0.08; // 8% tax
    final total = subtotal + deliveryFee + tax;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _itemsForPurchase.isEmpty
          ? _buildEmptyCart(context)
          : _buildCheckoutContent(context, _itemsForPurchase, subtotal, deliveryFee, tax, total),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to your cart to checkout',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Return to Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutContent(
    BuildContext context,
    List<Map<String, dynamic>> itemsForPurchase,
    double subtotal,
    double deliveryFee,
    double tax,
    double total
  ) {
    return Column(
      children: [
        // Main content (scrollable)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Delivery Location Section
                _buildLocationSection(),
                const SizedBox(height: 20),

                // 2. Order Items Section
                _buildOrderItemsSection(itemsForPurchase),
                const SizedBox(height: 20),

                // 3. Payment Method Section
                _buildPaymentMethodSection(),
                const SizedBox(height: 20),

                // 4. Payment Details Section
                _buildPaymentDetailsSection(subtotal, deliveryFee, tax, total),
              ],
            ),
          ),
        ),

        // 5. Bottom Navigation Bar (Static)
        _buildBottomNavBar(context, total),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Delivery Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                onTap: _isLoadingAddresses ? null : _showLocationPicker,
                child: Text(
                  'Change',
                  style: TextStyle(
                    color: _isLoadingAddresses ? Colors.grey : primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingAddresses)
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loading addresses...',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            )
          else if (_selectedAddress == null && _availableAddresses.isEmpty)
            Row(
              children: [
                Icon(
                  Icons.location_off_outlined,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'No addresses found',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddressBookPage(),
                          ),
                        ).then((_) => _loadAddresses()),
                        child: Text(
                          'Add your first address',
                          style: TextStyle(
                            color: primaryBlue,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedAddress?['name'] ?? 'No address selected',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_selectedAddress != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _selectedAddress!['address'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsSection(List<Map<String, dynamic>> itemsForPurchase) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Items',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: itemsForPurchase.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final item = itemsForPurchase[index];
              final price = CurrencyFormatter.parsePeso(item['price'].toString());
              final quantity = item['quantity'] ?? 1;
              final itemTotal = price * quantity;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Thumbnail
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        item['image'] ?? 'assets/placeholder.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Item details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] ?? item['title'] ?? 'Unknown Product',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              CurrencyFormatter.formatPeso(price),
                              style: TextStyle(
                                fontSize: 13,
                                color: primaryRed,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'x$quantity',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Item total
                  Text(
                    CurrencyFormatter.formatPeso(itemTotal),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: primaryBlue),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  color: primaryBlue,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Cash On Delivery (COD)',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.check_circle,
                  color: primaryBlue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Only Cash on Delivery is available at the moment',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsSection(double subtotal, double deliveryFee, double tax, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildPaymentRow('Subtotal', CurrencyFormatter.formatPeso(subtotal)),
          _buildPaymentRow('Delivery Fee', CurrencyFormatter.formatPeso(deliveryFee)),
          _buildPaymentRow('Tax (8%)', CurrencyFormatter.formatPeso(tax)),
          const Divider(height: 24),
          _buildPaymentRow(
            'Total',
            CurrencyFormatter.formatPeso(total),
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.black : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 18 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold ? primaryBlue : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Total price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Total Price',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatPeso(total),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
            ),

            // Place order button
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isProcessing || _selectedAddress == null)
                      ? null
                      : () => _placeOrder(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_selectedAddress == null)
                        ? Colors.grey[400]
                        : primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _selectedAddress == null
                              ? 'Select Address'
                              : 'Place Order',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Delivery Address',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_availableAddresses.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.location_off_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No addresses found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first delivery address to continue',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...List.generate(
                _availableAddresses.length,
                (index) {
                  final address = _availableAddresses[index];
                  final isSelected = _selectedAddress?['id'] == address['id'];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primaryBlue.withValues(alpha: 0.1),
                        child: Icon(
                          _getAddressIcon(address['name']),
                          color: primaryBlue,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        address['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            address['address'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (address['phoneNumber']?.isNotEmpty == true)
                            Text(
                              address['phoneNumber'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: primaryBlue)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedAddress = address;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to address book and refresh addresses when returning
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddressBookPage(),
                    ),
                  ).then((_) => _loadAddresses());
                },
                icon: const Icon(Icons.add),
                label: Text(_availableAddresses.isEmpty ? 'Add Address' : 'Manage Addresses'),
                style: TextButton.styleFrom(
                  foregroundColor: primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAddressIcon(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('home')) {
      return Icons.home_outlined;
    } else if (lowerName.contains('work') || lowerName.contains('office')) {
      return Icons.business_outlined;
    } else if (lowerName.contains('school') || lowerName.contains('college')) {
      return Icons.school_outlined;
    } else if (lowerName.contains('gym')) {
      return Icons.fitness_center_outlined;
    } else {
      return Icons.place_outlined;
    }
  }

  Future<void> _placeOrder(BuildContext context) async {
    // Start loading indicator
    setState(() {
      _isProcessing = true;
    });

    try {
      // Calculate total amount
      final subtotal = _calculateSubtotal();
      final deliveryFee = 149.50;
      final tax = subtotal * 0.08;
      final total = subtotal + deliveryFee + tax;

      // Create order in Supabase
      final orderResult = await _orderService.createOrder(
        items: _itemsForPurchase,
        totalAmount: total,
        status: 'Preparing', // Start with Preparing status (matches DB constraint)
      );

      if (orderResult != null) {
        // Order created successfully

        // Only clear the cart if this wasn't a direct purchase
        if (widget.directPurchaseItem == null) {
          await _cartService.clear();
        }

        // Navigate to the confirmation page
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CustomConfirmationPage(
                title: "Payment Completed",
                message: "Your order has been placed successfully. Order ID: ${orderResult['order_id']}",
                buttonText: "Back to Home",
                icon: Icons.check_circle,
                iconColor: Colors.green,
              ),
            ),
          );
        }
      } else {
        // Order creation failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to place order. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Handle errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
