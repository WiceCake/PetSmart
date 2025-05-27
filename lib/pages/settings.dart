import 'package:flutter/material.dart';
import 'package:pet_smart/auth/auth.dart';
import 'package:pet_smart/pages/setting/account_information.dart';
import 'package:pet_smart/pages/setting/address_book.dart';
import 'package:pet_smart/pages/setting/country.dart';
import 'package:pet_smart/pages/setting/language.dart';
import 'package:pet_smart/pages/setting/policies.dart';
import 'package:pet_smart/pages/setting/help.dart';
import 'package:pet_smart/pages/setting/feedback.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
                ? Colors.red.withOpacity(0.1)
                : primaryBlue.withOpacity(0.08),
            highlightColor: Colors.transparent,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
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
                            ? Colors.red.withOpacity(0.1)
                            : primaryBlue.withOpacity(0.1),
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
        shadowColor: Colors.grey.withOpacity(0.1),
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
                  // TODO: Navigate to notifications settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications settings coming soon')),
                  );
                },
              ),
              settingCard(
                icon: Icons.privacy_tip_outlined,
                child: const Text(
                  'Privacy & Security',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                onTap: () {
                  // TODO: Navigate to privacy settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy & Security settings coming soon')),
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
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _logout(context);
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> _logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
