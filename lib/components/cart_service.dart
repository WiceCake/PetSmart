class CartService {
  static final CartService _instance = CartService._internal();
  final List<Map<String, dynamic>> _items = [];
  
  factory CartService() {
    return _instance;
  }
  
  CartService._internal();
  
  List<Map<String, dynamic>> get items => _items;
  
  void addItem(Map<String, dynamic> product) {
    // Check if item already exists
    final existingIndex = _items.indexWhere((item) => item['id'] == product['id']);
    
    if (existingIndex != -1) {
      // Update quantity if item exists
      _items[existingIndex]['quantity'] = (_items[existingIndex]['quantity'] ?? 1) + 1;
    } else {
      // Add new item with quantity
      _items.add({
        ...product,
        'quantity': 1,
      });
    }
  }
  
  void removeItem(int index) {
    _items.removeAt(index);
  }
  
  void updateQuantity(int index, int quantity) {
    if (quantity > 0) {
      _items[index]['quantity'] = quantity;
    }
  }
  
  double getTotal() {
    return _items.fold(0, (total, item) {
      final price = double.tryParse(item['price'].toString().replaceAll('\$', '')) ?? 0;
      return total + (price * (item['quantity'] ?? 1));
    });
  }
  
  void clear() {
    _items.clear();
  }
}