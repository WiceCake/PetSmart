import 'package:intl/intl.dart';

/// Utility class for formatting currency values in Philippine Pesos
class CurrencyFormatter {
  static const String currencySymbol = '₱';
  static const String currencyCode = 'PHP';
  
  /// Format a number as Philippine Peso currency
  /// Example: formatPeso(1250.50) returns "₱1,250.50"
  static String formatPeso(dynamic amount) {
    if (amount == null) return '₱0.00';
    
    double value;
    if (amount is String) {
      // Remove any existing currency symbols and parse
      final cleanAmount = amount.replaceAll(RegExp(r'[^\d.]'), '');
      value = double.tryParse(cleanAmount) ?? 0.0;
    } else if (amount is num) {
      value = amount.toDouble();
    } else {
      value = 0.0;
    }
    
    final formatter = NumberFormat.currency(
      locale: 'en_PH',
      symbol: currencySymbol,
      decimalDigits: 2,
    );
    
    return formatter.format(value);
  }
  
  /// Format a number as Philippine Peso currency without symbol
  /// Example: formatPesoAmount(1250.50) returns "1,250.50"
  static String formatPesoAmount(dynamic amount) {
    if (amount == null) return '0.00';
    
    double value;
    if (amount is String) {
      final cleanAmount = amount.replaceAll(RegExp(r'[^\d.]'), '');
      value = double.tryParse(cleanAmount) ?? 0.0;
    } else if (amount is num) {
      value = amount.toDouble();
    } else {
      value = 0.0;
    }
    
    final formatter = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '',
      decimalDigits: 2,
    );
    
    return formatter.format(value).trim();
  }
  
  /// Parse a currency string to double value
  /// Example: parsePeso("₱1,250.50") returns 1250.50
  static double parsePeso(String currencyString) {
    if (currencyString.isEmpty) return 0.0;
    
    // Remove currency symbols, commas, and spaces
    final cleanString = currencyString.replaceAll(RegExp(r'[₱$,\s]'), '');
    return double.tryParse(cleanString) ?? 0.0;
  }
  
  /// Convert USD amount to PHP amount using 1 USD = 50 PHP rate
  /// Example: convertUsdToPhp(24.99) returns 1249.50
  static double convertUsdToPhp(double usdAmount) {
    return usdAmount * 50.0;
  }
  
  /// Format USD amount as PHP currency
  /// Example: formatUsdAsPeso(24.99) returns "₱1,249.50"
  static String formatUsdAsPeso(dynamic usdAmount) {
    if (usdAmount == null) return '₱0.00';
    
    double value;
    if (usdAmount is String) {
      final cleanAmount = usdAmount.replaceAll(RegExp(r'[^\d.]'), '');
      value = double.tryParse(cleanAmount) ?? 0.0;
    } else if (usdAmount is num) {
      value = usdAmount.toDouble();
    } else {
      value = 0.0;
    }
    
    final phpAmount = convertUsdToPhp(value);
    return formatPeso(phpAmount);
  }
}
