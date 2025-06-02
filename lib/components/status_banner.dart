import 'package:flutter/material.dart';

// Color constants matching app design patterns
const Color primaryBlue = Color(0xFF233A63);   // Main primary color
const Color secondaryBlue = Color(0xFF3F51B5); // Secondary blue
const Color primaryRed = Color(0xFFE57373);    // Light coral red
const Color accentRed = Color(0xFFEF5350);     // Brighter red for emphasis
const Color backgroundColor = Color(0xFFF6F7FB); // Light background
const Color successGreen = Color(0xFF4CAF50);  // Success green

// Enum for different status types
enum StatusType {
  success,
  error,
  warning,
  info,
}

class CustomConfirmationPage extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final IconData icon;
  final Color iconColor;
  final StatusType statusType;

  const CustomConfirmationPage({
    super.key,
    this.title = "Successfully",
    this.message = "The shop has already received your schedule.",
    this.buttonText = "Back to home page",
    this.icon = Icons.check_circle,
    this.iconColor = successGreen,
    this.statusType = StatusType.success,
  });

  // Factory constructors for common status types
  factory CustomConfirmationPage.success({
    String title = "Success!",
    String message = "Operation completed successfully.",
    String buttonText = "Continue",
  }) {
    return CustomConfirmationPage(
      title: title,
      message: message,
      buttonText: buttonText,
      icon: Icons.check_circle,
      iconColor: successGreen,
      statusType: StatusType.success,
    );
  }

  factory CustomConfirmationPage.error({
    String title = "Error",
    String message = "Something went wrong. Please try again.",
    String buttonText = "Try Again",
  }) {
    return CustomConfirmationPage(
      title: title,
      message: message,
      buttonText: buttonText,
      icon: Icons.error,
      iconColor: primaryRed,
      statusType: StatusType.error,
    );
  }

  factory CustomConfirmationPage.warning({
    String title = "Warning",
    String message = "Please review the information before proceeding.",
    String buttonText = "Understood",
  }) {
    return CustomConfirmationPage(
      title: title,
      message: message,
      buttonText: buttonText,
      icon: Icons.warning,
      iconColor: const Color(0xFFFF9800),
      statusType: StatusType.warning,
    );
  }

  factory CustomConfirmationPage.info({
    String title = "Information",
    String message = "Here's some important information for you.",
    String buttonText = "Got it",
  }) {
    return CustomConfirmationPage(
      title: title,
      message: message,
      buttonText: buttonText,
      icon: Icons.info,
      iconColor: primaryBlue,
      statusType: StatusType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
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
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo container with enhanced styling
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
                        height: 60,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 60,
                            width: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.pets,
                              size: 30,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Enhanced message card with proper styling
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Enhanced icon with container and shadow
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: iconColor.withValues(alpha: 0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              icon,
                              color: iconColor,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Enhanced title with better typography
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Enhanced message with better styling
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Enhanced button with proper styling
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                elevation: 2,
                                shadowColor: primaryBlue.withValues(alpha: 0.3),
                              ),
                              onPressed: () {
                                // Navigate back to root - AuthWrapper will handle the navigation
                                Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
                              },
                              child: Text(buttonText),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Enhanced Status Banner Widget for inline notifications
class StatusBanner extends StatelessWidget {
  final String message;
  final StatusType type;
  final bool showIcon;
  final VoidCallback? onDismiss;

  const StatusBanner({
    super.key,
    required this.message,
    this.type = StatusType.info,
    this.showIcon = true,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Color iconColor;
    IconData icon;

    switch (type) {
      case StatusType.success:
        backgroundColor = successGreen.withValues(alpha: 0.1);
        textColor = successGreen;
        iconColor = successGreen;
        icon = Icons.check_circle;
        break;
      case StatusType.error:
        backgroundColor = primaryRed.withValues(alpha: 0.1);
        textColor = primaryRed;
        iconColor = primaryRed;
        icon = Icons.error;
        break;
      case StatusType.warning:
        backgroundColor = const Color(0xFFFF9800).withValues(alpha: 0.1);
        textColor = const Color(0xFFFF9800);
        iconColor = const Color(0xFFFF9800);
        icon = Icons.warning;
        break;
      case StatusType.info:
        backgroundColor = primaryBlue.withValues(alpha: 0.1);
        textColor = primaryBlue;
        iconColor = primaryBlue;
        icon = Icons.info;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                color: iconColor,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }
}