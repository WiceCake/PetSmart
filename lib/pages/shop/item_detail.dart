import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:pet_smart/components/cart_service.dart';
import 'package:pet_smart/pages/payment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_smart/utils/currency_formatter.dart';
import 'package:pet_smart/services/review_service.dart';
import 'package:pet_smart/components/discount_badge.dart';
import 'package:pet_smart/services/liked_products_service.dart';
import 'package:pet_smart/pages/shop/all_reviews.dart';
import 'package:pet_smart/components/enhanced_toasts.dart';

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

class _ItemDetailScreenState extends State<ItemDetailScreen> with WidgetsBindingObserver, RouteAware {
  int _current = 0;
  bool _isFavorite = false;
  bool _showReviewInput = false;
  int _rating = 0; // Add this variable for the review rating
  int _selectedQuantity = 1; // Add quantity selection
  bool _isAddingToCart = false; // Add loading state for cart operations
  bool _isLikeLoading = false; // Add loading state for like operations
  bool _likeStateChanged = false; // Track if like state has changed

  // Product data
  List<String> productImages = [];
  Map<String, dynamic>? product;
  bool isLoading = true;

  // Review data
  List<Map<String, dynamic>> reviews = [];
  bool isLoadingReviews = false;
  double averageRating = 0.0;
  int totalReviews = 0;
  bool hasUserReviewed = false;
  final TextEditingController _reviewController = TextEditingController();

  // Services
  final LikedProductsService _likedProductsService = LikedProductsService();

  // Related products
  List<Map<String, dynamic>> relatedProducts = [];
  bool isLoadingRelatedProducts = false;

  // Route observer for detecting when page becomes visible
  static final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchProduct();
    // Note: fetchReviews() and _checkLikeStatus() are called after fetchProduct() completes
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _reviewController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh reviews when app comes back to foreground
      // This helps catch reviews added from other sessions
      if (product != null) {
        debugPrint('ItemDetail: App resumed, refreshing reviews');
        fetchReviews();
      }
    }
  }

  // RouteAware methods
  @override
  void didPopNext() {
    // Called when the top route has been popped off, and this route shows up.
    _onPageResumed();
  }

  @override
  void didPushNext() {
    // Called when a new route has been pushed, and this route is no longer visible.
  }

  /// Called when the page becomes visible again (e.g., when returning from another page)
  void _onPageResumed() {
    if (product != null) {
      debugPrint('ItemDetail: Page resumed, refreshing reviews');
      fetchReviews();
    }
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

    // Check like status, fetch reviews, and fetch related products after product is loaded
    _checkLikeStatus();
    fetchReviews();
    fetchRelatedProducts();
  }



  Future<void> fetchReviews() async {
    if (product == null) return;

    setState(() {
      isLoadingReviews = true;
    });

    try {
      final reviewService = ReviewService();

      debugPrint('ItemDetail: Starting to fetch reviews for product ${widget.productId}');

      // Fetch reviews
      final fetchedReviews = await reviewService.getProductReviews(widget.productId);
      debugPrint('ItemDetail: Raw reviews fetched: ${fetchedReviews.length}');

      final formattedReviews = fetchedReviews.map((review) =>
        ReviewService.formatReviewForDisplay(review)).toList();
      debugPrint('ItemDetail: Formatted reviews: ${formattedReviews.length}');

      // Fetch rating info
      final ratingInfo = await reviewService.getProductRating(widget.productId);
      debugPrint('ItemDetail: Rating info: $ratingInfo');

      // Check if user has reviewed
      final userReviewed = await reviewService.hasUserReviewed(widget.productId);
      debugPrint('ItemDetail: User has reviewed: $userReviewed');

      if (mounted) {
        setState(() {
          reviews = formattedReviews;
          averageRating = ratingInfo['average_rating'];
          totalReviews = ratingInfo['total_reviews'];
          hasUserReviewed = userReviewed;
          isLoadingReviews = false;
        });
        debugPrint('ItemDetail: State updated with ${reviews.length} reviews');
      }
    } catch (e) {
      debugPrint('ItemDetail: Error fetching reviews: $e');
      if (mounted) {
        setState(() {
          reviews = [];
          averageRating = 0.0;
          totalReviews = 0;
          hasUserReviewed = false;
          isLoadingReviews = false;
        });
      }
    }
  }

  /// Refresh reviews - can be called when returning to the page
  Future<void> refreshReviews() async {
    debugPrint('ItemDetail: Refreshing reviews...');
    await fetchReviews();
  }

  Future<void> fetchRelatedProducts() async {
    if (product == null) return;

    setState(() {
      isLoadingRelatedProducts = true;
    });

    try {
      final currentPrice = (product!['price'] is num)
          ? (product!['price'] as num).toDouble()
          : double.tryParse(product!['price'].toString()) ?? 0.0;

      // Calculate price range (±20% of current product price)
      final minPrice = currentPrice * 0.8;
      final maxPrice = currentPrice * 1.2;

      // Note: Could implement keyword-based similarity matching in the future

      // Build query to find related products
      var query = Supabase.instance.client
          .from('products')
          .select('*, product_images(*)')
          .neq('id', widget.productId) // Exclude current product
          .gte('price', minPrice)
          .lte('price', maxPrice)
          .limit(6);

      final response = await query;
      List<Map<String, dynamic>> products = List<Map<String, dynamic>>.from(response);

      // If we don't have enough products in price range, get more products
      if (products.length < 4) {
        final additionalQuery = await Supabase.instance.client
            .from('products')
            .select('*, product_images(*)')
            .neq('id', widget.productId)
            .order('created_at', ascending: false)
            .limit(6);

        final additionalProducts = List<Map<String, dynamic>>.from(additionalQuery);

        // Merge and deduplicate
        final existingIds = products.map((p) => p['id']).toSet();
        for (var product in additionalProducts) {
          if (!existingIds.contains(product['id']) && products.length < 6) {
            products.add(product);
          }
        }
      }

      // Process product images and calculate ratings
      for (var product in products) {
        // Process images
        final images = (product['product_images'] as List<dynamic>? ?? []);
        if (images.isNotEmpty) {
          product['image_urls'] = images.map<String>((img) => img['image_url'] as String).toList();
          product['image'] = product['image_urls'][0];
        } else {
          product['image_urls'] = ['assets/placeholder.png'];
          product['image'] = 'assets/placeholder.png';
        }

        // Calculate sales data
        try {
          final salesResponse = await Supabase.instance.client
              .from('order_items')
              .select('''
                quantity,
                order:order_id!inner (
                  status
                )
              ''')
              .eq('product_id', product['id'])
              .eq('order.status', 'Completed');

          int totalSold = 0;
          for (var item in salesResponse) {
            totalSold += (item['quantity'] as int? ?? 0);
          }
          product['total_sold'] = totalSold;
        } catch (e) {
          product['total_sold'] = 0;
        }

        // Calculate average rating
        try {
          final reviewsResponse = await Supabase.instance.client
              .from('reviews')
              .select('rating')
              .eq('product_id', product['id']);

          if (reviewsResponse.isNotEmpty) {
            final ratings = reviewsResponse.map((r) => (r['rating'] as num).toDouble()).toList();
            product['rating'] = ratings.reduce((a, b) => a + b) / ratings.length;
          } else {
            product['rating'] = 0.0;
          }
        } catch (e) {
          product['rating'] = 0.0;
        }
      }

      if (mounted) {
        setState(() {
          relatedProducts = products;
          isLoadingRelatedProducts = false;
        });
      }
    } catch (e) {
      debugPrint('ItemDetail: Error fetching related products: $e');
      if (mounted) {
        setState(() {
          relatedProducts = [];
          isLoadingRelatedProducts = false;
        });
      }
    }
  }

  Future<void> _checkLikeStatus() async {
    if (product == null) return;

    final isLiked = await _likedProductsService.isProductLiked(widget.productId);
    if (mounted) {
      setState(() {
        _isFavorite = isLiked;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (product == null) return;

    setState(() {
      _isLikeLoading = true;
    });

    try {
      final success = await _likedProductsService.toggleLike(widget.productId);

      if (mounted) {
        if (success) {
          // Re-check the actual like status from the database to ensure consistency
          final actualLikeStatus = await _likedProductsService.isProductLiked(widget.productId);

          setState(() {
            _isFavorite = actualLikeStatus;
            _isLikeLoading = false;
            _likeStateChanged = true; // Mark that like state has changed
          });

          if (mounted) {
            final productName = product?['title'] ?? product?['name'] ?? 'Product';
            if (_isFavorite) {
              EnhancedToasts.showItemLiked(context, productName);
            } else {
              EnhancedToasts.showItemUnliked(context, productName);
            }
          }
        } else {
          setState(() {
            _isLikeLoading = false;
          });

          EnhancedToasts.showError(
            context,
            'Failed to update liked status. Please try again.',
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLikeLoading = false;
        });

        EnhancedToasts.showError(
          context,
          'Error: ${e.toString()}',
          duration: const Duration(seconds: 2),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Return the like state change status when popping
          Navigator.of(context).pop(_likeStateChanged);
        }
      },
      child: Scaffold(
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
                  onPressed: () => Navigator.pop(context, _likeStateChanged),
                ),
                actions: [
                  IconButton(
                    icon: _isLikeLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                            ),
                          )
                        : Icon(
                            _isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: _isFavorite ? primaryRed : Colors.grey,
                          ),
                    onPressed: _isLikeLoading ? null : _toggleLike,
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
                                color: Colors.white.withValues(
                                  alpha: _current == entry.key ? 0.9 : 0.4,
                                ),
                                // Add shadow for better visibility against any background
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
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
                                Colors.black.withValues(alpha: 0.4),
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
                      // Price display with discount support
                      Builder(
                        builder: (context) {
                          if (product == null) {
                            return const Text('N/A', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600));
                          }

                          final priceInfo = ProductDiscountHelper.getProductPrices(product!);
                          return PriceDisplay(
                            currentPrice: priceInfo['current_price'],
                            originalPrice: priceInfo['original_price'],
                            discountPercentage: priceInfo['discount_percentage'],
                            currentPriceStyle: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: primaryBlue,
                            ),
                          );
                        },
                      ),
                      if (product?['quantity'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Quantity: ${product!['quantity']} left',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Rating and reviews
                      Row(
                        children: [
                          Icon(
                            totalReviews > 0 ? Icons.star : Icons.star_border,
                            color: totalReviews > 0 ? Colors.amber : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            totalReviews > 0 ? averageRating.toStringAsFixed(1) : '0.0',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            totalReviews > 0
                                ? '($totalReviews Review${totalReviews > 1 ? 's' : ''})'
                                : '(No reviews yet)',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Quantity Selector
                      Row(
                        children: [
                          const Text(
                            'Quantity:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: _selectedQuantity > 1
                                      ? () {
                                          setState(() {
                                            _selectedQuantity--;
                                          });
                                        }
                                      : null,
                                  icon: const Icon(Icons.remove),
                                  iconSize: 20,
                                ),
                                Container(
                                  constraints: const BoxConstraints(minWidth: 40),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _selectedQuantity.toString(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedQuantity++;
                                    });
                                  },
                                  icon: const Icon(Icons.add),
                                  iconSize: 20,
                                ),
                              ],
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
                        onPressed: hasUserReviewed ? null : () {
                          setState(() {
                            _showReviewInput = true;
                          });
                        },
                        icon: const Icon(Icons.rate_review_outlined),
                        label: Text(hasUserReviewed ? 'Already Reviewed' : 'Write a Review'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: hasUserReviewed ? Colors.grey : primaryBlue,
                          elevation: 0,
                          side: BorderSide(color: hasUserReviewed ? Colors.grey : primaryBlue),
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
                                controller: _reviewController,
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
                                    onPressed: () async {
                                      final scaffoldMessenger = ScaffoldMessenger.of(context);

                                      if (_rating == 0) {
                                        scaffoldMessenger.showSnackBar(
                                          const SnackBar(
                                            content: Text('Please select a rating'),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        return;
                                      }

                                      if (_reviewController.text.trim().isEmpty) {
                                        scaffoldMessenger.showSnackBar(
                                          const SnackBar(
                                            content: Text('Please write a comment'),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        return;
                                      }

                                      final reviewService = ReviewService();
                                      final success = await reviewService.addReview(
                                        productId: widget.productId,
                                        rating: _rating,
                                        comment: _reviewController.text.trim(),
                                      );

                                      if (success) {
                                        setState(() {
                                          _showReviewInput = false;
                                          _rating = 0;
                                          _reviewController.clear();
                                        });

                                        // Refresh reviews
                                        await fetchReviews();

                                        if (!mounted) return;
                                        scaffoldMessenger.showSnackBar(
                                          const SnackBar(
                                            content: Text('Review submitted successfully!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else {
                                        if (!mounted) return;
                                        scaffoldMessenger.showSnackBar(
                                          const SnackBar(
                                            content: Text('Failed to submit review. Please try again.'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
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
                          if (totalReviews > 0)
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AllReviewsPage(
                                      productId: widget.productId,
                                      productName: product?['title'] ?? product?['name'] ?? 'Product',
                                      averageRating: averageRating,
                                      totalReviews: totalReviews,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('View All'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Reviews content
                      if (isLoadingReviews)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (reviews.isEmpty)
                        Center(
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(vertical: 20),
                            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.rate_review_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No reviews yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Be the first to review this product!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...reviews.map((review) => _ReviewCard(review: review)),
                      const SizedBox(height: 24),
                      // Related products section
                      const Text(
                        'You May Also Like',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (isLoadingRelatedProducts)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (relatedProducts.isEmpty)
                        Center(
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(vertical: 20),
                            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No related products found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Check out our other products in the shop',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 240,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: relatedProducts.length,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemBuilder: (context, index) {
                              return _RelatedProductCard(
                                product: relatedProducts[index],
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
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isAddingToCart ? null : () async {
                        setState(() {
                          _isAddingToCart = true;
                        });

                        try {
                          // Prepare product data for cart
                          final productData = {
                            'id': product?['id']?.toString() ?? DateTime.now().toString(),
                            'name': product?['title'] ?? product?['name'] ?? 'Unknown Product',
                            'title': product?['title'] ?? product?['name'] ?? 'Unknown Product',
                            'image': productImages.isNotEmpty ? productImages.first : 'assets/placeholder.png',
                            'price': product?['price'] ?? 0.0,
                          };

                          // Add to cart with selected quantity
                          final success = await CartService().addItem(
                            productData,
                            quantity: _selectedQuantity,
                          );

                          if (!mounted) return;

                          if (success) {
                            if (mounted) {
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${productData['name']} added to cart'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          } else {
                            if (mounted) {
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to add item to cart. Please try again.'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (!mounted) return;
                          if (mounted) {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isAddingToCart = false;
                            });
                          }
                        }
                      },
                      icon: _isAddingToCart
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                              ),
                            )
                          : const Icon(Icons.shopping_cart_outlined),
                      label: Text(_isAddingToCart ? 'Adding...' : 'Add to Cart'),
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
                                'id': product?['id']?.toString() ?? DateTime.now().toString(),
                                'name': product?['title'] ?? product?['name'] ?? 'Unknown Product',
                                'title': product?['title'] ?? product?['name'] ?? 'Unknown Product',
                                'image': productImages.isNotEmpty ? productImages.first : 'assets/placeholder.png',
                                'price': product?['price'] ?? 0.0,
                                'quantity': _selectedQuantity,
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
                  color: primaryBlue.withValues(alpha: 0.1),
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

// Related product card widget for "You May Also Like" section
class _RelatedProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const _RelatedProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    // Parse price, handling potential errors
    double priceValue = 0.0;
    if (product['price'] is String) {
      try {
        priceValue = double.parse(product['price'] as String);
      } catch (e) {
        priceValue = 0.0;
      }
    } else if (product['price'] is num) {
      priceValue = (product['price'] as num).toDouble();
    }

    final double ratingValue = (product['rating'] ?? 0.0).toDouble();
    final int soldCountValue = (product['total_sold'] ?? 0); // Use total_sold from our data

    return Container(
      width: 180, // Adjusted width for better layout
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 1, // Added subtle shadow
        shadowColor: Colors.grey.withValues(alpha: 0.2),
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
                      child: (product['image']?.toString().startsWith('http') ?? false)
                          ? Image.network(
                              product['image'],
                              fit: BoxFit.cover,
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
                            )
                          : Image.asset(
                              product['image'] ?? 'assets/placeholder.png',
                              fit: BoxFit.cover,
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
                  product['title'] ?? product['name'] ?? 'Unknown Product',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Product Price
                Text(
                  CurrencyFormatter.formatPeso(priceValue),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryBlue,
                  ),
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
                      '$soldCountValue sold',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
