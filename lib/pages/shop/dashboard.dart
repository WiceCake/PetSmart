import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:pet_smart/pages/shop/item_detail.dart';
import 'package:pet_smart/pages/shop/search_results.dart';
import 'package:pet_smart/pages/cart.dart';
import 'package:pet_smart/components/search_service.dart';
import 'package:pet_smart/pages/view_all_products.dart';
import 'package:pet_smart/services/product_service.dart';

// Color constants matching app design patterns
const Color primaryBlue = Color(0xFF233A63);   // Main primary color
const Color secondaryBlue = Color(0xFF3F51B5); // Secondary blue
const Color primaryRed = Color(0xFFE57373);    // Light coral red
const Color accentRed = Color(0xFFEF5350);     // Brighter red for emphasis
const Color backgroundColor = Color(0xFFF6F7FB); // Light background
const Color successGreen = Color(0xFF4CAF50);  // Success green

class DashboardShopScreen extends StatefulWidget {
  const DashboardShopScreen({super.key});

  @override
  State<DashboardShopScreen> createState() => _DashboardShopScreenState();
}

class _DashboardShopScreenState extends State<DashboardShopScreen> {
  final ProductService _productService = ProductService();

  List<Map<String, dynamic>> newArrivals = [];
  List<Map<String, dynamic>> topSellingItems = [];

  bool isLoadingNewArrivals = true;
  bool isLoadingTopSelling = true;
  String? errorMessage;

  final List<String> bannerList = [
    'assets/banner1.png',
    'assets/banner2.png',
    'assets/banner3.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    await Future.wait([
      _loadNewArrivals(),
      _loadTopSelling(),
    ]);
  }

  Future<void> _loadNewArrivals() async {
    try {
      setState(() {
        isLoadingNewArrivals = true;
        errorMessage = null;
      });

      final products = await _productService.getNewArrivals(limit: 2);

      if (!mounted) return;
      setState(() {
        newArrivals = products;
        isLoadingNewArrivals = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingNewArrivals = false;
        errorMessage = 'Failed to load new arrivals. Please try again.';
      });
    }
  }

  Future<void> _loadTopSelling() async {
    try {
      setState(() {
        isLoadingTopSelling = true;
      });

      final products = await _productService.getTopSellingProducts(limit: 2);

      if (!mounted) return;
      setState(() {
        topSellingItems = products;
        isLoadingTopSelling = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingTopSelling = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: primaryBlue,
          child: Builder(
            builder: (context) {
              // Show loading state while both sections are loading
              if (isLoadingNewArrivals && isLoadingTopSelling) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: primaryBlue,
                  ),
                );
              }

              // Show error state if there's an error and no data
              if (errorMessage != null && newArrivals.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[400],
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProducts,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              return _StickySearchScrollView(
                bannerList: bannerList,
                newArrivals: newArrivals,
                topSellingItems: topSellingItems,
                isLoadingNewArrivals: isLoadingNewArrivals,
                isLoadingTopSelling: isLoadingTopSelling,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StickySearchScrollView extends StatefulWidget {
  final List<String> bannerList;
  final List<Map<String, dynamic>> newArrivals;
  final List<Map<String, dynamic>> topSellingItems;
  final bool isLoadingNewArrivals;
  final bool isLoadingTopSelling;

  const _StickySearchScrollView({
    required this.bannerList,
    required this.newArrivals,
    required this.topSellingItems,
    required this.isLoadingNewArrivals,
    required this.isLoadingTopSelling,
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

  // All products section with lazy loading
  final ProductService _productService = ProductService();
  final List<Map<String, dynamic>> _allProducts = [];
  bool _isLoadingAllProducts = false;
  bool _hasMoreProducts = true;
  int _currentPage = 1;
  final int _productsPerPage = 10;

  // Combine all products for search
  List<Map<String, dynamic>> get _searchableProducts => [
    ...widget.newArrivals,
    ...widget.topSellingItems,
    ..._allProducts,
  ];

  void _onSearchChanged(String query) async {
    setState(() {
      if (query.isEmpty) {
        _showSuggestions = false;
        _searchResults = [];
      } else {
        _showSuggestions = true;
      }
    });

    if (query.isNotEmpty) {
      try {
        // Use ProductService for better search results
        final ProductService productService = ProductService();
        final searchResults = await productService.searchProducts(query);

        if (mounted) {
          setState(() {
            _searchResults = searchResults;
          });
        }
      } catch (e) {
        // Fallback to local search if service fails
        if (mounted) {
          setState(() {
            _searchResults = SearchService.searchProducts(query, _searchableProducts);
          });
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    _loadAllProducts(); // Load initial products
  }

  Future<void> _loadAllProducts() async {
    if (_isLoadingAllProducts || !_hasMoreProducts) return;

    try {
      setState(() {
        _isLoadingAllProducts = true;
      });

      final products = await _productService.getAllProducts(
        page: _currentPage,
        limit: _productsPerPage,
      );

      if (!mounted) return;

      setState(() {
        if (products.isEmpty) {
          _hasMoreProducts = false;
        } else {
          _allProducts.addAll(products);
          _currentPage++;
        }
        _isLoadingAllProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingAllProducts = false;
      });
    }
  }

  void _onScroll() {
    final offset = _controller.offset;

    // Handle search bar visibility
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

    // Handle lazy loading for all products
    if (_controller.position.pixels >= _controller.position.maxScrollExtent - 200) {
      _loadAllProducts();
    }
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
                    color: Colors.black.withValues(alpha: 0.1),
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
                              product['title'] ?? product['name'] ?? 'No Title',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(
                              Icons.north_west,
                              size: 16,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              final productName = product['title'] ?? product['name'] ?? '';
                              setState(() {
                                _searchController.text = productName;
                                _showSuggestions = false;
                              });

                              // Navigate to search results with current search results
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SearchResultsScreen(
                                    searchQuery: productName,
                                    searchResults: _searchResults,
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
                      color: primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.new_releases_rounded,
                          color: primaryBlue,
                          size: 20,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "New Arrivals",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: primaryBlue,
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
                      foregroundColor: primaryBlue,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Builder(
                builder: (context) {
                  if (widget.isLoadingNewArrivals) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(
                          color: primaryBlue,
                        ),
                      ),
                    );
                  }
                  if (widget.newArrivals.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'No new arrivals available at the moment',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return _ProductRow(products: widget.newArrivals);
                },
              ),
            ),
            // Top Selling Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.local_fire_department_rounded,
                          color: primaryRed,
                          size: 20,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Top Selling",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: primaryRed,
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
                            products: widget.topSellingItems,
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: primaryRed,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Builder(
                builder: (context) {
                  if (widget.isLoadingTopSelling) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(
                          color: primaryBlue,
                        ),
                      ),
                    );
                  }
                  if (widget.topSellingItems.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'No top selling products available yet',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return _ProductRow(products: widget.topSellingItems);
                },
              ),
            ),

            // All Products Section
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.grid_view_rounded,
                          color: successGreen,
                          size: 20,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "All Products",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: successGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (_allProducts.isNotEmpty)
                    Text(
                      '${_allProducts.length} products',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),

            // All Products Grid with Lazy Loading
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _allProducts.isEmpty && !_isLoadingAllProducts
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'No products available currently',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // Products Grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                          ),
                          itemCount: _allProducts.length,
                          itemBuilder: (context, index) {
                            final product = _allProducts[index];
                            return _ProductCard(
                              id: product['id'] ?? '',
                              image: product['image'] ?? 'assets/placeholder.png',
                              name: product['title'] ?? product['name'] ?? 'Unknown Product',
                              description: product['description'] ?? 'No description available',
                              price: (product['price'] ?? 0.0).toDouble(),
                              rating: (product['rating'] ?? 4.0).toDouble(),
                              soldCount: product['soldCount'] ?? product['total_sold'] ?? 0,
                              badge: product['badge'],
                            );
                          },
                        ),

                        // Loading indicator for lazy loading
                        if (_isLoadingAllProducts)
                          const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(
                              color: primaryBlue,
                            ),
                          ),

                        // End of products indicator
                        if (!_hasMoreProducts && _allProducts.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              'No more products to load',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
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
                color: _current == index ? primaryBlue : primaryBlue.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// Row for 2 products side by side (for New Arrivals and Top Selling)
class _ProductRow extends StatelessWidget {
  final List<Map<String, dynamic>> products;

  const _ProductRow({required this.products});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < products.length && i < 2; i++) ...[
          Expanded(
            child: _ProductCard(
              id: products[i]['id'] ?? '',
              image: products[i]['image'] ?? 'assets/placeholder.png',
              name: products[i]['title'] ?? products[i]['name'] ?? 'Unknown Product',
              description: products[i]['description'] ?? 'No description available',
              price: (products[i]['price'] ?? 0.0).toDouble(),
              rating: (products[i]['rating'] ?? 4.0).toDouble(),
              soldCount: products[i]['soldCount'] ?? products[i]['total_sold'] ?? 0,
              badge: products[i]['badge'],
            ),
          ),
          if (i < products.length - 1 && i < 1) const SizedBox(width: 16),
        ],
        // Fill remaining space if only one product
        if (products.length == 1) const Expanded(child: SizedBox()),
      ],
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product Image
                    AspectRatio(
                      aspectRatio: 16/9,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildProductImage(image),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 1),
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
                    const SizedBox(height: 8),
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

  Widget _buildProductImage(String imageUrl) {
    // Check if it's a network URL or asset path
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                color: primaryBlue,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: Colors.grey[600], size: 32),
                const SizedBox(height: 4),
                Text(
                  'Image not available',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
    } else {
      // Asset image
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: Colors.grey[600], size: 32),
                const SizedBox(height: 4),
                Text(
                  'Image not found',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
    }
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