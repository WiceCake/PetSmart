class SearchService {
  static List<Map<String, dynamic>> searchProducts(
    String query, 
    List<Map<String, dynamic>> allProducts
  ) {
    if (query.isEmpty) return [];
    
    final lowercaseQuery = query.toLowerCase();
    return allProducts.where((product) {
      final lowercaseName = product['name'].toString().toLowerCase();
      final String description = product['description']?.toString().toLowerCase() ?? '';
      
      return lowercaseName.contains(lowercaseQuery) || 
             description.contains(lowercaseQuery);
    }).toList();
  }

  static List<String> getSearchSuggestions(String query) {
    // Mock suggestions - you can replace with your own logic
    final List<String> allSuggestions = [
      'pet food',
      'pet toys',
      'dog food',
      'cat food',
      'pet accessories',
      'pet grooming',
      'pet treats',
      'pet supplies',
      'pet carrier',
      'pet bowl',
    ];

    if (query.isEmpty) return [];

    return allSuggestions
        .where((suggestion) =>
            suggestion.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}