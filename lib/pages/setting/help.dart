import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    const mainBlue = Color(0xFF3B4CCA);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Help',
          style: TextStyle(
            color: mainBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: mainBlue),
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
              mainBlue: mainBlue,
              children: [
                _buildExpandableQuestion(
                  question: 'How do I reset my password?',
                  answer:
                      'To reset your password, go to the login screen and tap on "Forgot Password". Follow the instructions sent to your email to create a new password.',
                  mainBlue: mainBlue,
                ),
                _buildExpandableQuestion(
                  question: 'How do I update my pet\'s information?',
                  answer:
                      'You can update your pet\'s information in the Account section. Tap on your pet\'s profile and select "Edit" to modify details such as weight, age, or medical information.',
                  mainBlue: mainBlue,
                ),
                _buildExpandableQuestion(
                  question: 'Where can I see my order history?',
                  answer:
                      'Your order history can be found in the Account section under "Order History". There, you can view details of past purchases and track current orders.',
                  mainBlue: mainBlue,
                ),
                _buildExpandableQuestion(
                  question: 'How do I schedule a grooming appointment?',
                  answer:
                      'To schedule a grooming appointment, go to the Services tab, select "Grooming", choose your preferred date and time, and follow the booking instructions.',
                  mainBlue: mainBlue,
                ),
                _buildExpandableQuestion(
                  question: 'What payment methods do you accept?',
                  answer:
                      'We accept all major credit cards (Visa, Mastercard, American Express), PayPal, and PetSmart gift cards. For in-store purchases, cash and debit cards are also accepted.',
                  mainBlue: mainBlue,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Troubleshooting',
              mainBlue: mainBlue,
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
                  mainBlue: mainBlue,
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
                  mainBlue: mainBlue,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children, required Color mainBlue}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: mainBlue,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildExpandableQuestion({required String question, required String answer, required Color mainBlue}) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        question,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      backgroundColor: Colors.white,
      collapsedBackgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: Text(
            answer,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTroubleshootingCard({
    required String title,
    required List<String> items,
    required Color mainBlue,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
              fontWeight: FontWeight.bold,
              color: mainBlue,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
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