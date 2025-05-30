import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:pet_smart/pages/account.dart';
import 'package:pet_smart/pages/cart.dart';
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

  @override
  void initState() {
    super.initState();
  }

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
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SalomonBottomBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: primaryBlue,
            unselectedItemColor: Colors.grey[600],
            backgroundColor: Colors.white,
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
            items: [
              SalomonBottomBarItem(
                icon: const Icon(Icons.home_rounded),
                title: const Text("Home"),
                selectedColor: primaryBlue,
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.settings_rounded),
                title: const Text("Settings"),
                selectedColor: primaryBlue,
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.message_rounded),
                title: const Text("Messages"),
                selectedColor: primaryBlue,
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.shopping_cart_outlined),
                title: const Text("Cart"),
                selectedColor: primaryBlue,
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.person_rounded),
                title: const Text("Account"),
                selectedColor: primaryBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
