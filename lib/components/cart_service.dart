import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_smart/utils/currency_formatter.dart';

class CartService {
  static final CartService _instance = CartService._internal();
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;

  factory CartService() {
    return _instance;
  }

  CartService._internal();

  List<Map<String, dynamic>> get items => _items;
  bool get isLoading => _isLoading;

  /// Initialize cart by fetching user's cart items from Supabase
  Future<void> initializeCart() async {
    try {
      _isLoading = true;
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _items = [];
        return;
      }

      // Try to fetch from Supabase, fallback to mock data if tables don't exist
      try {
        final response = await _supabase
            .from('cart_items')
            .select('''
              *,
              product:product_id (
                id,
                title,
                price,
                product_images (
                  image_url,
                  is_thumbnail
                )
              )
            ''')
            .eq('user_id', user.id)
            .order('created_at', ascending: false);

        _items = List<Map<String, dynamic>>.from(response).map((cartItem) {
          final product = cartItem['product'] ?? {};
          final images = product['product_images'] as List<dynamic>? ?? [];
          final imageUrl = images.isNotEmpty
              ? images.firstWhere((img) => img['is_thumbnail'] == true,
                  orElse: () => images.first)['image_url']
              : 'assets/placeholder.png';

          return {
            'id': product['id'] ?? cartItem['product_id'],
            'cart_item_id': cartItem['id'],
            'name': product['title'] ?? 'Unknown Product',
            'title': product['title'] ?? 'Unknown Product',
            'image': imageUrl,
            'price': product['price'] ?? 0.0,
            'quantity': cartItem['quantity'] ?? 1,
          };
        }).toList();
      } catch (e) {
        print('CartService: Database tables not found, using local storage: $e');
        // Keep existing local items if database is not available
      }
    } catch (e) {
      print('CartService: Error initializing cart: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// Add item to cart (Supabase + local fallback)
  Future<bool> addItem(Map<String, dynamic> product, {int quantity = 1}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final productId = product['id']?.toString();
      if (productId == null) {
        throw Exception('Product ID is required');
      }

      // Try to add to Supabase first
      try {
        // Check if item already exists in cart
        final existingItems = await _supabase
            .from('cart_items')
            .select('*')
            .eq('user_id', user.id)
            .eq('product_id', productId);

        if (existingItems.isNotEmpty) {
          // Update existing item quantity
          final existingItem = existingItems.first;
          final newQuantity = (existingItem['quantity'] as int? ?? 0) + quantity;

          await _supabase
              .from('cart_items')
              .update({'quantity': newQuantity})
              .eq('id', existingItem['id']);
        } else {
          // Insert new cart item
          await _supabase
              .from('cart_items')
              .insert({
                'user_id': user.id,
                'product_id': productId,
                'quantity': quantity,
              });
        }

        // Refresh cart from database
        await initializeCart();
        return true;
      } catch (e) {
        print('CartService: Database operation failed, using local storage: $e');
        // Fallback to local storage
        _addItemLocally(product, quantity: quantity);
        return true;
      }
    } catch (e) {
      print('CartService: Error adding item to cart: $e');
      return false;
    }
  }

  /// Local fallback for adding items
  void _addItemLocally(Map<String, dynamic> product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere((item) => item['id'] == product['id']);

    if (existingIndex != -1) {
      _items[existingIndex]['quantity'] = (_items[existingIndex]['quantity'] ?? 1) + quantity;
    } else {
      _items.add({
        'id': product['id'] ?? DateTime.now().toString(),
        'name': product['name'] ?? product['title'] ?? 'Unknown Product',
        'title': product['title'] ?? product['name'] ?? 'Unknown Product',
        'image': product['image'] ?? 'assets/placeholder.png',
        'price': _parsePrice(product['price']),
        'quantity': quantity,
      });
    }
  }

  /// Remove item from cart
  Future<bool> removeItem(int index) async {
    try {
      if (index < 0 || index >= _items.length) return false;

      final item = _items[index];
      final user = _supabase.auth.currentUser;

      if (user != null && item['cart_item_id'] != null) {
        try {
          await _supabase
              .from('cart_items')
              .delete()
              .eq('id', item['cart_item_id']);
        } catch (e) {
          print('CartService: Database delete failed, removing locally: $e');
        }
      }

      _items.removeAt(index);
      return true;
    } catch (e) {
      print('CartService: Error removing item: $e');
      return false;
    }
  }

  /// Update item quantity
  Future<bool> updateQuantity(int index, int quantity) async {
    try {
      if (index < 0 || index >= _items.length || quantity <= 0) return false;

      final item = _items[index];
      final user = _supabase.auth.currentUser;

      if (user != null && item['cart_item_id'] != null) {
        try {
          await _supabase
              .from('cart_items')
              .update({'quantity': quantity})
              .eq('id', item['cart_item_id']);
        } catch (e) {
          print('CartService: Database update failed, updating locally: $e');
        }
      }

      _items[index]['quantity'] = quantity;
      return true;
    } catch (e) {
      print('CartService: Error updating quantity: $e');
      return false;
    }
  }

  /// Get cart total
  double getTotal() {
    return _items.fold(0, (total, item) {
      final price = _parsePrice(item['price']);
      final quantity = item['quantity'] as int? ?? 1;
      return total + (price * quantity);
    });
  }

  /// Get selected items total
  double getSelectedTotal(Set<int> selectedIndices) {
    double total = 0;
    for (int index in selectedIndices) {
      if (index < _items.length) {
        final item = _items[index];
        final price = _parsePrice(item['price']);
        final quantity = item['quantity'] as int? ?? 1;
        total += price * quantity;
      }
    }
    return total;
  }

  /// Clear entire cart
  Future<void> clear() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        try {
          await _supabase
              .from('cart_items')
              .delete()
              .eq('user_id', user.id);
        } catch (e) {
          print('CartService: Database clear failed: $e');
        }
      }
      _items.clear();
    } catch (e) {
      print('CartService: Error clearing cart: $e');
    }
  }

  /// Helper method to parse price from various formats
  double _parsePrice(dynamic price) {
    if (price is num) return price.toDouble();
    if (price is String) {
      return CurrencyFormatter.parsePeso(price);
    }
    return 0.0;
  }

  /// Get cart item count
  int get itemCount => _items.length;

  /// Get total quantity of all items
  int get totalQuantity => _items.fold(0, (total, item) => total + (item['quantity'] as int? ?? 1));
}