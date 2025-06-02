import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Color constants matching app design patterns
const Color primaryBlue = Color(0xFF233A63);   // Main primary color
const Color secondaryBlue = Color(0xFF3F51B5); // Secondary blue
const Color backgroundColor = Color(0xFFF6F7FB); // Light background

/// Optimized image widget with caching, lazy loading, and error handling
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableMemoryCache;
  final Duration? fadeInDuration;
  final Duration? placeholderFadeInDuration;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.enableMemoryCache = true,
    this.fadeInDuration,
    this.placeholderFadeInDuration,
  });

  /// Factory constructor for product images
  factory OptimizedImage.product({
    required String imageUrl,
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return OptimizedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      placeholder: _ProductImagePlaceholder(width: width, height: height),
      errorWidget: _ProductImageError(width: width, height: height),
    );
  }

  /// Factory constructor for pet images
  factory OptimizedImage.pet({
    required String imageUrl,
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return OptimizedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      placeholder: _PetImagePlaceholder(width: width, height: height),
      errorWidget: _PetImageError(width: width, height: height),
    );
  }

  /// Factory constructor for profile images
  factory OptimizedImage.profile({
    required String imageUrl,
    double? size,
  }) {
    return OptimizedImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular((size ?? 40) / 2),
      placeholder: _ProfileImagePlaceholder(size: size),
      errorWidget: _ProfileImageError(size: size),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    // Check if it's a network URL or asset path
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      // Network image with caching
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
        fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 300),
        placeholderFadeInDuration: placeholderFadeInDuration ?? const Duration(milliseconds: 200),
        placeholder: (context, url) => placeholder ?? _DefaultPlaceholder(width: width, height: height),
        errorWidget: (context, url, error) => errorWidget ?? _DefaultErrorWidget(width: width, height: height),
        cacheManager: enableMemoryCache ? null : null, // Use default cache manager
      );
    } else {
      // Asset image
      imageWidget = Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => 
            errorWidget ?? _DefaultErrorWidget(width: width, height: height),
      );
    }

    // Apply border radius if specified
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

/// Default placeholder widget
class _DefaultPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;

  const _DefaultPlaceholder({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          color: primaryBlue,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

/// Default error widget
class _DefaultErrorWidget extends StatelessWidget {
  final double? width;
  final double? height;

  const _DefaultErrorWidget({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            color: Colors.grey[600],
            size: (width != null && width! < 100) ? 20 : 40,
          ),
          if (width == null || width! >= 100) ...[
            const SizedBox(height: 8),
            Text(
              'Image not available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Product image placeholder
class _ProductImagePlaceholder extends StatelessWidget {
  final double? width;
  final double? height;

  const _ProductImagePlaceholder({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            color: primaryBlue.withValues(alpha: 0.5),
            size: (width != null && width! < 100) ? 24 : 40,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: primaryBlue,
              strokeWidth: 2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Product image error widget
class _ProductImageError extends StatelessWidget {
  final double? width;
  final double? height;

  const _ProductImageError({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            color: Colors.grey[500],
            size: (width != null && width! < 100) ? 24 : 40,
          ),
          if (width == null || width! >= 100) ...[
            const SizedBox(height: 8),
            Text(
              'Product image\nnot available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Pet image placeholder
class _PetImagePlaceholder extends StatelessWidget {
  final double? width;
  final double? height;

  const _PetImagePlaceholder({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            color: primaryBlue.withValues(alpha: 0.5),
            size: (width != null && width! < 100) ? 24 : 40,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: primaryBlue,
              strokeWidth: 2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pet image error widget
class _PetImageError extends StatelessWidget {
  final double? width;
  final double? height;

  const _PetImageError({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            color: Colors.grey[600],
            size: (width != null && width! < 100) ? 24 : 40,
          ),
          if (width == null || width! >= 100) ...[
            const SizedBox(height: 8),
            Text(
              'Pet photo\nnot available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Profile image placeholder
class _ProfileImagePlaceholder extends StatelessWidget {
  final double? size;

  const _ProfileImagePlaceholder({this.size});

  @override
  Widget build(BuildContext context) {
    final double actualSize = size ?? 40;
    return Container(
      width: actualSize,
      height: actualSize,
      decoration: BoxDecoration(
        color: primaryBlue.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: actualSize * 0.4,
          height: actualSize * 0.4,
          child: CircularProgressIndicator(
            color: primaryBlue,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

/// Profile image error widget
class _ProfileImageError extends StatelessWidget {
  final double? size;

  const _ProfileImageError({this.size});

  @override
  Widget build(BuildContext context) {
    final double actualSize = size ?? 40;
    return Container(
      width: actualSize,
      height: actualSize,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        color: Colors.grey[600],
        size: actualSize * 0.6,
      ),
    );
  }
}
