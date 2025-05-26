import 'package:flutter/material.dart';
import 'package:pet_smart/components/nav_bar.dart';

class CustomConfirmationPage extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final IconData icon;
  final Color iconColor;

  const CustomConfirmationPage({
    super.key,
    this.title = "Successfully",
    this.message = "The shop has already received your schedule.",
    this.buttonText = "Back to home page",
    this.icon = Icons.check_circle,
    this.iconColor = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF233A63); // blue from your app
    const accentColor = Color(0xFFE57373);  // red from your app

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo at the top
                Image.asset(
                  'assets/petsmart_word.png',
                  height: 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 32),
                // Message box without shadow or border
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: iconColor, size: 90),
                      const SizedBox(height: 24),
                      Text(
                        title,
                        style: TextStyle(
                          color: iconColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: 220,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor, // red or use primaryColor for blue
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            elevation: 0, // No shadow
                          ),
                          onPressed: () {
                            // Navigate to the bottom navigation with Home tab selected
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const BottomNavigation(),
                              ),
                              (route) => false, // This removes all previous routes
                            );
                          },
                          child: Text(buttonText),
                        ),
                      ),
                    ],
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