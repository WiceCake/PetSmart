import 'package:flutter/material.dart';
import 'package:pet_smart/auth/auth.dart';
import 'package:pet_smart/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _error = null;
      _isLoading = true;
    });

    // Validate inputs
    if (emailController.text.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Please enter your email address.';
      });
      return;
    }

    if (passwordController.text.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Please enter your password.';
      });
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text.trim())) {
      setState(() {
        _isLoading = false;
        _error = 'Please enter a valid email address.';
      });
      return;
    }

    final supabase = Supabase.instance.client;

    try {
      // Check if Supabase is properly configured
      if (!AppConfig.isConfigured()) {
        setState(() {
          _isLoading = false;
          _error = 'App configuration error. Please contact support.';
        });
        return;
      }

      // First, ensure any existing session is cleared (for release mode)
      try {
        await supabase.auth.signOut();
        // Small delay to ensure signout is processed
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        // Ignore signout errors - user might not be logged in
        debugPrint('Signout before login (expected): $e');
      }

      final response = await supabase.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (response.user != null && response.session != null) {
        // Login successful
        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful! Welcome back.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Small delay to ensure session is properly set
        await Future.delayed(const Duration(milliseconds: 300));

        // Navigate back to root - AuthWrapper will handle the navigation
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
        }
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Login failed. Please check your credentials.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        // Handle specific Supabase auth errors
        String errorMessage = e.toString().toLowerCase();

        debugPrint('Login error: $e');
        debugPrint('Error type: ${e.runtimeType}');

        if (errorMessage.contains('invalid login credentials') ||
            errorMessage.contains('invalid_credentials')) {
          _error = 'Invalid email or password. Please try again.';
        } else if (errorMessage.contains('email not confirmed')) {
          _error = 'Please verify your email address before logging in.';
        } else if (errorMessage.contains('too many requests')) {
          _error = 'Too many login attempts. Please try again later.';
        } else if (errorMessage.contains('session_not_found') ||
                   errorMessage.contains('user_not_found')) {
          _error = 'Invalid email or password. Please try again.';
        } else if (errorMessage.contains('network') ||
                   errorMessage.contains('connection') ||
                   errorMessage.contains('socket') ||
                   errorMessage.contains('timeout') ||
                   errorMessage.contains('host') ||
                   errorMessage.contains('dns') ||
                   errorMessage.contains('ssl') ||
                   errorMessage.contains('certificate')) {
          _error = 'Network error. Please check your internet connection and try again.';
        } else if (errorMessage.contains('permission') ||
                   errorMessage.contains('cleartext') ||
                   errorMessage.contains('security')) {
          _error = 'Network security error. Please try again or contact support.';
        } else if (errorMessage.contains('format') ||
                   errorMessage.contains('parse') ||
                   errorMessage.contains('json')) {
          _error = 'Server response error. Please try again later.';
        } else {
          // For release mode, provide more specific error information
          if (const bool.fromEnvironment('dart.vm.product')) {
            _error = 'Login failed. Please check your internet connection and try again.';
          } else {
            _error = 'Login failed: ${e.toString()}';
          }
        }
      });
    }
  }

  Future<void> _forgotPassword() async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.resetPasswordForEmail(emailController.text.trim());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent! Check your inbox.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send reset email. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF233A63);
    const accentColor = Color(0xFFE57373);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[50]!,
              Colors.white,
              Colors.grey[50]!,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: primaryColor),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const AuthScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Main Content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo Container
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/petsmart_word.png',
                              height: 80,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 80,
                                  width: 160,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.pets, size: 32, color: Colors.grey[600]),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 32),
                  // Welcome text
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Login to your Account",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Email Field
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined, color: primaryColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Password Field
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline, color: primaryColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Remember Me & Forgot Password
                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        activeColor: accentColor,
                        onChanged: (value) {
                          setState(() {
                            rememberMe = value ?? false;
                          });
                        },
                      ),
                      const Text(
                        "Remember Me",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _forgotPassword,
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'LOGIN',
                              style: TextStyle(fontSize: 18, letterSpacing: 1),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Divider with text
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(
                          color: Colors.black12,
                          thickness: 1,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        child: const Text(
                          "or sign in with",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(
                          color: Colors.black12,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Social Icons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialIconButton(
                        asset: 'assets/google-plus.png',
                        onTap: () {
                          // TODO: Implement Google login
                        },
                      ),
                      const SizedBox(width: 32),
                      _SocialIconButton(
                        asset: 'assets/facebook.png',
                        onTap: () {
                          // TODO: Implement Facebook login
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Sign up prompt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const AuthScreen()),
                          );
                        },
                        child: const Text(
                          "Sign up",
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialIconButton extends StatefulWidget {
  final String asset;
  final VoidCallback onTap;

  const _SocialIconButton({
    required this.asset,
    required this.onTap,
  });

  @override
  State<_SocialIconButton> createState() => _SocialIconButtonState();
}

class _SocialIconButtonState extends State<_SocialIconButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.92);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            border: Border.all(
              color: Colors.grey.shade200,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              widget.asset,
              height: 28,
              width: 28,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
