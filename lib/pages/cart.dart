import 'package:flutter/material.dart';
import 'package:pet_smart/components/cart_service.dart';
import 'package:pet_smart/pages/shop/dashboard.dart';
import 'package:pet_smart/pages/payment.dart'; // Add import for payment page

// Add color constants
const Color primaryRed = Color(0xFFE57373);    // Light coral red
const Color primaryBlue = Color(0xFF3F51B5);   // PetSmart blue
const Color accentRed = Color(0xFFEF5350);     // Brighter red for emphasis
const Color backgroundColor = Color(0xFFF6F7FB); // Light background

// Add cart item model
class CartItem {
  final String name;
  final String image;
  final double price;
  int quantity;

  CartItem({
    required this.name,
    required this.image,
    required this.price,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image': image,
      'price': price,
      'quantity': quantity,
    };
  }
}

class CartPage extends StatefulWidget {
  final bool showBackButton;

  const CartPage({
    super.key,
    this.showBackButton = true, // Default to true for normal navigation
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartService _cartService = CartService();
  Set<int> selectedItems = {};

  @override
  Widget build(BuildContext context) {
    final cartItems = _cartService.items;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('My Cart'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: widget.showBackButton ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context), // This will go back to the previous screen
        ) : null,
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return _CartItemCard(
                        item: item,
                        index: index,
                        isSelected: selectedItems.contains(index),
                        onSelect: (selected) {
                          setState(() {
                            if (selected) {
                              selectedItems.add(index);
                            } else {
                              selectedItems.remove(index);
                            }
                          });
                        },
                        onQuantityChanged: (quantity) {
                          setState(() {
                            _cartService.updateQuantity(index, quantity);
                          });
                        },
                        onRemove: () {
                          setState(() {
                            _cartService.removeItem(index);
                            selectedItems.remove(index);
                          });
                        },
                      );
                    },
                  ),
                ),
                if (selectedItems.isNotEmpty) _buildCheckoutBar(),
              ],
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Cart icon in circle
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 60,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          // Title
          const Text(
            'Your Cart is Empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          // Subtitle
          Text(
            'Looks like you haven\'t made your choice yet.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          // Start Shopping Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => DashboardShopScreen(),
                ),
              );
            },
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Start Shopping'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(200, 48),
              padding: const EdgeInsets.symmetric(horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total (${selectedItems.length} items)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '\$${_cartService.getTotal().toStringAsFixed(2)}',
                  style: TextStyle(
                    color: primaryBlue,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to the payment page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Proceed to Checkout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;
  final bool isSelected;
  final Function(bool) onSelect;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.index,
    required this.isSelected,
    required this.onSelect,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // Determine border color based on selection
    final borderColor = isSelected ? primaryBlue.withOpacity(0.5) : Colors.grey[200]!;
    final borderWidth = isSelected ? 1.5 : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // Slightly less rounded
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), // Softer shadow
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Consistent padding
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // Vertically center items
          children: [
            // 1. Checkbox
            SizedBox(
              width: 24,
              height: 24,
              child: Transform.scale(
                scale: 0.95, // Slightly larger scale for checkbox
                child: Checkbox(
                  value: isSelected,
                  onChanged: (value) => onSelect(value!),
                  activeColor: primaryBlue,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4), // Less rounded checkbox
                  ),
                  side: BorderSide(color: Colors.grey[400]!, width: 1.5),
                ),
              ),
            ),
            const SizedBox(width: 8), // Reduced space
 
            // 2. Thumbnail
            Container(
              width: 70,
              height: 70,
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
                    Icons.broken_image_outlined,
                    size: 30,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10), // Reduced space
 
            // 3. Title & 4. Price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item['name'],
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '\$${(item['price'] as num).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: primaryRed,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8), // Reduced space before spinner
 
            // 5. Qty (Spinner)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0), // More compact
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _QuantityButton(
                    icon: Icons.remove,
                    onPressed: () {
                      if (item['quantity'] > 1) {
                        onQuantityChanged(item['quantity'] - 1);
                      }
                    },
                    iconSize: 16, // Reduced icon size
                    color: Colors.black54,
                    padding: const EdgeInsets.all(4), // Reduced padding
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 20, maxWidth: 30), // Reduced constraints
                    padding: const EdgeInsets.symmetric(horizontal: 1), // Reduced padding
                    alignment: Alignment.center,
                    child: Text(
                      item['quantity'].toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13, // Reduced font size
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  _QuantityButton(
                    icon: Icons.add,
                    onPressed: () {
                      onQuantityChanged(item['quantity'] + 1);
                    },
                    iconSize: 16, // Reduced icon size
                    color: Colors.black54,
                    padding: const EdgeInsets.all(4), // Reduced padding
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4), // Reduced space before delete

            // Delete Button (kept, but styled to be less prominent)
            SizedBox(
              width: 36, // Slightly larger tap area
              height: 36,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.delete_outline_rounded, color: Colors.grey[500], size: 22), // Adjusted size and color
                onPressed: onRemove,
                tooltip: 'Remove item',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double iconSize;
  final Color color;
  final EdgeInsets padding;

  const _QuantityButton({
    required this.icon,
    required this.onPressed,
    this.iconSize = 18.0, // Default icon size
    this.color = Colors.black54, // Default color
    this.padding = const EdgeInsets.all(8.0), // Default padding
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30), // Make it very rounded for circular tap effect
        child: Padding(
          padding: padding,
          child: Icon(
            icon,
            size: iconSize,
            color: color,
          ),
        ),
      ),
    );
  }
}