import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF233A63);   // PetSmart brand blue
    const backgroundColor = Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.grey.withValues(alpha: 0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'Frequently Asked Questions',
              primaryBlue: primaryBlue,
              children: [
                _buildExpandableQuestion(
                  question: 'How do I reset my password?',
                  answer:
                      'To reset your password, go to the login screen and tap on "Forgot Password". Follow the instructions sent to your email to create a new password.',
                  primaryBlue: primaryBlue,
                ),
                _buildExpandableQuestion(
                  question: 'How do I update my pet\'s information?',
                  answer:
                      'You can update your pet\'s information in the Account section. Tap on your pet\'s profile and select "Edit" to modify details such as weight, age, or medical information.',
                  primaryBlue: primaryBlue,
                ),
                _buildExpandableQuestion(
                  question: 'Where can I see my order history?',
                  answer:
                      'Your order history can be found in the Account section under "Order History". There, you can view details of past purchases and track current orders.',
                  primaryBlue: primaryBlue,
                ),
                _buildExpandableQuestion(
                  question: 'How do I schedule a grooming appointment?',
                  answer:
                      'To schedule a grooming appointment, go to the Services tab, select "Grooming", choose your preferred date and time, and follow the booking instructions.',
                  primaryBlue: primaryBlue,
                ),
                _buildExpandableQuestion(
                  question: 'What payment methods do you accept?',
                  answer:
                      'We accept all major credit cards (Visa, Mastercard, American Express), PayPal, and PetSmart gift cards. For in-store purchases, cash and debit cards are also accepted.',
                  primaryBlue: primaryBlue,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Troubleshooting',
              primaryBlue: primaryBlue,
              children: [
                _buildTroubleshootingCard(
                  title: 'App Issues',
                  items: [
                    'Force close and restart the app',
                    'Ensure you have the latest version installed',
                    'Clear app cache in your device settings',
                    'Check your internet connection',
                    'Uninstall and reinstall the app',
                  ],
                  primaryBlue: primaryBlue,
                ),
                _buildTroubleshootingCard(
                  title: 'Payment Issues',
                  items: [
                    'Verify your payment information is up-to-date',
                    'Check with your bank for any payment restrictions',
                    'Try a different payment method',
                    'Clear cookies if using the web version',
                    'Contact customer support if problems persist',
                  ],
                  primaryBlue: primaryBlue,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children, required Color primaryBlue}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: primaryBlue,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildExpandableQuestion({required String question, required String answer, required Color primaryBlue}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingCard({
    required String title,
    required List<String> items,
    required Color primaryBlue,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6, right: 8),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}