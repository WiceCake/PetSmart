import 'package:flutter/material.dart';
import 'package:pet_smart/auth/auth.dart';
import 'package:pet_smart/auth/user_details.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _error;

  Future<bool> _checkEmailExists(String email) async {
    try {
      final supabase = Supabase.instance.client;

      // Check if email exists in auth.users table by attempting to sign in with a dummy password
      // This is a workaround since Supabase doesn't provide a direct way to check email existence
      try {
        await supabase.auth.signInWithPassword(email: email, password: 'dummy_password_check');
        // If we reach here, the email exists but password is wrong
        return true;
      } catch (e) {
        String errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('invalid_credentials') || errorMessage.contains('invalid login credentials')) {
          // Email exists but password is wrong
          return true;
        } else if (errorMessage.contains('email not confirmed') || errorMessage.contains('email_not_confirmed')) {
          // Email exists but not confirmed
          return true;
        } else {
          // Email doesn't exist or other error
          return false;
        }
      }
    } catch (e) {
      // If there's any other error, assume email doesn't exist to allow registration attempt
      return false;
    }
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // Validation
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = "All fields are required.";
      });
      return;
    }
    if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email)) {
      setState(() {
        _isLoading = false;
        _error = "Please enter a valid email address.";
      });
      return;
    }
    if (password.length < 8) {
      setState(() {
        _isLoading = false;
        _error = "Password must be at least 8 characters long.";
      });
      return;
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password)) {
      setState(() {
        _isLoading = false;
        _error = "Password must contain at least one uppercase letter, one lowercase letter, and one number.";
      });
      return;
    }
    if (password != confirmPassword) {
      setState(() {
        _isLoading = false;
        _error = "Passwords do not match.";
      });
      return;
    }

    // Check if email already exists
    final emailExists = await _checkEmailExists(email);
    if (emailExists) {
      setState(() {
        _isLoading = false;
        _error = "An account with this email already exists. Please try logging in instead.";
      });
      return;
    }

    final supabase = Supabase.instance.client;
    try {
      final response = await supabase.auth.signUp(email: email, password: password);

      // Debug information (remove in production)
      // print('Registration response:');
      // print('User: ${response.user?.id}');
      // print('Session: ${response.session?.accessToken != null ? "Present" : "Null"}');

      if (response.user != null) {
        // Registration successful - proceed regardless of email confirmation
        if (!mounted) return;

        // Show success message and navigate
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.session != null
                ? 'Registration successful!'
                : 'Registration successful! Please verify your email when convenient.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to user details
        Navigator.of(context).push(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (context, animation, secondaryAnimation) => UserDetailsScreen(
              userId: response.user!.id,
              userEmail: response.user!.email ?? email,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      } else {
        setState(() {
          _error = "Registration failed. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        // Show a more user-friendly error if possible
        String errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('email') && errorMessage.contains('already')) {
          _error = "An account with this email already exists. Please try logging in instead.";
        } else if (errorMessage.contains('invalid_credentials')) {
          _error = "Invalid email or password format.";
        } else if (errorMessage.contains('weak_password')) {
          _error = "Password is too weak. Please choose a stronger password.";
        } else if (errorMessage.contains('network')) {
          _error = "Network error. Please check your connection and try again.";
        } else if (errorMessage.contains('anonymous_provider_disabled')) {
          _error = "Please enter a valid email and password.";
        } else {
          _error = "Registration failed. Please try again.";
        }
      });
    }
    setState(() {
      _isLoading = false;
    });
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
                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              transitionDuration: const Duration(milliseconds: 400),
                              pageBuilder: (context, animation, secondaryAnimation) => const AuthScreen(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                            ),
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
                  const Text(
                    'Create your Account',
                    style: TextStyle(
                      fontSize: 24,
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Email
                  _AnimatedInputField(
                    controller: emailController,
                    hintText: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  // Password
                  _AnimatedInputField(
                    controller: passwordController,
                    hintText: 'Password',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
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
                  const SizedBox(height: 14),
                  // Confirm Password
                  _AnimatedInputField(
                    controller: confirmPasswordController,
                    hintText: 'Confirm Password',
                    icon: Icons.lock_outline,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
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
                  // Register Button
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
                      onPressed: _isLoading ? null : _register,
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
                              'REGISTER',
                              style: TextStyle(fontSize: 18, letterSpacing: 1),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Already have an account? Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account?",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              transitionDuration: const Duration(milliseconds: 400),
                              pageBuilder: (context, animation, secondaryAnimation) => const AuthScreen(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        child: const Text(
                          "Log in",
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                          const SizedBox(height: 24),
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

class _AnimatedInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const _AnimatedInputField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
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
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: const Color(0xFF233A63)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}