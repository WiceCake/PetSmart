import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:pet_smart/pages/account.dart';
import 'package:pet_smart/pages/cart.dart';
import 'package:pet_smart/pages/dashboard.dart';
import 'package:pet_smart/pages/settings.dart';
import 'package:pet_smart/pages/messages/chat_history.dart';
import 'package:pet_smart/components/cart_service.dart';
import 'package:pet_smart/services/unread_message_service.dart';
import 'package:badges/badges.dart' as badges;

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
  final UnreadMessageService _unreadMessageService = UnreadMessageService();
  int _unreadMessageCount = 0;

  @override
  void initState() {
    super.initState();
    // Initialize cart service when navigation is created
    _initializeCartService();
    // Initialize unread message service
    _initializeUnreadMessages();
  }

  Future<void> _initializeCartService() async {
    try {
      await CartService().initializeCart();
    } catch (e) {
      debugPrint('Failed to initialize cart service: $e');
    }
  }

  Future<void> _initializeUnreadMessages() async {
    try {
      await _unreadMessageService.initialize();
      // Listen to unread message changes
      _unreadMessageService.unreadCountStream.listen((count) {
        if (mounted) {
          setState(() {
            _unreadMessageCount = count;
          });
        }
      });
    } catch (e) {
      debugPrint('Failed to initialize unread message service: $e');
    }
  }

  // Update the widget options list
  final List<Widget> _widgetOptions = <Widget>[
    const DashboardScreen(),
    const SettingScreen(),
    const ChatHistoryPage(),
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
  void dispose() {
    _unreadMessageService.dispose();
    super.dispose();
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
                icon: _unreadMessageCount > 0
                    ? badges.Badge(
                        badgeContent: Text(
                          _unreadMessageCount > 99 ? '99+' : '$_unreadMessageCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        badgeStyle: badges.BadgeStyle(
                          badgeColor: const Color(0xFFEF5350),
                          padding: const EdgeInsets.all(4),
                        ),
                        child: const Icon(Icons.message_rounded),
                      )
                    : const Icon(Icons.message_rounded),
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
