import 'package:flutter/material.dart';
import 'package:pet_smart/pages/shop/item_detail.dart';

// Add these color constants at the top of the file
const Color primaryRed = Color(0xFFE57373);    // Light coral red
const Color primaryBlue = Color(0xFF3F51B5);   // PetSmart blue
const Color accentRed = Color(0xFFEF5350);     // Brighter red for emphasis
const Color backgroundColor = Color(0xFFF6F7FB); // Light background

class SearchResultsScreen extends StatefulWidget {
  final String searchQuery;
  final List<Map<String, dynamic>> searchResults;

  const SearchResultsScreen({
    super.key,
    required this.searchQuery,
    required this.searchResults,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  String _sortBy = 'Popular'; // Default sort option

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Search Results'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '"${widget.searchQuery}"',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Filter and Sort bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      // Show filter options
                    },
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Filter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryBlue,
                      side: BorderSide(color: primaryBlue),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      _showSortOptions(context);
                    },
                    icon: const Icon(Icons.sort),
                    label: Text('Sort by: $_sortBy'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryBlue,
                      side: BorderSide(color: primaryBlue),
                    ),
                  ),
                ],
              ),
            ),
            // Results count
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.centerLeft,
              child: Text(
                '${widget.searchResults.length} Results Found',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            // Search results grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75, // Adjusted for new card layout
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: widget.searchResults.length,
                itemBuilder: (context, index) {
                  final product = widget.searchResults[index];
                  return _SearchResultCard(product: product);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Sort By',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.trending_up),
                title: const Text('Popular'),
                selected: _sortBy == 'Popular',
                onTap: () => _updateSort('Popular'),
              ),
              ListTile(
                leading: const Icon(Icons.price_check),
                title: const Text('Price: Low to High'),
                selected: _sortBy == 'Price: Low to High',
                onTap: () => _updateSort('Price: Low to High'),
              ),
              ListTile(
                leading: const Icon(Icons.price_check),
                title: const Text('Price: High to Low'),
                selected: _sortBy == 'Price: High to Low',
                onTap: () => _updateSort('Price: High to Low'),
              ),
              ListTile(
                leading: const Icon(Icons.star_border),
                title: const Text('Rating'),
                selected: _sortBy == 'Rating',
                onTap: () => _updateSort('Rating'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateSort(String sortBy) {
    setState(() {
      _sortBy = sortBy;
    });
    Navigator.pop(context);
    // Implement sorting logic here
  }
}

class _SearchResultCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const _SearchResultCard({required this.product});

  @override
  Widget build(BuildContext context) {
    // Extract and provide defaults for product data
    final String imageUrl = product['image'] ?? 'assets/placeholder.png'; // Ensure placeholder asset exists
    final String name = product['name'] ?? 'Unnamed Product';
    final double price = (product['price'] is num)
        ? (product['price'] as num).toDouble()
        : (double.tryParse(product['price'].toString().replaceAll(r'$', '')) ?? 0.0);
    final double rating = (product['rating'] is num)
        ? (product['rating'] as num).toDouble()
        : (double.tryParse(product['rating'].toString()) ?? 0.0);
    final int soldCount = (product['soldCount'] is int)
        ? product['soldCount']
        : (int.tryParse(product['soldCount'].toString()) ?? 0);
    final String? badge = product['badge'] as String?;

    return Semantics(
      button: true,
      label: name,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 1, // Added subtle shadow
        shadowColor: Colors.grey.withOpacity(0.2),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ItemDetailScreen(productId: product['id']),
              ),
            );
          },
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    AspectRatio(
                      aspectRatio: 16/9, // Consistent with dashboard card
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: Icon(Icons.broken_image, color: Colors.grey[600]),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Product Name
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Product Description (placeholder)
                    Text(
                      'Product description goes here', // Or use product['description'] if available
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(), // Pushes content below to the bottom
                    // Rating and Sold Count
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Colors.amber[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${soldCount}k sold', // Assuming soldCount is in thousands or adjust as needed
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Price
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: primaryBlue, // Match dashboard price color
                      ),
                    ),
                  ],
                ),
              ),
              // Badge (optional, can be added if search results include badges)
              if (badge != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getBadgeColor(badge), // Assumes _getBadgeColor is available or defined
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function for badge color, can be moved to a utility class if used elsewhere
  Color _getBadgeColor(String badge) {
    switch (badge.toUpperCase()) {
      case 'NEW':
        return Colors.blue;
      case 'HOT':
        return Colors.orange;
      case 'SALE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}