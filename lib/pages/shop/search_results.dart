import 'dart:async';
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
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _filteredResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _sortBy = 'Popular';

  // Helper method to get short sort label for button
  String get _shortSortLabel {
    switch (_sortBy) {
      case 'Price: Low to High':
        return 'Price ↑';
      case 'Price: High to Low':
        return 'Price ↓';
      case 'Rating':
        return 'Rating';
      case 'Popular':
      default:
        return 'Popular';
    }
  }

  // Check if any filters are active
  bool get _hasActiveFilters {
    return _selectedCategory != 'All' ||
           _minPrice > 0 ||
           _maxPrice < 1000 ||
           _minRating > 0;
  }

  // Count active filters
  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedCategory != 'All') count++;
    if (_minPrice > 0 || _maxPrice < 1000) count++;
    if (_minRating > 0) count++;
    return count;
  }

  // Filter options
  double _minPrice = 0;
  double _maxPrice = 1000;
  double _minRating = 0;
  String? _selectedCategory;
  final List<String> _categories = ['All', 'Food', 'Toys', 'Accessories', 'Health', 'Grooming'];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
    _searchResults = List.from(widget.searchResults);
    _filteredResults = List.from(_searchResults);
    _selectedCategory = 'All';
    _applyFiltersAndSort();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = List.from(widget.searchResults);
        _filteredResults = List.from(_searchResults);
        _isLoading = false;
        _errorMessage = null;
      });
      _applyFiltersAndSort();
      return;
    }

    // Debounce search API calls by 500ms
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      await _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final results = await _productService.searchProducts(query.trim());

      if (!mounted) return;

      setState(() {
        _searchResults = results;
        _filteredResults = List.from(results);
        _isLoading = false;
      });

      _applyFiltersAndSort();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to search products. Please try again.';
      });
    }
  }

  void _applyFiltersAndSort() {
    List<Map<String, dynamic>> filtered = List.from(_searchResults);

    // Apply category filter
    if (_selectedCategory != null && _selectedCategory != 'All') {
      filtered = filtered.where((product) {
        final category = product['category']?.toString().toLowerCase() ?? '';
        return category.contains(_selectedCategory!.toLowerCase());
      }).toList();
    }

    // Apply price filter
    filtered = filtered.where((product) {
      final price = (product['price'] is num)
          ? (product['price'] as num).toDouble()
          : 0.0;
      return price >= _minPrice && price <= _maxPrice;
    }).toList();

    // Apply rating filter
    filtered = filtered.where((product) {
      final rating = (product['rating'] is num)
          ? (product['rating'] as num).toDouble()
          : 0.0;
      return rating >= _minRating;
    }).toList();

    // Apply sorting
    switch (_sortBy) {
      case 'Price: Low to High':
        filtered.sort((a, b) {
          final priceA = (a['price'] is num) ? (a['price'] as num).toDouble() : 0.0;
          final priceB = (b['price'] is num) ? (b['price'] as num).toDouble() : 0.0;
          return priceA.compareTo(priceB);
        });
        break;
      case 'Price: High to Low':
        filtered.sort((a, b) {
          final priceA = (a['price'] is num) ? (a['price'] as num).toDouble() : 0.0;
          final priceB = (b['price'] is num) ? (b['price'] as num).toDouble() : 0.0;
          return priceB.compareTo(priceA);
        });
        break;
      case 'Rating':
        filtered.sort((a, b) {
          final ratingA = (a['rating'] is num) ? (a['rating'] as num).toDouble() : 0.0;
          final ratingB = (b['rating'] is num) ? (b['rating'] as num).toDouble() : 0.0;
          return ratingB.compareTo(ratingA);
        });
        break;
      case 'Popular':
      default:
        filtered.sort((a, b) {
          final soldA = (a['total_sold'] is num) ? (a['total_sold'] as num).toInt() : 0;
          final soldB = (b['total_sold'] is num) ? (b['total_sold'] as num).toInt() : 0;
          return soldB.compareTo(soldA);
        });
        break;
    }

    setState(() {
      _filteredResults = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        leading: Container(
          margin: const EdgeInsets.all(8),
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
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back',
          ),
        ),
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: primaryBlue.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            onSubmitted: _performSearch,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Search products...',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
              prefixIcon: Container(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.search_rounded,
                  color: primaryBlue,
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
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        tooltip: 'Clear search',
                      ),
                    )
                  : _isLoading
                      ? Container(
                          padding: const EdgeInsets.all(10),
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
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
            ),
          ),
        ),
        titleSpacing: 8,
      ),
      body: Column(
        children: [
          // Enhanced Filter and Sort bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Filter Button with enhanced styling
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _hasActiveFilters ? primaryRed : primaryBlue.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      color: _hasActiveFilters
                          ? primaryRed.withValues(alpha: 0.1)
                          : primaryBlue.withValues(alpha: 0.05),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showFilterDialog(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    size: 20,
                                    color: _hasActiveFilters ? primaryRed : primaryBlue,
                                  ),
                                  if (_hasActiveFilters)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: primaryRed,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _hasActiveFilters
                                      ? 'Filter (${_getActiveFilterCount()})'
                                      : 'Filter',
                                  style: TextStyle(
                                    color: _hasActiveFilters ? primaryRed : primaryBlue,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Sort Button with enhanced styling
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryBlue.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      color: primaryBlue.withValues(alpha: 0.05),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showSortOptions(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.sort_rounded,
                                size: 20,
                                color: primaryBlue,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _shortSortLabel,
                                  style: const TextStyle(
                                    color: primaryBlue,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Enhanced Results count and status
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                if (_isLoading) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Searching...',
                    style: TextStyle(
                      color: primaryBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else if (_errorMessage != null) ...[
                  Icon(
                    Icons.error_outline,
                    color: Colors.red[600],
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.search_rounded,
                    color: Colors.grey[600],
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_filteredResults.length} result${_filteredResults.length != 1 ? 's' : ''} found',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_searchResults.length != _filteredResults.length) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(${_searchResults.length} total)',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
                const Spacer(),
                if (!_isLoading && _filteredResults.isNotEmpty)
                  Text(
                    'for "${widget.searchQuery}"',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Search results grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: primaryBlue,
                    ),
                  )
                : _filteredResults.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _searchResults.isEmpty
                                      ? Icons.search_off_rounded
                                      : Icons.filter_list_off_rounded,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                _searchResults.isEmpty
                                    ? 'No products found'
                                    : 'No results match your filters',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchResults.isEmpty
                                    ? 'Try searching with different keywords or check your spelling'
                                    : 'Try adjusting your filters or search terms',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[500],
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_hasActiveFilters) ...[
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _minPrice = 0;
                                      _maxPrice = 1000;
                                      _minRating = 0;
                                      _selectedCategory = 'All';
                                    });
                                    _applyFiltersAndSort();
                                  },
                                  icon: const Icon(Icons.clear_all_rounded),
                                  label: const Text('Clear All Filters'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        itemCount: _filteredResults.length,
                        itemBuilder: (context, index) {
                          final product = _filteredResults[index];
                          return _SearchResultCard(product: product);
                        },
                      ),
          ),
        ],
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
                leading: const Icon(Icons.arrow_upward),
                title: const Text('Price: Low to High'),
                selected: _sortBy == 'Price: Low to High',
                onTap: () => _updateSort('Price: Low to High'),
              ),
              ListTile(
                leading: const Icon(Icons.arrow_downward),
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
    _applyFiltersAndSort();
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Products',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _minPrice = 0;
                            _maxPrice = 1000;
                            _minRating = 0;
                            _selectedCategory = 'All';
                          });
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Category Filter
                  const Text(
                    'Category',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _categories.map((category) {
                      return FilterChip(
                        label: Text(category),
                        selected: _selectedCategory == category,
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedCategory = selected ? category : 'All';
                          });
                        },
                        selectedColor: primaryBlue.withValues(alpha: 0.2),
                        checkmarkColor: primaryBlue,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Price Range Filter
                  const Text(
                    'Price Range',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: RangeValues(_minPrice, _maxPrice),
                    min: 0,
                    max: 1000,
                    divisions: 20,
                    labels: RangeLabels(
                      CurrencyFormatter.formatPeso(_minPrice.round()),
                      CurrencyFormatter.formatPeso(_maxPrice.round()),
                    ),
                    onChanged: (values) {
                      setModalState(() {
                        _minPrice = values.start;
                        _maxPrice = values.end;
                      });
                    },
                    activeColor: primaryBlue,
                  ),
                  Text(
                    '${CurrencyFormatter.formatPeso(_minPrice.round())} - ${CurrencyFormatter.formatPeso(_maxPrice.round())}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),

                  // Rating Filter
                  const Text(
                    'Minimum Rating',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _minRating,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    label: '${_minRating.toStringAsFixed(1)} stars',
                    onChanged: (value) {
                      setModalState(() {
                        _minRating = value;
                      });
                    },
                    activeColor: primaryBlue,
                  ),
                  Text(
                    '${_minRating.toStringAsFixed(1)} stars and above',
                    style: TextStyle(color: Colors.grey[600]),
                  ),

                  const Spacer(),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _applyFiltersAndSort();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const _SearchResultCard({required this.product});

  @override
  Widget build(BuildContext context) {
    // Extract and provide defaults for product data
    final String imageUrl = product['image'] ?? 'assets/placeholder.png';
    final String name = product['title'] ?? product['name'] ?? 'Unnamed Product';
    final double price = (product['price'] is num)
        ? (product['price'] as num).toDouble()
        : (double.tryParse(product['price'].toString().replaceAll(r'$', '')) ?? 0.0);
    final double rating = (product['rating'] is num)
        ? (product['rating'] as num).toDouble()
        : (double.tryParse(product['rating'].toString()) ?? 4.0);
    final int soldCount = (product['total_sold'] is int)
        ? product['total_sold']
        : (product['soldCount'] is int)
            ? product['soldCount']
            : (int.tryParse(product['total_sold']?.toString() ?? '0') ?? 0);
    final String? badge = product['badge'] as String?;

    return Semantics(
      button: true,
      label: name,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 1, // Added subtle shadow
        shadowColor: Colors.grey.withValues(alpha: 0.2),
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
                          child: _buildProductImage(imageUrl),
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
                      product['description'] ?? 'No description available',
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
                          soldCount > 1000 ? '${(soldCount / 1000).toStringAsFixed(1)}k sold' : '$soldCount sold',
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

  // Build product image widget that handles both network and asset images
  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      // Network image
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