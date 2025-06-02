import 'package:flutter/material.dart';
import 'package:pet_smart/auth/auth.dart';
import 'package:pet_smart/auth/user_details.dart';
import 'package:pet_smart/auth/profile_setup.dart';

import 'package:pet_smart/components/nav_bar.dart';
import 'package:pet_smart/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_smart/services/push_notification_service.dart';
import 'package:pet_smart/services/realtime_notification_service.dart';
import 'package:pet_smart/services/navigation_service.dart';
import 'package:pet_smart/services/profile_completion_service.dart';

import 'package:pet_smart/services/deep_link_service.dart';
import 'package:pet_smart/pages/notifications_list.dart';

/// Main entry point of the application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeSupabase();

  runApp(const MyApp());
}

/// Initialize Supabase with proper error handling
Future<void> _initializeSupabase() async {
  if (!AppConfig.isConfigured()) {
    debugPrint('Warning: Supabase configuration not found. Running in demo mode.');
    return;
  }

  try {
    await Supabase.initialize(
      url: AppConfig.getSupabaseUrl(),
      anonKey: AppConfig.getSupabaseAnonKey(),
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      // Add timeout and retry configuration for better network handling
      realtimeClientOptions: const RealtimeClientOptions(
        timeout: Duration(seconds: 30),
      ),
    );
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Error initializing Supabase: $e');
    // Continue anyway - the app will handle auth errors gracefully
  }
}

/// Root widget of the application
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Only show splash on first launch, not during hot reload
    _checkIfShouldShowSplash();
  }

  void _checkIfShouldShowSplash() {
    // Always show splash screen first, regardless of session state
    // This ensures consistent behavior in both debug and release modes
    debugPrint('Showing splash screen');
    // _showSplash is already true by default, so no need to change it
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetSmart',
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF233A63),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: _showSplash ? const SplashScreen() : const AuthWrapper(),
      routes: {
        '/auth': (context) => const AuthWrapper(),
        '/notifications': (context) => const NotificationsListPage(),
      },
    );
  }
}

/// Splash screen with responsive animated logo and white background
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start animation and navigate after delay
    _animationController.forward();
    _navigateToNext();
  }

  void _navigateToNext() {
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const AuthWrapper(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Calculate responsive logo size - much smaller than before
    // Use 40% of screen width or 15% of screen height, whichever is smaller
    final logoWidth = (screenWidth * 0.4).clamp(120.0, 200.0);
    final logoHeight = (screenHeight * 0.15).clamp(80.0, 120.0);
    final logoSize = logoWidth < logoHeight ? logoWidth : logoHeight;

    return Scaffold(
      backgroundColor: Colors.white, // White background as requested
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Image.asset(
            'assets/petsmart_word.png',
            width: logoSize,
            height: logoSize, // Maintain aspect ratio but make it more compact
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

/// Authentication wrapper that checks login status and routes accordingly
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  ProfileCompletionStatus? _profileStatus;

  static const Duration _timeoutDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    debugPrint('🔐 AuthWrapper: Initializing authentication check');
    _checkAuthStatus();
    _setupAuthListener();
    // Initialize deep links after a small delay to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDeepLinks();
    });
  }

  /// Initialize deep link handling for OAuth callbacks
  void _initializeDeepLinks() {
    try {
      debugPrint('🔗 Initializing deep link service...');
      DeepLinkService.initialize(context);
      debugPrint('🔗 Deep link service initialized successfully');
    } catch (e) {
      debugPrint('🔗 Error initializing deep link service: $e');
    }
  }

  /// Setup authentication state listener for real-time updates
  void _setupAuthListener() {
    if (AppConfig.isConfigured()) {
      try {
        Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
          final session = data.session;
          final user = data.session?.user;
          final event = data.event;

          debugPrint('🔐 Auth state change event: $event');
          debugPrint('🔐 Auth state changed - Session exists: ${session != null}');
          debugPrint('🔐 Auth state changed - Email confirmed: ${user?.emailConfirmedAt != null}');

          // Check if session exists and user is present
          final hasSession = session != null && user != null;

          debugPrint('🔐 Auth state changed - Has session: $hasSession');
          debugPrint('🔐 Auth state changed - Email confirmed: ${user?.emailConfirmedAt != null}');

          if (mounted) {
            if (hasSession) {
              // Check profile completion status (includes email verification)
              final profileStatus = await ProfileCompletionService().checkProfileCompletion(user.id);
              debugPrint('🔐 Auth state changed - Profile status: $profileStatus');

              setState(() {
                _isLoggedIn = profileStatus == ProfileCompletionStatus.complete;
                _profileStatus = profileStatus;
                _isLoading = false;
              });

              // Initialize push notifications when user is fully logged in
              if (_isLoggedIn) {
                _initializePushNotifications();
                // Execute any pending navigation after login
                _executePendingNavigation();
              }
            } else {
              // Handle logout/signout events
              debugPrint('🔐 User logged out - clearing state');

              // Cleanup real-time notification service
              try {
                final realtimeNotificationService = RealtimeNotificationService();
                await realtimeNotificationService.dispose();
                debugPrint('Real-time notification service disposed on logout');
              } catch (e) {
                debugPrint('Error disposing real-time notification service: $e');
              }

              setState(() {
                _isLoggedIn = false;
                _profileStatus = null;
                _isLoading = false;
              });
            }
          }
        });
      } catch (e) {
        debugPrint('Failed to setup auth listener: $e');
      }
    }
  }

  /// Check authentication status and update UI accordingly
  Future<void> _checkAuthStatus() async {
    try {
      // Shorter delay for better UX
      await Future.delayed(const Duration(milliseconds: 300));

      // Check if Supabase is configured
      if (!AppConfig.isConfigured()) {
        debugPrint('Supabase not configured, showing auth screen');
        _updateAuthState(isLoggedIn: false);
        return;
      }

      // Check current session with retry logic for release mode
      bool isLoggedIn = false;
      ProfileCompletionStatus? profileStatus;

      for (int attempt = 0; attempt < 5; attempt++) {
        try {
          final session = Supabase.instance.client.auth.currentSession;
          final user = Supabase.instance.client.auth.currentUser;

          // Check if session exists and user is present
          bool hasSession = session != null && user != null;

          if (session != null && user != null) {
            debugPrint('Auth check completed - Session exists: true');
            debugPrint('Email confirmed: ${user.emailConfirmedAt != null}');
            debugPrint('Session expires at: ${session.expiresAt}');

            // Verify session is not expired
            final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            if (session.expiresAt != null && session.expiresAt! <= now) {
              debugPrint('Session expired, treating as logged out');
              hasSession = false;
            }

            if (hasSession) {
              debugPrint('User has valid session, checking profile completion');
              // Check profile completion status (includes email verification)
              profileStatus = await ProfileCompletionService().checkProfileCompletion(user.id);
              debugPrint('Profile completion status: $profileStatus');

              // User is fully logged in only if profile is complete
              isLoggedIn = profileStatus == ProfileCompletionStatus.complete;
              debugPrint('User fully logged in: $isLoggedIn');
            }
            break;
          }

          // If no session, wait a bit and try again (for release mode)
          if (attempt < 4) {
            await Future.delayed(Duration(milliseconds: 300 + (attempt * 100)));
          }
        } catch (e) {
          debugPrint('Auth check attempt ${attempt + 1} failed: $e');
          if (attempt == 4) {
            // Last attempt failed
            isLoggedIn = false;
          } else {
            await Future.delayed(Duration(milliseconds: 300 + (attempt * 100)));
          }
        }
      }

      debugPrint('Final auth check result - User logged in: $isLoggedIn');
      _updateAuthState(isLoggedIn: isLoggedIn, profileStatus: profileStatus);

      // Initialize push notifications if user is already logged in
      if (isLoggedIn) {
        _initializePushNotifications();
      }

    } catch (e) {
      debugPrint('Critical error during auth check: $e');
      _updateAuthState(isLoggedIn: false);
    }

    // Failsafe timeout
    _setFailsafeTimeout();
  }

  /// Update authentication state if widget is still mounted
  void _updateAuthState({required bool isLoggedIn, ProfileCompletionStatus? profileStatus}) {
    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _profileStatus = profileStatus;
        _isLoading = false;
      });
    }
  }

  /// Set failsafe timeout to prevent infinite loading
  void _setFailsafeTimeout() {
    Future.delayed(_timeoutDuration, () {
      if (mounted && _isLoading) {
        debugPrint('Auth check timeout reached, showing auth screen');
        _updateAuthState(isLoggedIn: false);
      }
    });
  }

  /// Initialize push notification service and real-time notifications
  Future<void> _initializePushNotifications() async {
    try {
      // Initialize push notification service
      final pushService = PushNotificationService();
      await pushService.initialize();
      debugPrint('Push notification service initialized successfully');

      // Initialize real-time notification service
      final realtimeNotificationService = RealtimeNotificationService();
      await realtimeNotificationService.initialize();
      debugPrint('Real-time notification service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notification services: $e');
    }
  }

  /// Execute any pending navigation after authentication
  Future<void> _executePendingNavigation() async {
    try {
      final navigationService = NavigationService();
      if (navigationService.hasPendingNavigation) {
        // Small delay to ensure the UI is ready
        await Future.delayed(const Duration(milliseconds: 500));
        await navigationService.executePendingNavigation();
      }
    } catch (e) {
      debugPrint('Error executing pending navigation: $e');
    }
  }

  @override
  void dispose() {
    // Cleanup services
    DeepLinkService.dispose();

    // Cleanup real-time notification service
    try {
      final realtimeNotificationService = RealtimeNotificationService();
      realtimeNotificationService.dispose();
    } catch (e) {
      debugPrint('Error disposing real-time notification service in dispose: $e');
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingScreen();
    }

    // Handle different authentication and profile completion states
    if (_isLoggedIn) {
      return const BottomNavigation();
    } else if (_profileStatus != null) {
      // User is authenticated but profile is incomplete
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        switch (_profileStatus!) {
          case ProfileCompletionStatus.needsEmailVerification:
            // This case is now unused but kept for compatibility
            return const BottomNavigation();
          case ProfileCompletionStatus.needsUserDetails:
            return UserDetailsScreen(
              userId: user.id,
              userEmail: user.email ?? '',
            );
          case ProfileCompletionStatus.needsProfileSetup:
            return ProfileSetupScreen(
              userId: user.id,
              userEmail: user.email ?? '',
            );
          case ProfileCompletionStatus.complete:
            // This shouldn't happen since _isLoggedIn should be true
            return const BottomNavigation();
        }
      }
    }

    // Default to auth screen
    return const AuthScreen();
  }
}

/// Reusable loading screen widget
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  static const Color _primaryColor = Color(0xFF233A63);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: _primaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(
                color: _primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
