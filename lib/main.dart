import 'package:flutter/material.dart';
import 'package:pet_smart/auth/auth.dart';
import 'package:pet_smart/components/nav_bar.dart';
import 'package:pet_smart/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _showSplash = true;

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF233A63),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: _showSplash ? const SplashScreen() : const AuthWrapper(),
      routes: {
        '/auth': (context) => const AuthWrapper(),
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

  static const Duration _timeoutDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    debugPrint('🔐 AuthWrapper: Initializing authentication check');
    _checkAuthStatus();
    _setupAuthListener();
  }

  /// Setup authentication state listener for real-time updates
  void _setupAuthListener() {
    if (AppConfig.isConfigured()) {
      try {
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
          final session = data.session;
          final isLoggedIn = session != null;

          debugPrint('Auth state changed - User logged in: $isLoggedIn');

          if (mounted) {
            setState(() {
              _isLoggedIn = isLoggedIn;
              _isLoading = false;
            });
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
      for (int attempt = 0; attempt < 5; attempt++) {
        try {
          final session = Supabase.instance.client.auth.currentSession;
          isLoggedIn = session != null;

          if (isLoggedIn) {
            debugPrint('Auth check completed - User logged in: true');
            debugPrint('Session expires at: ${session.expiresAt}');

            // Verify session is not expired
            final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            if (session.expiresAt != null && session.expiresAt! <= now) {
              debugPrint('Session expired, treating as logged out');
              isLoggedIn = false;
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
      _updateAuthState(isLoggedIn: isLoggedIn);

    } catch (e) {
      debugPrint('Critical error during auth check: $e');
      _updateAuthState(isLoggedIn: false);
    }

    // Failsafe timeout
    _setFailsafeTimeout();
  }

  /// Update authentication state if widget is still mounted
  void _updateAuthState({required bool isLoggedIn}) {
    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingScreen();
    }

    if (_isLoggedIn) {
      return const BottomNavigation();
    } else {
      return const AuthScreen();
    }
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
