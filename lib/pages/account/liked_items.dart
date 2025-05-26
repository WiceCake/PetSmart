import 'package:flutter/material.dart';
import 'package:pet_smart/pages/shop/item_detail.dart'; // Import ItemDetailScreen

// Define color constants, or import from a shared file if available
const Color primaryBlue = Color(0xFF3F51B5); // PetSmart blue
const Color backgroundColor = Color(0xFFF6F7FB); // Light background

class LikedItemsPage extends StatefulWidget {
  const LikedItemsPage({super.key});

  @override
  State<LikedItemsPage> createState() => _LikedItemsPageState();
}

class _LikedItemsPageState extends State<LikedItemsPage> {
  // Mock data for liked items - replace with actual data source
  final List<Map<String, dynamic>> _likedItems = [
    {
      'name': 'Premium Dog Food',
      'image': 'assets/food1.png', // Ensure this asset exists
      'price': 24.99,
      'rating': 4.5,
    },
    {
      'name': 'Interactive Cat Toy',
      'image': 'assets/toy1.png', // Ensure this asset exists
      'price': 15.75,
      'rating': 4.8,
    },
    {
      'name': 'Cozy Pet Bed',
      'image': 'assets/bed1.png', // Ensure this asset exists
      'price': 35.00,
      'rating': 4.2,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Liked Items'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _likedItems.isEmpty
          ? _buildEmptyLikedItems()
          : _buildLikedItemsList(),
    );
  }

  Widget _buildEmptyLikedItems() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_border,
              size: 60,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Liked Items Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the heart on products you love!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikedItemsList() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _likedItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final item = _likedItems[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemDetailScreen(productId: item['id']),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                  child: Image.asset(
                        item['image'] ?? 'assets/placeholder.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                  ),
                ),
              ),
                  const SizedBox(height: 12),
                  Text(
                item['name'] ?? 'Unknown Product',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${(item['price'] as num?)?.toStringAsFixed(2) ?? 'N/A'}',
                    style: const TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Colors.amber[600],
                  ),
                      const SizedBox(width: 4),
                      Text(
                        (item['rating'] ?? 0).toString(),
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                icon: Icon(Icons.favorite, color: Colors.red[400]),
                        tooltip: 'Remove from Liked',
                onPressed: () {
                  setState(() {
                    _likedItems.removeAt(index);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Removed from Liked Items')),
                  );
                },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                  ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
