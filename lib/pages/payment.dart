import 'package:flutter/material.dart';
import 'package:pet_smart/components/cart_service.dart';
import 'package:pet_smart/components/status_banner.dart';

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
  String _selectedLocation = 'Home Address';
  bool _isProcessing = false;
  // List to hold all items being purchased (from cart or direct purchase)
  late List<Map<String, dynamic>> _itemsForPurchase;

  // Predefined locations for demo
  final List<String> _availableLocations = [
    'Home Address',
    'Work Address',
    'Other Address'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize items for purchase
    _initializeItemsForPurchase();
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
      final price = double.tryParse(item['price'].toString().replaceAll('\$', '')) ?? 0;
      return total + (price * (item['quantity'] ?? 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = _calculateSubtotal();
    final deliveryFee = 2.99;
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
            color: Colors.black.withOpacity(0.05),
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
                onTap: _showLocationPicker,
                child: Text(
                  'Change',
                  style: TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _selectedLocation,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 15,
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
              final price = double.tryParse(item['price'].toString().replaceAll('\$', '')) ?? 0;
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
                        item['image'],
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
                          item['name'],
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
                              '\$${price.toStringAsFixed(2)}',
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
                    '\$${itemTotal.toStringAsFixed(2)}',
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
          _buildPaymentRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
          _buildPaymentRow('Delivery Fee', '\$${deliveryFee.toStringAsFixed(2)}'),
          _buildPaymentRow('Tax (8%)', '\$${tax.toStringAsFixed(2)}'),
          const Divider(height: 24),
          _buildPaymentRow(
            'Total',
            '\$${total.toStringAsFixed(2)}',
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
                    '\$${total.toStringAsFixed(2)}',
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
                  onPressed: _isProcessing ? null : () => _placeOrder(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
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
                      : const Text(
                          'Place Order',
                          style: TextStyle(
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
            const Text(
              'Select Delivery Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(
              _availableLocations.length,
              (index) => ListTile(
                leading: Icon(
                  Icons.location_on_outlined,
                  color: primaryBlue,
                ),
                title: Text(_availableLocations[index]),
                trailing: _selectedLocation == _availableLocations[index]
                    ? Icon(Icons.check_circle, color: primaryBlue)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedLocation = _availableLocations[index];
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                // In a real app, this would navigate to an "Add new address" page
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Add new address feature coming soon!'),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New Address'),
              style: TextButton.styleFrom(
                foregroundColor: primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _placeOrder(BuildContext context) {
    // Start loading indicator
    setState(() {
      _isProcessing = true;
    });

    // Simulating order processing
    Future.delayed(const Duration(seconds: 2), () {
      // Reset loading state
      setState(() {
        _isProcessing = false;
      });

      // Only clear the cart if this wasn't a direct purchase
      if (widget.directPurchaseItem == null) {
        _cartService.clear();
      }
      
      // Navigate to the confirmation page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const CustomConfirmationPage(
            title: "Payment Completed",
            message: "Your order has been placed successfully. You will receive a confirmation soon.",
            buttonText: "Back to Home",
            icon: Icons.check_circle,
            iconColor: Colors.green,
          ),
        ),
      );
    });
  }
}
