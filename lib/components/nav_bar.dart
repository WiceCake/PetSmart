import 'package:flutter/material.dart';
import 'package:pet_smart/pages/account.dart';
import 'package:pet_smart/pages/cart.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:pet_smart/pages/dashboard.dart';
import 'package:pet_smart/pages/settings.dart';
import 'package:pet_smart/pages/messages/direct_chat_admin.dart';

const Color primaryRed = Color(0xFFE57373);    // Light coral red
const Color primaryBlue = Color(0xFF3F51B5);   // PetSmart blue
const Color accentRed = Color(0xFFEF5350);     // Brighter red for emphasis
const Color backgroundColor = Color(0xFFF6F7FB); // Light background

class BottomNavigationApp extends StatelessWidget {
  const BottomNavigationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BottomNavigation(),
    );
  }
}

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _selectedIndex = 0;

  // Update the widget options list
  final List<Widget> _widgetOptions = <Widget>[
    const DashboardScreen(),
    const SettingScreen(),
    const DirectChatAdminPage(),
    // Remove CartPage from here since we'll handle it differently
    const Center(child: Text('Cart', style: TextStyle(fontSize: 22))),
    const AccountScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 3) { // Cart tab index
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const CartPage(showBackButton: false),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate dynamic sizes based on screen width
    double iconSize = MediaQuery.of(context).size.width * 0.055; // Dynamic icon size
    double textSize = MediaQuery.of(context).size.width * 0.028; // Dynamic text size
    
    // Adjust padding based on screen width
    double horizontalPadding = MediaQuery.of(context).size.width * 0.02;
    double verticalPadding = MediaQuery.of(context).size.width * 0.015;
    
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        child: SalomonBottomBar(
          margin: EdgeInsets.symmetric(horizontal: horizontalPadding / 2),
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            SalomonBottomBarItem(
              icon: Icon(Icons.home_rounded, size: iconSize),
              title: Text("Home", style: TextStyle(fontSize: textSize)),
              selectedColor: primaryBlue,
            ),
            SalomonBottomBarItem(
              icon: Icon(Icons.settings_rounded, size: iconSize),
              title: Text("Setting", style: TextStyle(fontSize: textSize)),
              selectedColor: primaryBlue,
            ),
            SalomonBottomBarItem(
              icon: Icon(Icons.message_rounded, size: iconSize),
              title: Text("Messages", style: TextStyle(fontSize: textSize)),
              selectedColor: primaryRed,
            ),
            SalomonBottomBarItem(
              icon: Icon(Icons.shopping_cart_outlined, size: iconSize),
              activeIcon: Icon(Icons.shopping_cart, size: iconSize),
              title: Text('Cart', style: TextStyle(fontSize: textSize)),
              selectedColor: primaryBlue,
            ),
            SalomonBottomBarItem(
              icon: Icon(Icons.person_rounded, size: iconSize),
              title: Text("Account", style: TextStyle(fontSize: textSize)),
              selectedColor: primaryBlue,
            ),
          ],
        ),
      ),
    );
  }
}
