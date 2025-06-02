import 'package:flutter/material.dart';

class DiscountBadge extends StatelessWidget {
  final double discountPercentage;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;

  const DiscountBadge({
    super.key,
    required this.discountPercentage,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (discountPercentage <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFE57373).withValues(alpha: 0.1),
        borderRadius: borderRadius ?? BorderRadius.circular(4),
        border: Border.all(
          color: backgroundColor ?? const Color(0xFFE57373),
          width: 0.5,
        ),
      ),
      child: Text(
        '${discountPercentage.toInt()}% OFF',
        style: TextStyle(
          color: textColor ?? const Color(0xFFE57373),
          fontWeight: FontWeight.w600,
          fontSize: fontSize ?? 12,
        ),
      ),
    );
  }
}

class PriceDisplay extends StatelessWidget {
  final double currentPrice;
  final double? originalPrice;
  final double? discountPercentage;
  final TextStyle? currentPriceStyle;
  final TextStyle? originalPriceStyle;
  final bool showDiscountBadge;
  final MainAxisAlignment alignment;

  const PriceDisplay({
    super.key,
    required this.currentPrice,
    this.originalPrice,
    this.discountPercentage,
    this.currentPriceStyle,
    this.originalPriceStyle,
    this.showDiscountBadge = true,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasDiscount = originalPrice != null &&
                            originalPrice! > currentPrice &&
                            discountPercentage != null &&
                            discountPercentage! > 0;

    return Row(
      mainAxisAlignment: alignment,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Current price
        Text(
          '₱${currentPrice.toStringAsFixed(2)}',
          style: currentPriceStyle ?? const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3F51B5),
          ),
        ),

        if (hasDiscount) ...[
          const SizedBox(width: 8),
          // Original price (crossed out)
          Text(
            '₱${originalPrice!.toStringAsFixed(2)}',
            style: originalPriceStyle ?? TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.grey[600],
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.grey[600],
            ),
          ),

          if (showDiscountBadge) ...[
            const SizedBox(width: 8),
            DiscountBadge(discountPercentage: discountPercentage!),
          ],
        ],
      ],
    );
  }
}

class ProductDiscountHelper {
  /// Calculate discount percentage from original and current price
  static double calculateDiscountPercentage(double originalPrice, double currentPrice) {
    if (originalPrice <= 0 || currentPrice >= originalPrice) {
      return 0.0;
    }
    return ((originalPrice - currentPrice) / originalPrice) * 100;
  }

  /// Calculate discounted price from original price and discount percentage
  static double calculateDiscountedPrice(double originalPrice, double discountPercentage) {
    if (discountPercentage <= 0 || discountPercentage >= 100) {
      return originalPrice;
    }
    return originalPrice * (1 - (discountPercentage / 100));
  }

  /// Check if a product is currently on sale based on date range
  static bool isProductOnSale(Map<String, dynamic> product) {
    final isOnSale = product['is_on_sale'] as bool? ?? false;
    if (!isOnSale) return false;

    final now = DateTime.now();

    // Check sale start date
    final saleStartDate = product['sale_start_date'];
    if (saleStartDate != null) {
      final startDate = DateTime.parse(saleStartDate);
      if (now.isBefore(startDate)) return false;
    }

    // Check sale end date
    final saleEndDate = product['sale_end_date'];
    if (saleEndDate != null) {
      final endDate = DateTime.parse(saleEndDate);
      if (now.isAfter(endDate)) return false;
    }

    return true;
  }

  /// Get the effective price for a product (considering discounts)
  static double getEffectivePrice(Map<String, dynamic> product) {
    if (!isProductOnSale(product)) {
      return (product['price'] as num?)?.toDouble() ?? 0.0;
    }

    final originalPrice = (product['original_price'] as num?)?.toDouble();
    final currentPrice = (product['price'] as num?)?.toDouble() ?? 0.0;
    final discountPercentage = (product['discount_percentage'] as num?)?.toDouble();

    // If we have original price and discount percentage, calculate from those
    if (originalPrice != null && discountPercentage != null && discountPercentage > 0) {
      return calculateDiscountedPrice(originalPrice, discountPercentage);
    }

    // Otherwise, use the current price
    return currentPrice;
  }

  /// Get display prices for a product
  static Map<String, dynamic> getProductPrices(Map<String, dynamic> product) {
    final isOnSale = isProductOnSale(product);
    final currentPrice = (product['price'] as num?)?.toDouble() ?? 0.0;
    final originalPrice = (product['original_price'] as num?)?.toDouble();
    final discountPercentage = (product['discount_percentage'] as num?)?.toDouble();

    if (isOnSale && originalPrice != null && discountPercentage != null && discountPercentage > 0) {
      final effectivePrice = calculateDiscountedPrice(originalPrice, discountPercentage);
      return {
        'current_price': effectivePrice,
        'original_price': originalPrice,
        'discount_percentage': discountPercentage,
        'has_discount': true,
      };
    }

    return {
      'current_price': currentPrice,
      'original_price': null,
      'discount_percentage': null,
      'has_discount': false,
    };
  }
}
