import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:pet_smart/pages/shop/item_detail.dart';
import 'package:pet_smart/pages/shop/search_results.dart';
import 'package:pet_smart/pages/cart.dart'; // <-- Import the cart page
import 'package:pet_smart/components/search_service.dart'; // <-- Ensure this import is present and the local one is removed
import 'package:pet_smart/pages/view_all_products.dart'; // <-- Import the new ViewAllProductsPage
import 'package:supabase_flutter/supabase_flutter.dart';

// Add these color constants at the top of the file
const Color primaryRed = Color(0xFFE57373);    // Light coral red
const Color primaryBlue = Color(0xFF3F51B5);   // PetSmart blue
const Color accentRed = Color(0xFFEF5350);     // Brighter red for emphasis
const Color backgroundColor = Color(0xFFF6F7FB); // Light background

class DashboardShopScreen extends StatelessWidget {
  DashboardShopScreen({super.key});

  final List<Map<String, dynamic>> newArrivals = [
    {
      'image': 'assets/new1.png',
      'name': 'Tuna Delight',
      'badge': 'NEW',
      'rating': 4.8,
      'soldCount': 120,
      'price': 24.99,
    },
    {
      'image': 'assets/new2.png',
      'name': 'Chicken Feast',
      'badge': 'HOT',
      'rating': 4.5,
      'soldCount': 350,
      'price': 29.99,
    },
    {
      'image': 'assets/new3.png',
      'name': 'Salmon Bites',
      'badge': null,
      'rating': 4.2,
      'soldCount': 89,
      'price': 19.99,
    },
    {
      'image': 'assets/new4.png',
      'name': 'Beef & Veggies',
      'badge': 'SALE',
      'rating': 4.7,
      'soldCount': 230,
      'price': 22.99,
    },
  ];

  final List<Map<String, dynamic>> topSelling = [
    {
      'image': 'assets/food1.png',
      'name': 'Chicken & Green Pea Recipe',
      'badge': 'HOT',
      'rating': 4.9,
      'soldCount': 520,
      'price': 34.99,
    },
    {
      'image': 'assets/food2.png',
      'name': 'Whitefish & Potato',
      'badge': '25% OFF',
      'rating': 4.3,        // Added default rating
      'soldCount': 150,     // Added default sold count
      'price': 32.50,       // Added default price
    },
    {
      'image': 'assets/food3.png',
      'name': 'Salmon & Rice',
      'badge': null,
      'rating': 4.6,        // Added default rating
      'soldCount': 280,     // Added default sold count
      'price': 30.99,       // Added default price
    },
    {
      'image': 'assets/food4.png',
      'name': 'Turkey & Sweet Potato',
      'badge': null,
      'rating': 4.7,        // Added default rating
      'soldCount': 190,     // Added default sold count
      'price': 33.00,       // Added default price
    },
  ];

  final List<String> bannerList = [
    'assets/banner1.png',
    'assets/banner2.png',
    'assets/banner3.png',
  ];

  Future<List<Map<String, dynamic>>> fetchNewArrivals() async {
    final response = await Supabase.instance.client
        .from('products')
        .select('*, product_images(*)')
        .order('created_at', ascending: false)
        .limit(10);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchNewArrivals(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No products found.'));
            }
            // Use your existing _StickySearchScrollView, but pass the fetched data
            return _StickySearchScrollView(
              bannerList: bannerList,
              newArrivals: snapshot.data!,
              topSelling: topSelling, // You can fetch this similarly
            );
          },
        ),
      ),
    );
  }
}

class _StickySearchScrollView extends StatefulWidget {
  final List<String> bannerList;
  final List<Map<String, dynamic>> newArrivals;
  final List<Map<String, dynamic>> topSelling;

  const _StickySearchScrollView({
    required this.bannerList,
    required this.newArrivals,
    required this.topSelling,
  });

  @override
  State<_StickySearchScrollView> createState() => _StickySearchScrollViewState();
}

class _StickySearchScrollViewState extends State<_StickySearchScrollView> {
  bool _showSearchBar = true;
  double _lastOffset = 0;

  final ScrollController _controller = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _showSuggestions = false;
  List<Map<String, dynamic>> _searchResults = [];

  // Combine all products for search
  List<Map<String, dynamic>> get _allProducts => [
    ...widget.newArrivals,
    ...widget.topSelling,
  ];

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _showSuggestions = false;
        _searchResults = [];
      } else {
        _showSuggestions = true;
        _searchResults = SearchService.searchProducts(query, _allProducts); // Uses the imported SearchService
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _controller.offset;
    if (offset <= 0) {
      if (!_showSearchBar) setState(() => _showSearchBar = true);
      _lastOffset = offset;
      return;
    }
    if (offset > _lastOffset && _showSearchBar) {
      // scrolling down
      setState(() => _showSearchBar = false);
    } else if (offset < _lastOffset && !_showSearchBar) {
      // scrolling up
      setState(() => _showSearchBar = true);
    }
    _lastOffset = offset;
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchSuggestions() {
    return AnimatedOpacity(
      opacity: _showSuggestions ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: _showSuggestions
          ? Container(
              margin: const EdgeInsets.only(top: 80),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recent Searches
                  if (_searchController.text.isEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Recent Searches',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Add your recent searches list here
                  ],

                  // Search Suggestions
                  if (_searchController.text.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Popular Searches',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final product = _searchResults[index];
                          return ListTile(
                            leading: const Icon(Icons.search_outlined),
                            title: Text(
                              product['title'] ?? 'No Title',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(
                              Icons.north_west,
                              size: 16,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              setState(() {
                                _searchController.text = product['title'] ?? '';
                                _showSuggestions = false;
                              });
                              
                              // Get all related products
                              final relatedProducts = SearchService.searchProducts(
                                product['title']?.split(' ')[0] ?? '', // Search by first word
                                _allProducts,
                              );
                              
                              // Navigate to search results
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SearchResultsScreen(
                                    searchQuery: product['title'] ?? '',
                                    searchResults: relatedProducts,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],

                  // No Results
                  if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No results found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          controller: _controller,
          padding: EdgeInsets.zero,
          children: [
            // Sticky bar spacer
            const SizedBox(height: 84),

            // --- Add your logo here ---
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Center(
                child: Image.asset(
                  'assets/petsmart_word.png', // <-- Change to your logo asset path
                  height: 48,
                  fit: BoxFit.contain,
                  semanticLabel: 'PetSmart Logo',
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 48,
                      color: Colors.grey[300],
                      child: Icon(Icons.broken_image, color: Colors.grey[600]),
                    );
                  },
                ),
              ),
            ),
            // --- End logo ---

            // Banner Carousel (full width, bigger, with indicator)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _BannerCarousel(bannerList: widget.bannerList),
            ),
            // New Arrivals Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.new_releases_rounded,
                          color: Colors.teal,
                          size: 20,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "New Arrivals",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewAllProductsPage(
                            title: "New Arrivals",
                            products: widget.newArrivals,
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.teal,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ProductGrid(products: widget.newArrivals),
            ),
            // Top Selling Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.deepOrange,
                          size: 20,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Top Selling",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewAllProductsPage(
                            title: "Top Selling",
                            products: widget.topSelling,
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.deepOrange,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ProductGrid(products: widget.topSelling),
            ),
            const SizedBox(height: 32),
          ],
        ),
        // Sticky Search Bar + Top Bar
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          top: _showSearchBar ? 0 : -90,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              color: const Color(0xFFF6F7FB),
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  Tooltip(
                    message: 'Back',
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  Expanded(
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(24),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search for food, toys, etc...',
                          prefixIcon: const Icon(Icons.search, color: primaryBlue),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _showSuggestions = false;
                                      _searchResults = [];
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'Cart',
                    child: IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
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
                ],
              ),
            ),
          ),
        ),
        // Search Suggestions
        _buildSearchSuggestions(),
      ],
    );
  }
}

// Carousel with indicator dots
class _BannerCarousel extends StatefulWidget {
  final List<String> bannerList;
  const _BannerCarousel({required this.bannerList});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: widget.bannerList.length,
          itemBuilder: (context, index, realIdx) {
            return Container(
              width: width,
              margin: EdgeInsets.zero,
              child: Image.asset(
                widget.bannerList[index],
                fit: BoxFit.cover,
                width: width,
                height: 210,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: width,
                    height: 210,
                    color: Colors.grey[300],
                    child: Icon(Icons.broken_image, size: 50, color: Colors.grey[600]),
                  );
                },
                semanticLabel: 'Banner ${index + 1}',
              ),
            );
          },
          options: CarouselOptions(
            height: 210,
            enlargeCenterPage: false,
            viewportFraction: 1.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            enableInfiniteScroll: true,
            onPageChanged: (index, reason) {
              setState(() {
                _current = index;
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.bannerList.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _current == index ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _current == index ? primaryBlue : primaryBlue.withOpacity(0.3),  // Changed from teal
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// Grid for 2 cards per row, with improved card design
class _ProductGrid extends StatelessWidget {
  final List<Map<String, dynamic>> products;

  const _ProductGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75, // Adjusted for new card layout
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        final images = product['product_images'] as List<dynamic>? ?? [];
        final thumbnail = images.isNotEmpty
            ? images.firstWhere((img) => img['is_thumbnail'] == true, orElse: () => images.first)
            : null;
        final imageUrl = thumbnail != null ? thumbnail['image_url'] as String? ?? '' : '';

        final name = product['title'] ?? 'No Name';
        final description = product['description'] ?? 'No Description';
        final badge = product['badge'] as String?;
        final price = product['price'] as num? ?? 0.0;
        final rating = product['rating'] as num? ?? 0.0;
        final soldCount = product['soldCount'] as int? ?? 0;
        final id = product['id'] as String? ?? '';

        return _ProductCard(
          id: id,
          image: imageUrl.isNotEmpty ? imageUrl : 'assets/placeholder.png',
          name: name,
          description: description,
          badge: badge,
          price: price.toDouble(),
          rating: rating.toDouble(),
          soldCount: soldCount,
        );
      },
    );
  }
}

// Improved product card with shadow, rounded corners, and badge
class _ProductCard extends StatelessWidget {
  final String id;
  final String image;
  final String name;
  final String description;
  final String? badge;
  final double price;
  final double rating;
  final int soldCount;

  const _ProductCard({
    required this.id,
    required this.image,
    required this.name,
    required this.description,
    this.badge,
    this.price = 24.99,
    this.rating = 4.5,
    this.soldCount = 250,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: name,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ItemDetailScreen(productId: id),
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
                      aspectRatio: 16/9,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.network(
                          image,
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
                    // Product Description
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
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
                          rating.toString(),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${soldCount}k sold',
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
                      ),
                    ),
                  ],
                ),
              ),
              // Badge
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
                      color: _getBadgeColor(badge!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge!,
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

// Removed local SearchService definition as it's now imported

// This function fetches products with their images
Future<List<Map<String, dynamic>>> fetchNewArrivals() async {
  final response = await Supabase.instance.client
      .from('products')
      .select('*, product_images(*)')
      .order('created_at', ascending: false)
      .limit(10);
  return List<Map<String, dynamic>>.from(response);
}