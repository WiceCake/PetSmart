import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pet_smart/pages/setting/account_information.dart';
import 'package:pet_smart/pages/setting/address_book.dart';
import 'package:pet_smart/pages/setting/country.dart';
import 'package:pet_smart/pages/setting/language.dart';
import 'package:pet_smart/pages/setting/policies.dart';
import 'package:pet_smart/pages/setting/help.dart';
import 'package:pet_smart/pages/setting/feedback.dart';
import 'package:pet_smart/pages/setting/notifications.dart';
import 'package:pet_smart/pages/setting/privacy_security.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_smart/components/enhanced_dialogs.dart';
import 'package:pet_smart/components/enhanced_toasts.dart';
import 'package:pet_smart/main.dart';

// Color constants
const Color primaryRed = Color(0xFFE57373);
const Color primaryBlue = Color(0xFF233A63);   // PetSmart brand blue
const Color accentRed = Color(0xFFEF5350);
const Color backgroundColor = Color(0xFFF8F9FA);
const Color cardColor = Colors.white;

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget settingCard({
      required Widget child,
      VoidCallback? onTap,
      IconData? icon,
      Color? iconColor,
      bool isDestructive = false,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            splashColor: isDestructive
                ? Colors.red.withValues(alpha: 0.1)
                : primaryBlue.withValues(alpha: 0.08),
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
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (icon != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDestructive
                            ? Colors.red.withValues(alpha: 0.1)
                            : primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: isDestructive ? Colors.red[600] : primaryBlue,
                        size: 20,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(child: child),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget sectionHeader(String title) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.grey.withValues(alpha: 0.1),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Section
              sectionHeader('ACCOUNT'),
              settingCard(
                icon: Icons.person_outline,
                child: const Text(
                  'Account Information',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AccountInformationPage()),
                  );
                },
              ),
              settingCard(
                icon: Icons.location_on_outlined,
                child: const Text(
                  'Address Book',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddressBookPage()),
                  );
                },
              ),
              settingCard(
                icon: Icons.notifications_outlined,
                child: const Text(
                  'Notifications',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsPage()),
                  );
                },
              ),

              // Privacy & Security Section
              sectionHeader('PRIVACY & SECURITY'),
              settingCard(
                icon: Icons.security_outlined,
                child: const Text(
                  'Privacy & Security',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PrivacySecurityPage()),
                  );
                },
              ),

              // Preferences Section
              sectionHeader('PREFERENCES'),
              settingCard(
                icon: Icons.flag_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Country',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Philippines',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CountryPage()),
                  );
                },
              ),
              settingCard(
                icon: Icons.language_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Language',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'English',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LanguagePage()),
                  );
                },
              ),

              // Support Section
              sectionHeader('SUPPORT'),
              settingCard(
                icon: Icons.policy_outlined,
                child: const Text(
                  'Policies',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PoliciesPage()),
                  );
                },
              ),
              settingCard(
                icon: Icons.help_outline,
                child: const Text(
                  'Help & Support',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HelpPage()),
                  );
                },
              ),
              settingCard(
                icon: Icons.feedback_outlined,
                child: const Text(
                  'Feedback',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FeedbackPage()),
                  );
                },
              ),

              // Logout Section
              sectionHeader('ACCOUNT ACTIONS'),
              settingCard(
                icon: Icons.logout,
                isDestructive: true,
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                onTap: () => _showLogoutDialog(context),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _showLogoutDialog(BuildContext context) async {
    // Show confirmation dialog first
    final confirmed = await EnhancedDialogs.showLogoutConfirmation(context);

    if (confirmed == true && context.mounted) {
      // Show the loading dialog and get the dismissal function
      final dismissDialog = await EnhancedDialogs.showLoadingDialog(context, message: 'Logging out...');

      // Store context before async operation
      if (context.mounted) {
        // Perform logout with the dismissal function
        await _logout(context, dismissDialog);
      }
    }
  }

  static Future<void> _logout(BuildContext context, VoidCallback dismissDialog) async {
    bool dialogDismissed = false;

    try {
      debugPrint('🔐 Starting logout process...');

      // Perform logout with timeout
      await Future.any([
        Supabase.instance.client.auth.signOut(),
        Future.delayed(const Duration(seconds: 8), () => throw TimeoutException('Logout timeout', const Duration(seconds: 8))),
      ]);

      debugPrint('🔐 Logout successful - Supabase signOut completed');

      // Dismiss the loading dialog first using the dismissal function
      if (!dialogDismissed) {
        try {
          dismissDialog();
          dialogDismissed = true;
          debugPrint('🔐 Loading dialog dismissed using dismissal function');
        } catch (popError) {
          debugPrint('🔐 Error dismissing dialog with dismissal function: $popError');
          // Fallback to context-based dismissal
          if (context.mounted) {
            try {
              Navigator.of(context).pop();
              dialogDismissed = true;
              debugPrint('🔐 Loading dialog dismissed using context fallback');
            } catch (contextPopError) {
              debugPrint('🔐 Error dismissing dialog with context: $contextPopError');
            }
          }
        }
      }

      // Small delay to ensure the dialog is dismissed before navigation
      await Future.delayed(const Duration(milliseconds: 300));

      // Navigate to auth screen - use pushNamedAndRemoveUntil to clear the entire stack
      if (context.mounted) {
        debugPrint('🔐 Navigating to auth screen...');
        try {
          Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
          debugPrint('🔐 Navigation completed successfully');
        } catch (navError) {
          debugPrint('🔐 Navigation error: $navError');
          // Fallback: try direct navigation to AuthWrapper
          try {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const AuthWrapper()),
              (route) => false,
            );
            debugPrint('🔐 Fallback navigation completed');
          } catch (fallbackError) {
            debugPrint('🔐 Fallback navigation error: $fallbackError');
          }
        }
      }

    } catch (e) {
      debugPrint('🔐 Logout error: $e');

      // Ensure the loading dialog is dismissed
      if (!dialogDismissed) {
        try {
          dismissDialog();
          dialogDismissed = true;
          debugPrint('🔐 Loading dialog dismissed after error using dismissal function');
        } catch (popError) {
          debugPrint('🔐 Error dismissing dialog with dismissal function: $popError');
          // Fallback to context-based dismissal
          if (context.mounted) {
            try {
              Navigator.of(context).pop();
              dialogDismissed = true;
              debugPrint('🔐 Loading dialog dismissed after error using context fallback');
            } catch (contextPopError) {
              debugPrint('🔐 Error dismissing dialog with context: $contextPopError');
            }
          }
        }
      }

      // Small delay before showing error
      await Future.delayed(const Duration(milliseconds: 100));

      // Show error message
      if (context.mounted) {
        EnhancedToasts.showError(
          context,
          'Logout failed: ${e.toString()}',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }
}
