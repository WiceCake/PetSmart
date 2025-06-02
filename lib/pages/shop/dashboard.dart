import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:pet_smart/pages/shop/item_detail.dart';
import 'package:pet_smart/pages/shop/search_results.dart';
import 'package:pet_smart/pages/cart.dart';
import 'package:pet_smart/components/search_service.dart';
import 'package:pet_smart/pages/shop/new_arrivals_page.dart';
import 'package:pet_smart/pages/shop/top_selling_page.dart';
import 'package:pet_smart/services/product_service.dart';
import 'package:pet_smart/services/search_history_service.dart';
import 'package:pet_smart/utils/currency_formatter.dart';
import 'package:pet_smart/components/optimized_image.dart';

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
        errorMessage = null;
      });

      final products = await _productService.getTopSellingProducts(limit: 2);

      if (!mounted) return;
      setState(() {
        topSellingItems = products;
        isLoadingTopSelling = false;
      });

      // Debug: Print to see if we're getting real data or mock data
      debugPrint('Top Selling Products loaded: ${products.length} items');
      if (products.isNotEmpty) {
        debugPrint('First product: ${products[0]['title']} - Total sold: ${products[0]['total_sold']}');
      }
    } catch (e) {
      debugPrint('Error loading top selling products: $e');
      if (!mounted) return;
      setState(() {
        isLoadingTopSelling = false;
        errorMessage = 'Failed to load top selling products. Please try again.';
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
  bool _isSearching = false;
  Timer? _debounceTimer;
  List<String> _searchHistory = [];
  List<String> _searchSuggestions = [];

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

  void _onSearchChanged(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    setState(() {
      if (query.isEmpty) {
        _showSuggestions = false;
        _searchResults = [];
        _searchSuggestions = [];
        _isSearching = false;
      } else {
        _showSuggestions = true;
        _isSearching = true;
      }
    });

    if (query.isNotEmpty) {
      // Get search suggestions immediately
      _loadSearchSuggestions(query);

      // Debounce search API calls by 500ms
      _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
        await _performSearch(query);
      });
    }
  }

  Future<void> _loadSearchSuggestions(String query) async {
    final suggestions = await SearchHistoryService.getSearchSuggestions(query);
    if (mounted) {
      setState(() {
        _searchSuggestions = suggestions;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    try {
      // Use ProductService for better search results
      final searchResults = await _productService.searchProducts(query);

      if (mounted) {
        setState(() {
          _searchResults = searchResults;
          _isSearching = false;
        });
      }
    } catch (e) {
      // Fallback to local search if service fails
      if (mounted) {
        setState(() {
          _searchResults = SearchService.searchProducts(query, _searchableProducts);
          _isSearching = false;
        });
      }
    }
  }

  void _addToSearchHistory(String query) async {
    if (query.trim().isEmpty) return;

    await SearchHistoryService.addToSearchHistory(query.trim());
    await _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    final history = await SearchHistoryService.getSearchHistory();
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  Future<void> _removeFromSearchHistory(String query) async {
    await SearchHistoryService.removeFromSearchHistory(query);
    await _loadSearchHistory();
  }

  Future<void> _clearSearchHistory() async {
    await SearchHistoryService.clearSearchHistory();
    await _loadSearchHistory();
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    _loadAllProducts(); // Load initial products
    _loadSearchHistory(); // Load search history
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
    _debounceTimer?.cancel();
    _controller.removeListener(_onScroll);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchSuggestions() {
    return AnimatedOpacity(
      opacity: _showSuggestions ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: _showSuggestions
          ? Container(
              margin: const EdgeInsets.only(top: 84),
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recent Searches
                  if (_searchController.text.isEmpty && _searchHistory.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Searches',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _clearSearchHistory();
                            },
                            child: const Text(
                              'Clear',
                              style: TextStyle(
                                color: primaryBlue,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...List.generate(
                      _searchHistory.take(5).length,
                      (index) {
                        final searchTerm = _searchHistory[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.history,
                            color: Colors.grey,
                            size: 20,
                          ),
                          title: Text(
                            searchTerm,
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              final searchTerm = _searchHistory[index];
                              _removeFromSearchHistory(searchTerm);
                            },
                          ),
                          onTap: () {
                            _searchController.text = searchTerm;
                            _onSearchChanged(searchTerm);
                          },
                        );
                      },
                    ),
                  ],

                  // Search Suggestions (when typing)
                  if (_searchController.text.isNotEmpty && _searchSuggestions.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Suggestions',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    ...List.generate(
                      _searchSuggestions.take(3).length,
                      (index) {
                        final suggestion = _searchSuggestions[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.search,
                            color: primaryBlue,
                            size: 20,
                          ),
                          title: Text(
                            suggestion,
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () {
                            _searchController.text = suggestion;
                            _addToSearchHistory(suggestion);
                            _performSearch(suggestion);
                            setState(() {
                              _showSuggestions = false;
                            });

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SearchResultsScreen(
                                  searchQuery: suggestion,
                                  searchResults: _searchResults,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],

                  // Product Results (when searching)
                  if (_searchController.text.isNotEmpty && _searchResults.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          const Text(
                            'Products',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_isSearching)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primaryBlue,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.3,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _searchResults.take(5).length,
                        itemBuilder: (context, index) {
                          final product = _searchResults[index];
                          return ListTile(
                            dense: true,
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: 40,
                                height: 40,
                                color: Colors.grey[200],
                                child: product['product_images'] != null &&
                                       (product['product_images'] as List).isNotEmpty
                                    ? Image.network(
                                        product['product_images'][0]['image_url'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.image, color: Colors.grey),
                                      )
                                    : const Icon(Icons.pets, color: Colors.grey),
                              ),
                            ),
                            title: Text(
                              product['title'] ?? product['name'] ?? 'No Title',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              CurrencyFormatter.formatPeso(product['price']?.toDouble() ?? 0.0),
                              style: const TextStyle(
                                color: primaryBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.north_west,
                              size: 16,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              final productName = product['title'] ?? product['name'] ?? '';
                              _addToSearchHistory(productName);
                              setState(() {
                                _searchController.text = productName;
                                _showSuggestions = false;
                              });

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

                  // Loading state
                  if (_isSearching && _searchController.text.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: primaryBlue,
                        ),
                      ),
                    ),

                  // No Results
                  if (!_isSearching &&
                      _searchResults.isEmpty &&
                      _searchController.text.isNotEmpty &&
                      _searchSuggestions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            color: Colors.grey[400],
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No results found',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try searching for something else',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
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
                          builder: (context) => const NewArrivalsPage(),
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
                          builder: (context) => const TopSellingPage(),
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
        // Enhanced Sticky Search Bar + Top Bar
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          top: _showSearchBar ? 0 : -90,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
              child: Row(
                children: [
                  // Back Button with better styling
                  Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: primaryBlue,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).maybePop(),
                      tooltip: 'Back',
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Enhanced Search Bar
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _showSuggestions
                              ? primaryBlue.withValues(alpha: 0.3)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        onTap: () {
                          setState(() {
                            _showSuggestions = true;
                          });
                        },
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search for food, toys, accessories...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: Container(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.search_rounded,
                              color: _showSuggestions ? primaryBlue : Colors.grey[600],
                              size: 22,
                            ),
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(4),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.clear_rounded,
                                      color: Colors.grey[600],
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _showSuggestions = false;
                                        _searchResults = [];
                                        _searchSuggestions = [];
                                        _isSearching = false;
                                      });
                                    },
                                    tooltip: 'Clear search',
                                  ),
                                )
                              : _isSearching
                                  ? Container(
                                      padding: const EdgeInsets.all(12),
                                      child: const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: primaryBlue,
                                        ),
                                      ),
                                    )
                                  : null,
                          filled: true,
                          fillColor: Colors.transparent,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Cart Button with better styling
                  Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                        color: primaryBlue,
                        size: 22,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CartPage(showBackButton: true),
                          ),
                        );
                      },
                      tooltip: 'Shopping Cart',
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
                          '$soldCount sold',
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
                      CurrencyFormatter.formatPeso(price),
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
    return OptimizedImage.product(
      imageUrl: imageUrl,
      borderRadius: BorderRadius.circular(8),
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