import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pet_smart/pages/account/liked_items.dart';
import 'package:pet_smart/pages/account/add_pet.dart';
import 'dart:math' as math;
import 'package:pet_smart/pages/view_all_products.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'account/all_pets.dart';
import 'account/pet_details.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late ScrollController _scrollController;

  // User data state
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;

  // Pets data state
  List<Map<String, dynamic>> _userPets = [];
  bool _petsLoading = true;

  // Static constants for better performance
  static const List<Map<String, dynamic>> _recentlyBoughtProducts = [
    {
      'name': 'Product Name 1',
      'image': 'assets/product_placeholder.png',
      'price': 24.99,
      'rating': 4.5,
      'soldCount': 2,
    },
    {
      'name': 'Product Name 2',
      'image': 'assets/product_placeholder.png',
      'price': 19.99,
      'rating': 4.2,
      'soldCount': 1,
    },
    {
      'name': 'Product Name 3',
      'image': 'assets/product_placeholder.png',
      'price': 29.99,
      'rating': 4.8,
      'soldCount': 3,
    },
    {
      'name': 'Product Name 4',
      'image': 'assets/product_placeholder.png',
      'price': 15.99,
      'rating': 4.0,
      'soldCount': 1,
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scrollController = ScrollController();
    _controller.forward();
    _loadUserData();
    _loadUserPets();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _userData = {
            'username': 'Guest',
            'fullName': 'Guest User',
            'bio': 'Welcome to PetSmart',
            'profilePic': null,
          };
        });
        return;
      }

      // Fetch user profile data
      final response = await supabase
          .from('profiles')
          .select('first_name, last_name, phone_number, birthdate, profile_pic, username, bio')
          .eq('id', user.id)
          .single();

      if (!mounted) return;
      setState(() {
        _userData = {
          'username': response['username'] ?? 'user',
          'fullName': '${response['first_name'] ?? ''} ${response['last_name'] ?? ''}'.trim(),
          'firstName': response['first_name'] ?? '',
          'lastName': response['last_name'] ?? '',
          'email': user.email ?? '',
          'phone': response['phone_number'] ?? '',
          'birthDate': response['birthdate'] ?? '',
          'profilePic': response['profile_pic'],
          'bio': response['bio'] ?? 'Pet lover and enthusiast',
        };
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        // Set default values if loading fails
        _userData = {
          'username': 'user',
          'fullName': 'User',
          'bio': 'Pet lover and enthusiast',
          'profilePic': null,
        };
      });
    }
  }

  Future<void> _loadUserPets() async {
    if (!mounted) return;

    setState(() {
      _petsLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (!mounted) return;
        setState(() {
          _petsLoading = false;
          _userPets = [];
        });
        return;
      }

      // Fetch user's pets
      final response = await supabase
          .from('pets')
          .select('id, name, type, gender, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _userPets = List<Map<String, dynamic>>.from(response);
        _petsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _petsLoading = false;
        _userPets = [];
      });
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _loadUserData(),
      _loadUserPets(),
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileSection(),
                _buildPurchasesSection(),
                _buildLikedItemsSection(context),
                _buildPetsSection(),
                _buildRecentlyBoughtSection(),
                const SizedBox(height: 20), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center( // Added Center widget here
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Added center alignment
          children: [
            // Profile picture with edit button
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Hero(
                  tag: 'profile_picture',
                  child: Container(
                    width: 120, // Increased size slightly
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _userData['profilePic'] != null
                          ? Image.network(
                              _userData['profilePic'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: Icon(Icons.person, size: 60, color: Colors.grey[600]),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.person, size: 60, color: Colors.grey[600]),
                            ),
                    ),
                  ),
                ),
                Material(
                  color: Colors.blue,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20), // Increased spacing
            // User info with fade in animation
            _isLoading
                ? const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Loading profile...'),
                    ],
                  )
                : FadeTransition(
                    opacity: _controller,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '@${_userData['username'] ?? 'user'}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _userData['fullName'] ?? 'User',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _userData['bio'] ?? 'Pet lover and enthusiast',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchasesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Purchases',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPurchaseItem(Icons.local_shipping_outlined, 'To Receive'),
              _buildPurchaseItem(Icons.star_outline, 'To Rate'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.grey[700]),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLikedItemsSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8), // Reduced vertical padding for a single item
      color: Colors.white,
      child: ListTile(
        leading: Icon(Icons.favorite_border, color: Colors.red[400], size: 28),
        title: const Text(
          'Liked Items',
          style: TextStyle(
            fontSize: 17, // Slightly adjusted font size
            fontWeight: FontWeight.w500, // Medium weight
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LikedItemsPage()),
          );
        },
      ),
    );
  }

  Widget _buildPetsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Pets',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  if (_userPets.length > 6)
                    TextButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AllPetsPage(pets: _userPets),
                          ),
                        );
                        // Refresh pets list if changes were made
                        if (result == true) {
                          _loadUserPets();
                        }
                      },
                      child: Text(
                        'View All',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddPetAccountScreen()),
                      );
                      // Refresh pets list if a pet was added successfully
                      if (result == true) {
                        _loadUserPets();
                      }
                    },
                    icon: const Icon(Icons.add, color: Colors.blue),
                    label: Text(
                      'Add Pet',
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _petsLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _userPets.isEmpty
                  ? Center(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.pets,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No pets added yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add your first pet to get started!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.85, // Adjusted to prevent overflow
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: math.min(6, _userPets.length),
                      itemBuilder: (context, index) {
                        final pet = _userPets[index];
                        return _buildPetCard(
                          pet['name'] ?? 'Unknown',
                          pet['type'] ?? 'Other',
                          pet['gender'] ?? 'Unknown',
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PetDetailsPage(pet: pet),
                              ),
                            );
                            // Refresh pets list if changes were made
                            if (result == true) {
                              _loadUserPets();
                            }
                          },
                        );
                      },
                    ),
        ],
      ),
    );
  }

  // Static method for better performance - moved outside build
  static IconData _getPetIcon(String type) {
    switch (type.toLowerCase()) {
      case 'dog':
        return FontAwesomeIcons.dog;
      case 'cat':
        return FontAwesomeIcons.cat;
      case 'bird':
        return FontAwesomeIcons.dove;
      case 'fish':
        return FontAwesomeIcons.fish;
      case 'hamster':
        return FontAwesomeIcons.kiwiBird;
      default:
        return FontAwesomeIcons.paw;
    }
  }

  Widget _buildPetCard(String name, String type, String gender, {VoidCallback? onTap}) {
    const primaryColor = Color(0xFF233A63);

    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pet Icon Container - Top section
              Expanded(
                flex: 3,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: FaIcon(
                      _getPetIcon(type),
                      size: 24,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Pet Name - Middle section with proper height
              Container(
                height: 20, // Fixed height to ensure descenders are visible
                alignment: Alignment.center,
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: primaryColor,
                    height: 1.2, // Line height to accommodate descenders
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 6),
              // Pet Type and Gender - Bottom section
              Container(
                height: 16, // Fixed height for consistent layout
                alignment: Alignment.center,
                child: Text(
                  '$type • $gender',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.2, // Line height for better text rendering
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentlyBoughtSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recently Bought',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewAllProductsPage(
                        title: 'Recently Bought',
                        products: _recentlyBoughtProducts,
                      ),
                    ),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _recentlyBoughtProducts.length,
            itemBuilder: (context, index) {
              final product = _recentlyBoughtProducts[index];
              return _buildRecentItemCard(
                product['name'] as String,
                product['image'] as String,
                'Product description goes here',
                product['soldCount'] as int,
                product['price'] as double,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItemCard(
    String name,
    String image,
    String description,
    int quantity,
    double price,
  ) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image - Made responsive with AspectRatio
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.broken_image, size: 40, color: Colors.grey[600]),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Product Details
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            // Quantity and Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Qty: $quantity',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
