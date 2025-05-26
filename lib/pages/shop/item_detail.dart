import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:pet_smart/pages/cart.dart'; // Import the CartPage
import 'package:pet_smart/components/cart_service.dart';
import 'package:pet_smart/pages/payment.dart'; // Import the PaymentPage
import 'package:supabase_flutter/supabase_flutter.dart';

// Add these color constants at the top of the file
const Color primaryRed = Color(0xFFE57373);    // Light coral red
const Color primaryBlue = Color(0xFF3F51B5);   // PetSmart blue
const Color accentRed = Color(0xFFEF5350);     // Brighter red for emphasis
const Color backgroundColor = Color(0xFFF6F7FB); // Light background

class ItemDetailScreen extends StatefulWidget {
  final String productId;

  const ItemDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  int _current = 0;
  bool _isFavorite = false;
  bool _showReviewInput = false;
  int _rating = 0; // Add this variable for the review rating

  // Mock data for product images
  late List<String> productImages;
  late Map<String, dynamic>? product;
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    fetchProduct();
  }

  Future<void> fetchProduct() async {
    final response = await Supabase.instance.client
        .from('products')
        .select('*, product_images(*)')
        .eq('id', widget.productId)
        .single();
    setState(() {
      product = response;
      // Extract image URLs from product_images
      final images = (product?['product_images'] as List<dynamic>? ?? []);
      productImages = images.isNotEmpty
          ? images.map<String>((img) => img['image_url'] as String).toList()
          : ['assets/placeholder.png']; // fallback image
      isLoading = false;
    });
  }

  // Mock data for reviews
  final List<Map<String, dynamic>> reviews = [
    {
      'name': 'John D.',
      'rating': 5,
      'comment': 'My pet loves this! Great quality and fast delivery.',
      'date': '2 days ago',
      'avatar': 'assets/avatar1.png',
    },
    {
      'name': 'Sarah M.',
      'rating': 4,
      'comment': 'Good product but packaging could be better.',
      'date': '1 week ago',
      'avatar': 'assets/avatar2.png',
    },
  ];

  // Mock data for suggested products
  final List<Map<String, dynamic>> suggestedProducts = [
    {
      'name': 'Premium Dog Food',
      'image': 'assets/food1.png',
      'price': '\$24.99',
      'rating': 4.5,
    },
    {
      'name': 'Cat Treats',
      'image': 'assets/food2.png',
      'price': '\$12.99',
      'rating': 4.8,
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Main content
          CustomScrollView(
            slivers: [
              // App Bar with back button and actions
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                backgroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? primaryRed : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isFavorite = !_isFavorite;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () {},
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      CarouselSlider.builder(
                        itemCount: productImages.length,
                        itemBuilder: (context, index, realIdx) {
                          return AspectRatio(
                            aspectRatio: 16 / 9, // Maintain consistent aspect ratio
                            child: productImages[index].startsWith('http')
                                ? Image.network(
                                    productImages[index],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: Icon(Icons.broken_image, size: 50, color: Colors.grey[600]),
                                      );
                                    },
                                  )
                                : Image.asset(
                                    productImages[index],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: Icon(Icons.broken_image, size: 50, color: Colors.grey[600]),
                                      );
                                    },
                                    cacheWidth: 800,
                                  ),
                          );
                        },
                        options: CarouselOptions(
                          height: 400,
                          viewportFraction: 1.0,
                          autoPlay: true, // Auto-play the carousel
                          autoPlayInterval: const Duration(seconds: 5),
                          autoPlayAnimationDuration: const Duration(milliseconds: 800),
                          autoPlayCurve: Curves.fastOutSlowIn,
                          pauseAutoPlayOnTouch: true,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _current = index;
                            });
                          },
                        ),
                      ),
                      // Image indicator dots with improved visibility
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: productImages.asMap().entries.map((entry) {
                            return Container(
                              width: _current == entry.key ? 24 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.white.withOpacity(
                                  _current == entry.key ? 0.9 : 0.4,
                                ),
                                // Add shadow for better visibility against any background
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      // Add gradient overlay for better text visibility
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 80,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.4),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Product details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product?['title'] ?? product?['name'] ?? 'Product Name',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            product?['price'] != null
                                ? (product!['price'] is num
                                    ? '\$${product!['price'].toStringAsFixed(2)}'
                                    : '\$${product!['price'].toString()}')
                                : 'N/A',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: primaryBlue,  // Changed to blue
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: primaryRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '20% OFF',
                              style: TextStyle(
                                color: primaryRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Rating and reviews
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const Text(
                            '4.8',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(2 Reviews)',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product?['description'] ?? 'No description available.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Add Review Button
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showReviewInput = true;
                          });
                        },
                        icon: const Icon(Icons.rate_review_outlined),
                        label: const Text('Write a Review'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryBlue,
                          elevation: 0,
                          side: BorderSide(color: primaryBlue),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                      // Review Input Form
                      if (_showReviewInput)
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Write Your Review',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: List.generate(
                                  5,
                                  (index) => IconButton(
                                    icon: Icon(
                                      index < _rating
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _rating = index + 1;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText:
                                      'Share your experience with this product...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _showReviewInput = false;
                                        _rating = 0;
                                      });
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: () {
                                      // Handle submit review
                                      setState(() {
                                        _showReviewInput = false;
                                        _rating = 0;
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Review submitted')),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryBlue,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                    ),
                                    child: const Text('Submit Review'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Reviews section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Reviews',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      ...reviews.map((review) => _ReviewCard(review: review)),
                      const SizedBox(height: 24),
                      // Suggested products
                      const Text(
                        'You May Also Like',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 240, // Increased height to prevent overflow
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: suggestedProducts.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            return _SuggestedProductCard(
                              product: suggestedProducts[index],
                            );
                          },
                        ),
                      ),
                      // Bottom padding for sticky buttons
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Sticky bottom buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), // Increased bottom padding
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Add item to cart service
                        CartService().addItem({
                          'id': product?['id'] ?? DateTime.now().toString(), // Temporary ID
                          'name': product?['name'],
                          'image': product?['image'],
                          'price': product?['price'] ?? '\$24.99',
                        });
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Added to cart!'),
                            action: SnackBarAction(
                              label: 'View Cart',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CartPage(showBackButton: true),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: const Text('Add to Cart'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryBlue,
                        side: BorderSide(color: primaryBlue),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to payment page with current product
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentPage(
                              directPurchaseItem: {
                                'id': product?['id'] ?? DateTime.now().toString(),
                                'name': product?['name'],
                                'image': product?['image'],
                                'price': product?['price'] ?? '\$24.99',
                                'quantity': 1,
                              },
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.flash_on_rounded),
                      label: const Text('Buy Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Update the _ReviewCard widget
class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryBlue.withOpacity(0.1),
                ),
                child: Center(
                  child: Text(
                    review['name'][0], // First letter of name
                    style: TextStyle(
                      color: primaryBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < review['rating'] 
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 16,
                            color: index < review['rating'] 
                                ? Colors.amber[700]
                                : Colors.grey[400],
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          review['date'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review['comment'],
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Update the _SuggestedProductCard widget
class _SuggestedProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const _SuggestedProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    // Parse price, handling potential errors
    double priceValue = 0.0;
    if (product['price'] is String) {
      try {
        priceValue = double.parse(
            (product['price'] as String).replaceAll(r'$', ''));
      } catch (e) {
        // Handle parsing error, e.g., log or use a default
        priceValue = 0.0;
      }
    } else if (product['price'] is num) {
      priceValue = (product['price'] as num).toDouble();
    }

    final double ratingValue = (product['rating'] ?? 0.0).toDouble();
    final int soldCountValue = (product['soldCount'] ?? 0); // Default to 0 if not present

    return Container(
      width: 180, // Adjusted width for better layout
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 1, // Added subtle shadow
        shadowColor: Colors.grey.withOpacity(0.2),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Prepare a full product map if needed by ItemDetailScreen
            // For now, passing the existing product map
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ItemDetailScreen(productId: product['id']),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image with improved handling
                AspectRatio(
                  aspectRatio: 16 / 10, // Consistent aspect ratio
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        product['image'],
                        fit: BoxFit.cover,
                        cacheWidth: 300, // Optimize memory usage
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, color: Colors.grey[600]),
                                const SizedBox(height: 4),
                                Text(
                                  'Image not available',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Product Name
                Text(
                  product['name'],
                  style: const TextStyle(
                    fontSize: 15, // Slightly larger
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Product Description (static as per dashboard card)
                Text(
                  'High-quality item for your pet.', // Generic description
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
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
                      ratingValue.toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${soldCountValue}k sold', // Assuming soldCount is in thousands
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Price
                Text(
                  '\$${priceValue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: primaryBlue, // Match dashboard price color
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
