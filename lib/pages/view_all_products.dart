import 'package:flutter/material.dart';
import 'package:pet_smart/pages/shop/item_detail.dart';
import 'package:pet_smart/services/product_service.dart';
import 'package:pet_smart/utils/currency_formatter.dart';

// Color constants matching app design patterns
const Color primaryBlue = Color(0xFF233A63);   // Main primary color
const Color secondaryBlue = Color(0xFF3F51B5); // Secondary blue
const Color primaryRed = Color(0xFFE57373);    // Light coral red
const Color accentRed = Color(0xFFEF5350);     // Brighter red for emphasis
const Color backgroundColor = Color(0xFFF6F7FB); // Light background
const Color successGreen = Color(0xFF4CAF50);  // Success green

class ViewAllProductsPage extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> products;

  const ViewAllProductsPage({
    super.key,
    required this.title,
    required this.products,
  });

  @override
  State<ViewAllProductsPage> createState() => _ViewAllProductsPageState();
}

class _ViewAllProductsPageState extends State<ViewAllProductsPage> {
  final ProductService _productService = ProductService();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _allProducts = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  String? _errorMessage;
  String _sortBy = 'created_at';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _allProducts = List.from(widget.products);
    _scrollController.addListener(_onScroll);

    // Load more products if we have a small initial set
    if (_allProducts.length < 20) {
      _loadMoreProducts();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoading || !_hasMoreData) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final newProducts = await _productService.getAllProducts(
        page: _currentPage + 1,
        limit: 20,
        sortBy: _sortBy,
        ascending: _sortAscending,
      );

      if (!mounted) return;

      setState(() {
        if (newProducts.isEmpty) {
          _hasMoreData = false;
        } else {
          _allProducts.addAll(newProducts);
          _currentPage++;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load more products';
      });
    }
  }

  Future<void> _refreshProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1;
        _hasMoreData = true;
      });

      final products = await _productService.getAllProducts(
        page: 1,
        limit: 20,
        sortBy: _sortBy,
        ascending: _sortAscending,
      );

      if (!mounted) return;

      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to refresh products';
      });
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort Products',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _SortOption(
              title: 'Newest First',
              isSelected: _sortBy == 'created_at' && !_sortAscending,
              onTap: () {
                setState(() {
                  _sortBy = 'created_at';
                  _sortAscending = false;
                });
                Navigator.pop(context);
                _refreshProducts();
              },
            ),
            _SortOption(
              title: 'Oldest First',
              isSelected: _sortBy == 'created_at' && _sortAscending,
              onTap: () {
                setState(() {
                  _sortBy = 'created_at';
                  _sortAscending = true;
                });
                Navigator.pop(context);
                _refreshProducts();
              },
            ),
            _SortOption(
              title: 'Price: Low to High',
              isSelected: _sortBy == 'price' && _sortAscending,
              onTap: () {
                setState(() {
                  _sortBy = 'price';
                  _sortAscending = true;
                });
                Navigator.pop(context);
                _refreshProducts();
              },
            ),
            _SortOption(
              title: 'Price: High to Low',
              isSelected: _sortBy == 'price' && !_sortAscending,
              onTap: () {
                setState(() {
                  _sortBy = 'price';
                  _sortAscending = false;
                });
                Navigator.pop(context);
                _refreshProducts();
              },
            ),
            _SortOption(
              title: 'Name: A to Z',
              isSelected: _sortBy == 'name' && _sortAscending,
              onTap: () {
                setState(() {
                  _sortBy = 'name';
                  _sortAscending = true;
                });
                Navigator.pop(context);
                _refreshProducts();
              },
            ),
            _SortOption(
              title: 'Name: Z to A',
              isSelected: _sortBy == 'name' && !_sortAscending,
              onTap: () {
                setState(() {
                  _sortBy = 'name';
                  _sortAscending = false;
                });
                Navigator.pop(context);
                _refreshProducts();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort, color: primaryBlue),
            onPressed: _showSortOptions,
            tooltip: 'Sort products',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        color: primaryBlue,
        child: _allProducts.isEmpty && !_isLoading
            ? const Center(
                child: Text(
                  'No products available',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              )
            : CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = _allProducts[index];
                          return _ProductCard(product: product);
                        },
                        childCount: _allProducts.length,
                      ),
                    ),
                  ),
                  if (_isLoading)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(
                            color: primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  if (_errorMessage != null)
                    SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _loadMoreProducts,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (!_hasMoreData && _allProducts.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            'No more products to load',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
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
}

class _SortOption extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortOption({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? primaryBlue : Colors.black87,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: primaryBlue)
          : null,
      onTap: onTap,
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: Colors.grey.withValues(alpha: 0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailScreen(
                productId: product['id']?.toString() ?? '',
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[100],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      product['image'] ?? 'assets/placeholder.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                            size: 40,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Product Name
              Expanded(
                flex: 1,
                child: Text(
                  product['name'] ?? 'Unknown Product',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              // Price and Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    CurrencyFormatter.formatPeso(product['price'] ?? 0.0),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryBlue,
                    ),
                  ),
                  if (product['rating'] != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          product['rating'].toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}