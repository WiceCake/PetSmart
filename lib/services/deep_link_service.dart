import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:pet_smart/services/email_verification_service.dart';
import 'package:pet_smart/components/enhanced_toasts.dart';
import 'package:pet_smart/auth/email_verification_success.dart';

/// Service to handle deep links for push notifications and other app navigation
/// OAuth is now handled natively, so OAuth-related deep links are no longer needed
class DeepLinkService {
  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _linkSubscription;
  static BuildContext? _context;

  /// Initialize deep link handling
  static Future<void> initialize(BuildContext context) async {
    try {
      debugPrint('🔗 DeepLinkService: Starting initialization...');
      _context = context;

      // Handle app launch from deep link
      final initialUri = await _appLinks.getInitialLink();
      debugPrint('🔗 DeepLinkService: Initial URI check: $initialUri');
      if (initialUri != null) {
        debugPrint('🔗 App launched with deep link: $initialUri');
        if (_context != null && _context!.mounted) {
          await _handleDeepLink(_context!, initialUri);
        }
      }

      // Listen for incoming deep links while app is running
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          debugPrint('🔗 Received deep link: $uri');
          if (_context != null && _context!.mounted) {
            _handleDeepLink(_context!, uri);
          }
        },
        onError: (err) {
          debugPrint('🔗 Deep link error: $err');
        },
      );
      debugPrint('🔗 DeepLinkService: Initialization completed successfully');
    } catch (e) {
      debugPrint('🔗 Error initializing deep links: $e');
    }
  }

  /// Handle incoming deep link
  static Future<void> _handleDeepLink(BuildContext context, Uri uri) async {
    debugPrint('Processing deep link: ${uri.toString()}');

    // Handle email verification deep links (from Supabase)
    if (uri.host == 'petsmart-app.com' && uri.path.contains('/auth/callback')) {
      await _handleEmailVerificationDeepLink(context, uri);
    }
    // Handle push notification deep links
    else if (uri.scheme == 'com.example.pet_smart') {
      await _handlePushNotificationDeepLink(context, uri);
    } else {
      debugPrint('Unhandled deep link: $uri');
    }
  }

  /// Handle email verification deep link
  static Future<void> _handleEmailVerificationDeepLink(BuildContext context, Uri uri) async {
    try {
      debugPrint('Handling email verification deep link: ${uri.toString()}');

      // Extract tokens from the URL fragment
      final fragment = uri.fragment;
      if (fragment.isEmpty) {
        debugPrint('No fragment found in verification URL');
        return;
      }

      // Parse the fragment to extract access_token and refresh_token
      final params = Uri.splitQueryString(fragment);
      final accessToken = params['access_token'];
      final refreshToken = params['refresh_token'];

      if (accessToken == null || refreshToken == null) {
        debugPrint('Missing tokens in verification URL');
        if (context.mounted) {
          EnhancedToasts.showError(
            context,
            'Invalid verification link. Please try again.',
          );
        }
        return;
      }

      // Handle the verification
      final verificationService = EmailVerificationService();
      final result = await verificationService.handleVerificationCallback(accessToken, refreshToken);

      if (context.mounted) {
        if (result.isSuccess) {
          // Navigate to success screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const EmailVerificationSuccessScreen(),
            ),
          );
        } else {
          EnhancedToasts.showError(
            context,
            result.errorMessage ?? 'Email verification failed.',
            duration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      debugPrint('Error handling email verification deep link: $e');
      if (context.mounted) {
        EnhancedToasts.showError(
          context,
          'An error occurred during email verification.',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  /// Handle push notification deep link
  static Future<void> _handlePushNotificationDeepLink(BuildContext context, Uri uri) async {
    try {
      debugPrint('Handling push notification deep link: ${uri.toString()}');

      // Extract path and query parameters
      final path = uri.path;
      final queryParams = uri.queryParameters;
      debugPrint('Deep link path: $path, params: $queryParams');

      // Handle different deep link paths
      if (path == '/notifications') {
        // Navigate to notifications screen
        debugPrint('Navigating to notifications screen from deep link');
        if (context.mounted) {
          Navigator.pushNamed(context, '/notifications');
        }
      } else {
        debugPrint('Unhandled push notification deep link path: $path');
      }
    } catch (e) {
      debugPrint('Error handling push notification deep link: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening notification: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }



  /// Dispose of deep link subscription
  static void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _context = null;
  }
}
