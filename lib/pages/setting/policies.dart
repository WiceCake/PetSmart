import 'package:flutter/material.dart';

class PoliciesPage extends StatelessWidget {
  const PoliciesPage({super.key});

  @override
  Widget build(BuildContext context) {
    const mainBlue = Color(0xFF3B4CCA);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Policies',
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
            _buildPolicyCard(
              context,
              title: 'Terms of Service',
              description: 'Learn about the terms and conditions for using PetSmart services',
              icon: Icons.description,
              onTap: () => _navigateToPolicyDetail(
                context,
                title: 'Terms of Service',
                content: _termsOfServiceContent,
                mainBlue: mainBlue,
              ),
              mainBlue: mainBlue,
            ),
            
            _buildPolicyCard(
              context,
              title: 'Privacy Policy',
              description: 'How we collect, use, and protect your personal information',
              icon: Icons.privacy_tip,
              onTap: () => _navigateToPolicyDetail(
                context,
                title: 'Privacy Policy',
                content: _privacyPolicyContent,
                mainBlue: mainBlue,
              ),
              mainBlue: mainBlue,
            ),
            
            _buildPolicyCard(
              context,
              title: 'Cookie Policy',
              description: 'Learn how we use cookies and similar technologies',
              icon: Icons.cookie,
              onTap: () => _navigateToPolicyDetail(
                context,
                title: 'Cookie Policy',
                content: _cookiePolicyContent,
                mainBlue: mainBlue,
              ),
              mainBlue: mainBlue,
            ),
            
            _buildPolicyCard(
              context,
              title: 'Community Guidelines',
              description: 'Standards for interacting with our community',
              icon: Icons.people,
              onTap: () => _navigateToPolicyDetail(
                context,
                title: 'Community Guidelines',
                content: _communityGuidelinesContent,
                mainBlue: mainBlue,
              ),
              mainBlue: mainBlue,
            ),
            
            _buildPolicyCard(
              context,
              title: 'Refund Policy',
              description: 'Our policies for returns and refunds',
              icon: Icons.monetization_on,
              onTap: () => _navigateToPolicyDetail(
                context,
                title: 'Refund Policy',
                content: _refundPolicyContent,
                mainBlue: mainBlue,
              ),
              mainBlue: mainBlue,
            ),
            
            _buildPolicyCard(
              context,
              title: 'Shipping Policy',
              description: 'Information about our shipping methods and timeframes',
              icon: Icons.local_shipping,
              onTap: () => _navigateToPolicyDetail(
                context,
                title: 'Shipping Policy',
                content: _shippingPolicyContent,
                mainBlue: mainBlue,
              ),
              mainBlue: mainBlue,
            ),
            
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Last Updated: June 1, 2023',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    required Color mainBlue,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8EAF6),
          child: Icon(
            icon,
            color: mainBlue,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(description),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _navigateToPolicyDetail(
    BuildContext context, {
    required String title,
    required List<Map<String, dynamic>> content,
    required Color mainBlue,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PolicyDetailPage(
          title: title,
          content: content,
          mainBlue: mainBlue,
        ),
      ),
    );
  }

  // Sample policy content
  static const List<Map<String, dynamic>> _termsOfServiceContent = [
    {
      'title': 'Acceptance of Terms',
      'content':
          'By accessing and using the PetSmart app, you accept and agree to be bound by the terms and provisions of this agreement. Additionally, when using the app\'s particular services, you shall be subject to any posted guidelines or rules applicable to such services.',
    },
    {
      'title': 'User Account',
      'content':
          'If you use this app, you are responsible for maintaining the confidentiality of your account and password and for restricting access to your computer. You agree to accept responsibility for all activities that occur under your account or password.',
    },
    {
      'title': 'Service Availability',
      'content':
          'PetSmart does not guarantee that the app or any content, service or feature of the app will be error-free or uninterrupted, or that any defects will be corrected, or that your use of the app will provide specific results.',
    },
    {
      'title': 'Modification of Terms',
      'content':
          'PetSmart reserves the right to change these terms and conditions at any time. Your continued use of the app following the posting of changes will mean that you accept and agree to the changes.',
    },
  ];

  static const List<Map<String, dynamic>> _privacyPolicyContent = [
    {
      'title': 'Information Collection',
      'content':
          'We collect personal information such as your name, email address, phone number, and pet details when you create an account or use our services. We also collect information about your device and how you use our app.',
    },
    {
      'title': 'Use of Information',
      'content':
          'We use the information we collect to provide and improve our services, communicate with you, and personalize your experience. We may also use your information to send you marketing communications about our products and services.',
    },
    {
      'title': 'Information Sharing',
      'content':
          'We do not sell your personal information to third parties. We may share your information with service providers who help us operate our business, or as required by law.',
    },
    {
      'title': 'Your Choices',
      'content':
          'You can update your account information at any time. You can also opt out of receiving marketing communications from us by following the unsubscribe instructions in our emails.',
    },
  ];

  static const List<Map<String, dynamic>> _cookiePolicyContent = [
    {
      'title': 'What Are Cookies',
      'content':
          'Cookies are small text files that are placed on your device when you visit our app. They are widely used to make websites and apps work more efficiently and provide information to the owners.',
    },
    {
      'title': 'How We Use Cookies',
      'content':
          'We use cookies to understand how you use our app, remember your preferences, and improve your experience. We also use cookies for analytics purposes to track user activity and understand how our app is being used.',
    },
    {
      'title': 'Your Cookie Choices',
      'content':
          'Most web browsers allow you to control cookies through their settings preferences. However, limiting the ability to use cookies may affect your user experience.',
    },
  ];

  static const List<Map<String, dynamic>> _communityGuidelinesContent = [
    {
      'title': 'Respectful Behavior',
      'content':
          'Treat others with respect. Do not engage in harassment, bullying, or hate speech. Respect the privacy of others and do not share their personal information without permission.',
    },
    {
      'title': 'Appropriate Content',
      'content':
          'Do not post content that is illegal, harmful, threatening, abusive, harassing, tortious, defamatory, vulgar, obscene, libelous, invasive of another\'s privacy, or otherwise objectionable.',
    },
    {
      'title': 'Honest Communications',
      'content':
          'Do not impersonate any person or entity or falsely state or otherwise misrepresent your affiliation with a person or entity. Provide accurate and truthful information.',
    },
  ];

  static const List<Map<String, dynamic>> _refundPolicyContent = [
    {
      'title': 'Return Eligibility',
      'content':
          'Products must be returned within 30 days of purchase. They must be in their original condition and packaging. Certain items, such as personalized products, cannot be returned.',
    },
    {
      'title': 'Refund Process',
      'content':
          'Once your return is received and inspected, we will send you an email to notify you that we have received your returned item. We will also notify you of the approval or rejection of your refund.',
    },
    {
      'title': 'Service Cancellations',
      'content':
          'For service appointments, cancellations made at least 24 hours before the scheduled time will receive a full refund. Cancellations made less than 24 hours before may be subject to a cancellation fee.',
    },
  ];

  static const List<Map<String, dynamic>> _shippingPolicyContent = [
    {
      'title': 'Shipping Methods',
      'content':
          'We offer standard shipping (5-7 business days), express shipping (2-3 business days), and same-day delivery for selected areas. Shipping costs are calculated based on the delivery method and destination.',
    },
    {
      'title': 'Delivery Timeframes',
      'content':
          'Orders are typically processed within 1-2 business days. Shipping times are estimated and not guaranteed. Delays may occur due to weather, high order volumes, or other unforeseen circumstances.',
    },
    {
      'title': 'Order Tracking',
      'content':
          'Once your order ships, you will receive a shipping confirmation email with a tracking number. You can track your order through our app or website.',
    },
  ];
}

class _PolicyDetailPage extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> content;
  final Color mainBlue;

  const _PolicyDetailPage({
    required this.title,
    required this.content,
    required this.mainBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            color: mainBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: mainBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: mainBlue,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Last Updated: June 1, 2023',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ...content.map((section) => _buildSection(section)),
            const SizedBox(height: 24),
            const Text(
              'If you have any questions about our policies, please contact us at support@petsmart.com',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(Map<String, dynamic> section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section['title'],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          section['content'],
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
