import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing search history with local storage
class SearchHistoryService {
  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistoryItems = 10;

  /// Get search history from local storage
  static Future<List<String>> getSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_searchHistoryKey) ?? [];
      return historyJson;
    } catch (e) {
      return [];
    }
  }

  /// Add a search term to history
  static Future<void> addToSearchHistory(String searchTerm) async {
    if (searchTerm.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList(_searchHistoryKey) ?? [];

      // Remove if already exists to avoid duplicates
      history.removeWhere((item) => item.toLowerCase() == searchTerm.toLowerCase());

      // Add to beginning of list
      history.insert(0, searchTerm.trim());

      // Keep only last N searches
      if (history.length > _maxHistoryItems) {
        history = history.take(_maxHistoryItems).toList();
      }

      await prefs.setStringList(_searchHistoryKey, history);
    } catch (e) {
      // Fail silently - search history is not critical
    }
  }

  /// Remove a specific search term from history
  static Future<void> removeFromSearchHistory(String searchTerm) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList(_searchHistoryKey) ?? [];

      history.removeWhere((item) => item.toLowerCase() == searchTerm.toLowerCase());

      await prefs.setStringList(_searchHistoryKey, history);
    } catch (e) {
      // Fail silently
    }
  }

  /// Clear all search history
  static Future<void> clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_searchHistoryKey);
    } catch (e) {
      // Fail silently
    }
  }

  /// Get popular search suggestions based on history and predefined terms
  static Future<List<String>> getSearchSuggestions(String query) async {
    if (query.trim().isEmpty) return [];

    final lowercaseQuery = query.toLowerCase();

    // Predefined popular search terms
    final List<String> popularTerms = [
      'dog food',
      'cat food',
      'pet toys',
      'pet accessories',
      'pet grooming',
      'pet treats',
      'pet supplies',
      'pet carrier',
      'pet bowl',
      'pet bed',
      'pet collar',
      'pet leash',
      'pet shampoo',
      'pet vitamins',
      'pet medicine',
    ];

    // Get search history
    final history = await getSearchHistory();

    // Combine history and popular terms
    final allTerms = [...history, ...popularTerms];

    // Filter based on query
    final suggestions = allTerms
        .where((term) => term.toLowerCase().contains(lowercaseQuery))
        .toSet() // Remove duplicates
        .take(5) // Limit to 5 suggestions
        .toList();

    return suggestions;
  }
}
