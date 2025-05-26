import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pet_smart/pages/account/liked_items.dart';
import 'package:pet_smart/pages/account/add_pet.dart'; // Updated import path
import 'dart:math' as math;
import 'package:pet_smart/pages/view_all_products.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late ScrollController _scrollController;
  bool _isScrolled = false;

  // Add recently bought products list
  final List<Map<String, dynamic>> recentlyBought = [
    {
      'name': 'Product Name 1',
      'image': 'assets/product_placeholder.png',
      'price': 24.99,
      'rating': 4.5,
      'soldCount': 2,
    },
    {
      'name': 'Product Name 2',
      'image': 'assets/product_placeholder.png',
      'price': 19.99,
      'rating': 4.2,
      'soldCount': 1,
    },
    {
      'name': 'Product Name 3',
      'image': 'assets/product_placeholder.png',
      'price': 29.99,
      'rating': 4.8,
      'soldCount': 3,
    },
    {
      'name': 'Product Name 4',
      'image': 'assets/product_placeholder.png',
      'price': 15.99,
      'rating': 4.0,
      'soldCount': 1,
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          _isScrolled = _scrollController.offset > 0;
        });
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileSection(),
              _buildPurchasesSection(),
              _buildLikedItemsSection(context), // Added Liked Items section
              _buildPetsSection(),
              _buildRecentlyBoughtSection(),
              const SizedBox(height: 20), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center( // Added Center widget here
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Added center alignment
          children: [
            // Profile picture with edit button
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Hero(
                  tag: 'profile_picture',
                  child: Container(
                    width: 120, // Increased size slightly
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/profile.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.person, size: 60, color: Colors.grey[600]),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Material(
                  color: Colors.blue,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20), // Increased spacing
            // User info with fade in animation
            FadeTransition(
              opacity: _controller,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Added center alignment
                children: [
                  Text(
                    '@username',
                    textAlign: TextAlign.center, // Added center alignment
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Full Name',
                    textAlign: TextAlign.center, // Added center alignment
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pet lover and enthusiast',
                    textAlign: TextAlign.center, // Added center alignment
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchasesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Purchases',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPurchaseItem(Icons.local_shipping_outlined, 'To Receive'),
              _buildPurchaseItem(Icons.star_outline, 'To Rate'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.grey[700]),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLikedItemsSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8), // Reduced vertical padding for a single item
      color: Colors.white,
      child: ListTile(
        leading: Icon(Icons.favorite_border, color: Colors.red[400], size: 28),
        title: const Text(
          'Liked Items',
          style: TextStyle(
            fontSize: 17, // Slightly adjusted font size
            fontWeight: FontWeight.w500, // Medium weight
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LikedItemsPage()),
          );
        },
      ),
    );
  }

  Widget _buildPetsSection() {
    final List<Map<String, String>> pets = [
      {'name': 'Max', 'type': 'Dog', 'gender': 'Male'},
      {'name': 'Luna', 'type': 'Cat', 'gender': 'Female'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Pets',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddPetAccountScreen()),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.blue),
                label: Text(
                  'Add Pet',
                  style: TextStyle(color: Colors.blue[700]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.0,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: math.min(6, pets.length), // Import 'dart:math' as math
            itemBuilder: (context, index) {
              if (index < pets.length) {
                final pet = pets[index];
                return _buildPetCard(
                  pet['name'] ?? 'Unknown',
                  pet['type'] ?? 'Other',
                  pet['gender'] ?? 'Unknown',
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(String name, String type, String gender) {
    IconData getPetIcon(String type) {
      switch (type.toLowerCase()) {
        case 'dog':
          return FontAwesomeIcons.dog;
        case 'cat':
          return FontAwesomeIcons.cat;
        case 'bird':
          return FontAwesomeIcons.dove;
        case 'fish':
          return FontAwesomeIcons.fish;
        case 'hamster':
          return FontAwesomeIcons.kiwiBird;
        default:
          return FontAwesomeIcons.paw;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: FaIcon(
                getPetIcon(type),
                size: 24,
                color: Colors.blue[700],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '$type • $gender',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyBoughtSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recently Bought',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewAllProductsPage(
                        title: 'Recently Bought',
                        products: recentlyBought,
                      ),
                    ),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75, // Adjusted for more height
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return _buildRecentItemCard(
                recentlyBought[index]['name'],
                recentlyBought[index]['image'],
                'Product description goes here',
                recentlyBought[index]['soldCount'],
                recentlyBought[index]['price'],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItemCard(
    String name,
    String image,
    String description,
    int quantity,
    double price,
  ) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image - Made responsive with AspectRatio
            AspectRatio(
              aspectRatio: 16 / 9, // Changed to make image shorter, giving more vertical space
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.broken_image, size: 40, color: Colors.grey[600]),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Product Details
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15, // Slightly reduced font size
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13, // Slightly reduced font size
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            // Quantity and Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Qty: $quantity',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
