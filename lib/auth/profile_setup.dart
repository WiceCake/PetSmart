import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_smart/services/profile_completion_service.dart';
import 'package:pet_smart/components/enhanced_dialogs.dart';
import 'package:pet_smart/components/enhanced_toasts.dart';
import 'dart:typed_data';

/// Screen for setting up user profile after registration
class ProfileSetupScreen extends StatefulWidget {
  final String? userId;
  final String? userEmail;

  const ProfileSetupScreen({
    super.key,
    this.userId,
    this.userEmail,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _profileImageBytes;
  String? _profileImageUrl;
  bool _isLoading = false;
  String? _error;

  // Constants
  static const Color _primaryColor = Color(0xFF233A63);
  static const Color _accentColor = Color(0xFFE57373);
  static const int _minUsernameLength = 3;
  static const int _imageQuality = 80;

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  /// Pick image from gallery for profile picture
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: _imageQuality,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _profileImageBytes = bytes;
          _error = null; // Clear any previous errors
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to pick image. Please try again.';
      });
      debugPrint('Image picker error: $e');
    }
  }

  Future<String?> _uploadProfileImage(Uint8List bytes, String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Try to upload the image
      await supabase.storage
          .from('profile-pictures')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      // Get the public URL
      final publicUrl = supabase.storage
          .from('profile-pictures')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      // print('Upload error: $e');
      // If upload fails, return null so the profile can still be saved without image
      return null;
    }
  }

  /// Validate user inputs before saving profile
  bool _validateInputs() {
    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      setState(() {
        _error = 'Username is required.';
      });
      return false;
    }

    if (username.length < _minUsernameLength) {
      setState(() {
        _error = 'Username must be at least $_minUsernameLength characters long.';
      });
      return false;
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      setState(() {
        _error = 'Username can only contain letters, numbers, and underscores.';
      });
      return false;
    }

    // Validate that profile picture is selected
    if (_profileImageBytes == null && _profileImageUrl == null) {
      setState(() {
        _error = 'Please select a profile picture.';
      });
      return false;
    }

    return true;
  }

  /// Handle cancellation of registration process
  Future<void> _handleCancellation() async {
    if (!mounted) return;

    final confirmed = await EnhancedDialogs.showRegistrationCancellation(context);

    if (confirmed == true && mounted) {
      // Show loading dialog and get dismissal function
      final dismissDialog = await EnhancedDialogs.showLoadingDialog(context, message: 'Cancelling registration...');

      try {
        // Delete the incomplete registration
        final success = await ProfileCompletionService().deleteIncompleteRegistration();

        if (mounted) {
          // Dismiss loading dialog
          dismissDialog();

          if (success) {
            // Show success toast
            EnhancedToasts.showRegistrationCancelled(context);

            // Small delay to let the toast show before navigation
            await Future.delayed(const Duration(milliseconds: 500));

            if (mounted) {
              // Navigate back to auth wrapper - this will properly handle the auth state
              Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
            }
          } else {
            // Show error toast
            EnhancedToasts.showError(
              context,
              'Failed to cancel registration. Please try again.',
            );
          }
        }
      } catch (e) {
        debugPrint('Error during registration cancellation: $e');
        if (mounted) {
          // Dismiss loading dialog
          dismissDialog();

          // Show error toast
          EnhancedToasts.showError(
            context,
            'An error occurred while cancelling registration. Please try again.',
          );
        }
      }
    }
  }

  /// Save profile data to database and navigate to main app
  Future<void> _finishProfile() async {
    setState(() {
      _error = null;
    });

    if (!_validateInputs()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    // Use passed userId if available, otherwise get from current user
    String? userId = widget.userId ?? user?.id;

    if (userId == null) {
      setState(() {
        _isLoading = false;
        _error = 'User information not found. Please try registering again.';
      });
      return;
    }

    String? uploadedImageUrl = _profileImageUrl;

    // Upload profile image (required)
    if (_profileImageBytes != null) {
      uploadedImageUrl = await _uploadProfileImage(_profileImageBytes!, userId);
      if (uploadedImageUrl == null) {
        // Profile picture upload failed - this is now an error since it's required
        setState(() {
          _isLoading = false;
          _error = 'Failed to upload profile picture. Please check your internet connection and try again.';
        });
        return;
      }
    }

    try {
      // Use upsert to handle both insert and update cases
      final profileData = {
        'id': userId,
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'profile_pic': uploadedImageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase.from('profiles').upsert(profileData);
      debugPrint('Profile saved successfully!');

    } catch (e) {
      debugPrint('Profile save error: $e');
      setState(() {
        _isLoading = false;
        _error = 'Failed to update profile. Please check your internet connection and try again.';
      });
      return;
    }

    if (!mounted) return;

    // Show success toast
    EnhancedToasts.showSuccess(
      context,
      'Profile setup completed successfully! Welcome to PetSmart!',
    );

    // Small delay to let the toast show before navigation
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      // Navigate back to root - AuthWrapper will handle the navigation
      Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Show cancellation dialog when back navigation is attempted
          await _handleCancellation();
        }
      },
      child: Scaffold(
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
              // Custom App Bar with Cancel Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48), // Spacer for centering
                    const Text(
                      'Profile Setup',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
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
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: _handleCancellation,
                        tooltip: 'Cancel Registration',
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
                          // Title Text
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Set up your profile',
                              style: TextStyle(
                                fontSize: 24,
                                color: _primaryColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundColor: const Color(0xFFF2F2F2),
                            backgroundImage: _profileImageBytes != null
                                ? MemoryImage(_profileImageBytes!)
                                : null,
                            child: _profileImageBytes == null
                                ? Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _primaryColor.withValues(alpha: 0.2),
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 32,
                                      color: _primaryColor,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _accentColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Profile picture label
                  Text(
                    'Profile Picture *',
                    style: TextStyle(
                      color: _primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _AnimatedInputField(
                    controller: _usernameController,
                    hintText: 'Username *',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 14),
                  // Bio section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: _primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Bio (Optional)',
                              style: TextStyle(
                                color: _primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _bioController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Tell us about yourself and your pets...',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _isLoading ? null : _finishProfile,
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
                              'FINISH',
                              style: TextStyle(fontSize: 18, letterSpacing: 1),
                            ),
                    ),
                  ),
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
      ),
    );
  }
}

/// Custom animated input field widget for profile setup
class _AnimatedInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;

  const _AnimatedInputField({
    required this.controller,
    required this.hintText,
    required this.icon,
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
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: const Color(0xFF233A63)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }
}