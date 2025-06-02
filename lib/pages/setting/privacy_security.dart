import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_smart/components/enhanced_dialogs.dart';
import 'package:pet_smart/components/enhanced_toasts.dart';

// Color constants matching app design patterns
const Color primaryBlue = Color(0xFF233A63);   // Main primary color
const Color secondaryBlue = Color(0xFF3F51B5); // Secondary blue
const Color primaryRed = Color(0xFFE57373);    // Light coral red
const Color accentRed = Color(0xFFEF5350);     // Brighter red for emphasis
const Color backgroundColor = Color(0xFFF6F7FB); // Light background
const Color successGreen = Color(0xFF4CAF50);  // Success green
const Color warningOrange = Color(0xFFFF9800); // Warning orange
const Color cardColor = Colors.white;

class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({super.key});

  @override
  State<PrivacySecurityPage> createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  bool _isLoading = true;
  String? _error;

  // Privacy settings
  bool _profileVisibility = true;
  bool _dataSharingEnabled = false;
  bool _securityNotifications = true;

  // Security settings
  DateTime? _lastPasswordChange;

  // User info
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        setState(() {
          _isLoading = false;
          _error = 'User not logged in';
        });
        return;
      }

      _userEmail = user.email;

      // Fetch user privacy and security settings
      final response = await supabase
          .from('profiles')
          .select('profile_visibility, data_sharing_enabled, security_notifications, last_password_change')
          .eq('id', user.id)
          .single();

      setState(() {
        _profileVisibility = response['profile_visibility'] ?? true;
        _dataSharingEnabled = response['data_sharing_enabled'] ?? false;
        _securityNotifications = response['security_notifications'] ?? true;

        if (response['last_password_change'] != null) {
          _lastPasswordChange = DateTime.parse(response['last_password_change']);
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load settings: ${e.toString()}';
      });
    }
  }

  Future<void> _updatePrivacySetting(String field, bool value) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) return;

      await supabase.from('profiles').update({
        field: value,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      if (mounted) {
        EnhancedToasts.showPrivacySettingsUpdated(context);
      }
    } catch (e) {
      if (mounted) {
        EnhancedToasts.showError(
          context,
          'Failed to update privacy setting. Please try again.',
        );

        // Revert the UI change
        setState(() {
          switch (field) {
            case 'profile_visibility':
              _profileVisibility = !value;
              break;
            case 'data_sharing_enabled':
              _dataSharingEnabled = !value;
              break;
            case 'security_notifications':
              _securityNotifications = !value;
              break;
          }
        });
      }
    }
  }



  Future<void> _changePassword() async {
    if (_userEmail == null) return;

    final confirmed = await EnhancedDialogs.showPasswordChangeConfirmation(context);
    if (confirmed != true) return;

    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.resetPasswordForEmail(_userEmail!);

      // Update last password change timestamp
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('profiles').update({
          'last_password_change': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);

        setState(() {
          _lastPasswordChange = DateTime.now();
        });
      }

      if (mounted) {
        EnhancedToasts.showPasswordResetSent(context, _userEmail!);
      }
    } catch (e) {
      if (mounted) {
        EnhancedToasts.showError(
          context,
          'Failed to send password reset email. Please try again.',
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await EnhancedDialogs.showAccountDeletionConfirmation(context);
    if (confirmed != true) return;

    try {
      // In a real implementation, you would call a backend service
      // Implement proper account deletion flow
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (mounted) {
          EnhancedToasts.showError(context, 'User not authenticated');
        }
        return;
      }

      // Delete user data from all tables
      await Future.wait([
        // Delete user's pets
        supabase.from('pets').delete().eq('user_id', user.id),
        // Delete user's appointments
        supabase.from('appointments').delete().eq('user_id', user.id),
        // Delete user's orders and order items
        supabase.from('orders').delete().eq('user_id', user.id),
        // Delete user's cart items
        supabase.from('cart_items').delete().eq('user_id', user.id),
        // Delete user's liked items
        supabase.from('liked_items').delete().eq('user_id', user.id),
        // Delete user's addresses
        supabase.from('addresses').delete().eq('user_id', user.id),
        // Delete user's feedback
        supabase.from('feedback').delete().eq('user_id', user.id),
        // Delete user's chat messages
        supabase.from('chat_messages').delete().eq('user_id', user.id),
        // Delete user's push tokens
        supabase.from('push_tokens').delete().eq('user_id', user.id),
        // Delete user profile
        supabase.from('profiles').delete().eq('id', user.id),
      ]);

      // Finally, delete the auth user
      await supabase.auth.admin.deleteUser(user.id);

      if (mounted) {
        EnhancedToasts.showAccountDeletionInitiated(context);
        // Navigate to login screen after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        EnhancedToasts.showError(
          context,
          'Failed to initiate account deletion. Please contact support.',
        );
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          splashColor: primaryBlue.withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Privacy & Security',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserSettings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Privacy Settings Section
                        _buildSectionHeader('PRIVACY SETTINGS'),
                        _buildPrivacySettings(),

                        // Security Settings Section
                        _buildSectionHeader('SECURITY SETTINGS'),
                        _buildSecuritySettings(),

                        // Account Actions Section
                        _buildSectionHeader('ACCOUNT ACTIONS'),
                        _buildAccountActions(),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildPrivacySettings() {
    return Column(
      children: [
        _buildSettingCard(
          child: Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                color: primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile Visibility',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _profileVisibility ? 'Public profile' : 'Private profile',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _profileVisibility,
                onChanged: (value) {
                  setState(() {
                    _profileVisibility = value;
                  });
                  _updatePrivacySetting('profile_visibility', value);
                },
                activeColor: primaryBlue,
                activeTrackColor: primaryBlue.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
        _buildSettingCard(
          child: Row(
            children: [
              Icon(
                Icons.share_outlined,
                color: primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Data Sharing',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => EnhancedDialogs.showDataSharingInfo(context),
                          child: Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _dataSharingEnabled ? 'Enabled for service improvement' : 'Disabled',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _dataSharingEnabled,
                onChanged: (value) {
                  setState(() {
                    _dataSharingEnabled = value;
                  });
                  _updatePrivacySetting('data_sharing_enabled', value);
                },
                activeColor: primaryBlue,
                activeTrackColor: primaryBlue.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
        _buildSettingCard(
          child: Row(
            children: [
              Icon(
                Icons.notifications_outlined,
                color: primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Security Notifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _securityNotifications ? 'Receive security alerts' : 'Security alerts disabled',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _securityNotifications,
                onChanged: (value) {
                  setState(() {
                    _securityNotifications = value;
                  });
                  _updatePrivacySetting('security_notifications', value);
                },
                activeColor: primaryBlue,
                activeTrackColor: primaryBlue.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySettings() {
    return Column(
      children: [
        _buildSettingCard(
          onTap: _changePassword,
          child: Row(
            children: [
              Icon(
                Icons.lock_reset_outlined,
                color: primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _lastPasswordChange != null
                          ? 'Last changed ${_formatDate(_lastPasswordChange!)}'
                          : 'Tap to change your password',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
        _buildSettingCard(
          child: Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: _getSecurityStatusColor(),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Security Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getSecurityStatusText(),
                      style: TextStyle(
                        fontSize: 13,
                        color: _getSecurityStatusColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountActions() {
    return Column(
      children: [
        _buildSettingCard(
          onTap: _deleteAccount,
          child: Row(
            children: [
              Icon(
                Icons.delete_forever_outlined,
                color: accentRed,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delete Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Permanently delete your account and all data',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }

  Color _getSecurityStatusColor() {
    // Simple security scoring based on available features
    if (_securityNotifications && _lastPasswordChange != null) {
      final daysSincePasswordChange = DateTime.now().difference(_lastPasswordChange!).inDays;
      if (daysSincePasswordChange < 90) {
        return successGreen;
      } else if (daysSincePasswordChange < 180) {
        return warningOrange;
      }
    }
    return accentRed;
  }

  String _getSecurityStatusText() {
    if (_securityNotifications && _lastPasswordChange != null) {
      final daysSincePasswordChange = DateTime.now().difference(_lastPasswordChange!).inDays;
      if (daysSincePasswordChange < 90) {
        return 'Good - Account is secure';
      } else if (daysSincePasswordChange < 180) {
        return 'Fair - Consider updating password';
      }
    }
    return 'Needs attention - Update security settings';
  }
}
