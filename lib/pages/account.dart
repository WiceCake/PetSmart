import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pet_smart/pages/account/liked_items.dart';
import 'package:pet_smart/pages/account/add_pet.dart';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'account/all_pets.dart';
import 'account/pet_details.dart';
import 'package:pet_smart/pages/account/purchase_history.dart';
import 'package:pet_smart/services/order_service.dart';
import 'package:pet_smart/utils/currency_formatter.dart';
import 'package:pet_smart/pages/notifications_list.dart';
import 'package:pet_smart/services/notification_service.dart';
import 'package:pet_smart/services/navigation_service.dart';
import 'package:pet_smart/components/enhanced_toasts.dart';
import 'package:pet_smart/components/enhanced_dialogs.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late ScrollController _scrollController;
  final OrderService _orderService = OrderService();
  final NotificationService _notificationService = NotificationService();
  final ImagePicker _imagePicker = ImagePicker();

  // User data state
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;

  // Pets data state
  List<Map<String, dynamic>> _userPets = [];
  bool _petsLoading = true;

  // Order stats state
  Map<String, dynamic> _orderStats = {};
  bool _statsLoading = true;

  // Recently bought orders data (changed from products to orders)
  List<Map<String, dynamic>> _recentlyBoughtOrders = [];
  bool _recentlyBoughtLoading = true;

  // Notifications state
  int _unreadNotificationCount = 0;
  bool _notificationsLoading = true;

  // Profile editing state
  bool _isEditMode = false;
  bool _isSaving = false;
  final TextEditingController _bioController = TextEditingController();
  Uint8List? _newProfileImageBytes;
  String? _originalBio;

  // Real-time subscriptions
  StreamSubscription<Map<String, dynamic>>? _orderStatsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _recentOrdersSubscription;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scrollController = ScrollController();
    _controller.forward();

    // Set up callback for when notifications are marked as read
    NavigationService().setNotificationReadCallback(() {
      _loadNotificationCount();
    });

    // Initialize real-time subscriptions for orders
    _initializeRealtimeSubscriptions();

    _loadUserData();
    _loadUserPets();
    _loadOrderStats();
    _loadRecentlyBoughtOrders();
    _loadNotificationCount();
  }

  /// Initialize real-time subscriptions for order data
  Future<void> _initializeRealtimeSubscriptions() async {
    debugPrint('AccountScreen: Initializing real-time subscriptions');

    try {
      // Initialize OrderService real-time subscriptions
      await _orderService.initializeRealtimeSubscriptions();

      // Subscribe to order statistics stream
      _orderStatsSubscription = _orderService.orderStatsStream.listen(
        (stats) {
          debugPrint('AccountScreen: Received order stats update: $stats');
          if (mounted) {
            setState(() {
              _orderStats = stats;
              _statsLoading = false;
            });
          }
        },
        onError: (error) {
          debugPrint('AccountScreen: Error in order stats stream: $error');
          if (mounted) {
            setState(() {
              _statsLoading = false;
            });
          }
        },
      );

      // Subscribe to recent orders stream
      _recentOrdersSubscription = _orderService.recentOrdersStream.listen(
        (recentOrders) {
          debugPrint('AccountScreen: Received recent orders update: ${recentOrders.length} orders');
          if (mounted) {
            setState(() {
              _recentlyBoughtOrders = recentOrders;
              _recentlyBoughtLoading = false;
            });
          }
        },
        onError: (error) {
          debugPrint('AccountScreen: Error in recent orders stream: $error');
          if (mounted) {
            setState(() {
              _recentlyBoughtLoading = false;
            });
          }
        },
      );

      debugPrint('AccountScreen: Real-time subscriptions initialized successfully');
    } catch (e) {
      debugPrint('AccountScreen: Error initializing real-time subscriptions: $e');
    }
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

  Future<void> _loadOrderStats() async {
    if (!mounted) return;

    setState(() {
      _statsLoading = true;
    });

    try {
      final stats = await _orderService.getOrderStats();
      if (!mounted) return;
      setState(() {
        _orderStats = stats;
        _statsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statsLoading = false;
        _orderStats = {
          'total_orders': 0,
          'pending_orders': 0,
          'completed_orders': 0,
          'total_spent': 0.0,
        };
      });
    }
  }

  Future<void> _loadRecentlyBoughtOrders() async {
    if (!mounted) return;

    setState(() {
      _recentlyBoughtLoading = true;
    });

    try {
      // Get recent completed orders with product details (limit to 5 orders for dashboard)
      final recentOrders = await _orderService.getUserOrders(
        limit: 5,
        status: 'Completed',
      );

      // Process orders to include summary information
      List<Map<String, dynamic>> processedOrders = [];

      for (final order in recentOrders) {
        final orderItems = order['order_items'] as List<dynamic>? ?? [];

        // Skip orders with no items
        if (orderItems.isEmpty) continue;

        // Calculate order summary
        int totalItems = 0;
        double totalAmount = order['total_amount']?.toDouble() ?? 0.0;
        List<String> productNames = [];
        String primaryImage = 'assets/logo_sample.png';

        for (final item in orderItems) {
          totalItems += (item['quantity'] as int? ?? 1);
          productNames.add(item['product_title'] ?? 'Unknown Product');

          // Use the first product's image as the primary image
          if (primaryImage == 'assets/logo_sample.png' && item['product_image'] != null) {
            primaryImage = item['product_image'];
          }
        }

        // Create order summary
        processedOrders.add({
          'id': order['id'],
          'order_date': order['created_at'],
          'total_amount': totalAmount,
          'total_items': totalItems,
          'item_count': orderItems.length,
          'product_names': productNames,
          'primary_image': primaryImage,
          'delivery_address': order['delivery_address'] ?? 'No address provided',
          'status': order['status'],
          'order_items': orderItems, // Keep full order items for detail view
          // Create a summary string for display
          'items_summary': _createItemsSummary(orderItems),
        });
      }

      if (!mounted) return;
      setState(() {
        _recentlyBoughtOrders = processedOrders;
        _recentlyBoughtLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recentlyBoughtLoading = false;
        _recentlyBoughtOrders = [];
      });
    }
  }

  String _createItemsSummary(List<dynamic> orderItems) {
    if (orderItems.isEmpty) return 'No items';

    if (orderItems.length == 1) {
      final item = orderItems.first;
      final quantity = item['quantity'] ?? 1;
      final name = item['product_title'] ?? 'Unknown Product';
      return quantity > 1 ? '$quantity × $name' : name;
    } else if (orderItems.length == 2) {
      final item1 = orderItems[0];
      final item2 = orderItems[1];
      final name1 = item1['product_title'] ?? 'Unknown';
      final name2 = item2['product_title'] ?? 'Unknown';
      return '$name1, $name2';
    } else {
      final firstName = orderItems.first['product_title'] ?? 'Unknown';
      final remainingCount = orderItems.length - 1;
      return '$firstName + $remainingCount more';
    }
  }

  Future<void> _loadNotificationCount() async {
    if (!mounted) return;

    setState(() {
      _notificationsLoading = true;
    });

    try {
      final notifications = await _notificationService.getUserNotifications(
        unreadOnly: true,
        limit: 100, // Get all unread notifications to count them
      );

      if (!mounted) return;
      setState(() {
        _unreadNotificationCount = notifications.length;
        _notificationsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notificationsLoading = false;
        _unreadNotificationCount = 0;
      });
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _loadUserData(),
      _loadUserPets(),
      _loadOrderStats(),
      _loadRecentlyBoughtOrders(),
      _loadNotificationCount(),
    ]);
  }

  // Profile editing methods
  void _enterEditMode() {
    setState(() {
      _isEditMode = true;
      _originalBio = _userData['bio'] ?? '';
      _bioController.text = _originalBio ?? '';
      _newProfileImageBytes = null;
    });
  }

  void _cancelEdit() async {
    if (_hasUnsavedChanges()) {
      final shouldDiscard = await EnhancedDialogs.showUnsavedChangesConfirmation(context);
      if (shouldDiscard != true) return;
    }

    setState(() {
      _isEditMode = false;
      _bioController.clear();
      _newProfileImageBytes = null;
      _originalBio = null;
    });
  }

  bool _hasUnsavedChanges() {
    final bioChanged = _bioController.text.trim() != (_originalBio ?? '');
    final imageChanged = _newProfileImageBytes != null;
    return bioChanged || imageChanged;
  }

  Future<void> _pickProfileImage() async {
    // Show dialog to choose between camera and gallery
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Profile Picture',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF233A63),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(ImageSource.camera),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.camera_alt_rounded,
                                size: 40,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Camera',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.photo_library_rounded,
                                size: 40,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Gallery',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _newProfileImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        EnhancedToasts.showError(
          context,
          'Failed to pick image. Please try again.',
        );
      }
    }
  }

  Future<String?> _uploadProfileImage(Uint8List bytes, String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage
          .from('profile-pictures')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      final publicUrl = supabase.storage
          .from('profile-pictures')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_hasUnsavedChanges()) {
      _cancelEdit();
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('User not logged in');
      }

      String? uploadedImageUrl;

      // Upload new image if selected
      if (_newProfileImageBytes != null) {
        uploadedImageUrl = await _uploadProfileImage(_newProfileImageBytes!, user.id);
        if (uploadedImageUrl == null) {
          throw Exception('Failed to upload profile image');
        }
      }

      // Prepare update data
      final updateData = <String, dynamic>{
        'bio': _bioController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Only update profile picture if a new one was uploaded
      if (uploadedImageUrl != null) {
        updateData['profile_pic'] = uploadedImageUrl;
      }

      // Update profile in database
      await supabase.from('profiles').update(updateData).eq('id', user.id);

      if (!mounted) return;

      // Update local state
      setState(() {
        _userData['bio'] = _bioController.text.trim();
        if (uploadedImageUrl != null) {
          _userData['profilePic'] = uploadedImageUrl;
        }
        _isEditMode = false;
        _isSaving = false;
        _newProfileImageBytes = null;
        _originalBio = null;
      });

      _bioController.clear();

      // Show success toast
      EnhancedToasts.showProfileUpdated(context);

    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        EnhancedToasts.showError(
          context,
          'Failed to update profile. Please try again.',
        );
      }
    }
  }

  @override
  void dispose() {
    debugPrint('AccountScreen: Disposing resources');

    // Cancel real-time subscriptions
    _orderStatsSubscription?.cancel();
    _recentOrdersSubscription?.cancel();

    // Dispose OrderService resources
    _orderService.dispose();

    _controller.dispose();
    _scrollController.dispose();
    _bioController.dispose();
    // Clear the notification callback
    NavigationService().setNotificationReadCallback(null);

    debugPrint('AccountScreen: Disposed successfully');
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
                _buildNotificationsSection(),
                _buildLikedItemsSection(context),
                _buildPurchasesSection(),
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Edit Profile Button (top right)
            if (!_isLoading && !_isEditMode)
              Align(
                alignment: Alignment.topRight,
                child: TextButton.icon(
                  onPressed: _enterEditMode,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Edit Profile'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF233A63),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            // Profile picture
            Hero(
              tag: 'profile_picture',
              child: GestureDetector(
                onTap: _isEditMode ? _pickProfileImage : null,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
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
                        child: _newProfileImageBytes != null
                            ? Image.memory(
                                _newProfileImageBytes!,
                                fit: BoxFit.cover,
                              )
                            : _userData['profilePic'] != null
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
                    // Edit overlay for profile picture
                    if (_isEditMode)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.3),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

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

                        // Bio section - editable in edit mode
                        _isEditMode
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: TextField(
                                  controller: _bioController,
                                  maxLines: 3,
                                  maxLength: 150,
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    hintText: 'Tell us about yourself and your pets...',
                                    hintStyle: TextStyle(color: Colors.grey[500]),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF233A63)),
                                    ),
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[700],
                                  ),
                                ),
                              )
                            : Text(
                                _userData['bio'] ?? 'Pet lover and enthusiast',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                      ],
                    ),
                  ),

            // Edit mode action buttons
            if (_isEditMode) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _cancelEdit,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[400]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Save button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF233A63),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      child: ListTile(
        leading: Stack(
          children: [
            Icon(
              Icons.notifications_outlined,
              color: Colors.blue[600],
              size: 28,
            ),
            if (_unreadNotificationCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white,
                      width: 1,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    _unreadNotificationCount > 99 ? '99+' : _unreadNotificationCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: _notificationsLoading
            ? const Text(
                'Loading...',
                style: TextStyle(fontSize: 12),
              )
            : _unreadNotificationCount > 0
                ? Text(
                    '$_unreadNotificationCount unread notification${_unreadNotificationCount > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : Text(
                    'All caught up!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationsListPage()),
          );
          // Refresh notification count when returning from notifications page
          if (result == true || result == null) {
            _loadNotificationCount();
          }
        },
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Purchases',
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
                      builder: (context) => const PurchaseHistoryPage(),
                    ),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _statsLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      // First row - Preparing and Pending Delivery
                      Row(
                        children: [
                          Expanded(
                            child: _buildPurchaseItem(
                              Icons.kitchen_outlined,
                              'Preparing',
                              _orderStats['preparing_orders']?.toString() ?? '0',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PurchaseHistoryPage(initialFilter: 'Preparing'),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPurchaseItem(
                              Icons.local_shipping_outlined,
                              'Pending Delivery',
                              _orderStats['pending_delivery_orders']?.toString() ?? '0',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PurchaseHistoryPage(initialFilter: 'Pending Delivery'),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Second row - Order Confirmation and Completed
                      Row(
                        children: [
                          Expanded(
                            child: _buildPurchaseItem(
                              Icons.check_circle_outline,
                              'Order Confirmation',
                              _orderStats['order_confirmation_orders']?.toString() ?? '0',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PurchaseHistoryPage(initialFilter: 'Order Confirmation'),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPurchaseItem(
                              Icons.check_circle,
                              'Completed',
                              _orderStats['completed_orders']?.toString() ?? '0',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PurchaseHistoryPage(initialFilter: 'Completed'),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          if (!_statsLoading && _orderStats['total_spent'] != null && _orderStats['total_spent'] > 0) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Spent',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  CurrencyFormatter.formatPeso(_orderStats['total_spent']),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF233A63),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPurchaseItem(IconData icon, String label, String count, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 110, // Increased height to accommodate labels
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with consistent sizing
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 22,
                  color: const Color(0xFF233A63),
                ),
              ),
              const SizedBox(height: 6),
              // Count with consistent styling
              Text(
                count,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF233A63),
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              // Label with proper text handling - increased space allocation
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
                  if (_userPets.isNotEmpty)
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
                  if (_userPets.isEmpty)
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
                      builder: (context) => const PurchaseHistoryPage(initialFilter: 'Completed'),
                    ),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _recentlyBoughtLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _recentlyBoughtOrders.isEmpty
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
                              Icons.shopping_bag_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No recent purchases',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start shopping to see your recent purchases here!',
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
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentlyBoughtOrders.length,
                      itemBuilder: (context, index) {
                        final order = _recentlyBoughtOrders[index];
                        return _buildRecentOrderCard(order);
                      },
                    ),
        ],
      ),
    );
  }

  Widget _buildRecentOrderCard(Map<String, dynamic> order) {
    final orderDate = DateTime.parse(order['order_date']);
    final formattedDate = '${orderDate.day}/${orderDate.month}/${orderDate.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        color: Colors.grey[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            // Navigate to order details - you can implement this later
            _showOrderDetails(order);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Order Image (primary product image)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: order['primary_image'] != 'assets/logo_sample.png'
                      ? Image.network(
                          order['primary_image'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.shopping_bag, size: 24, color: Colors.grey[600]),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.shopping_bag, size: 24, color: Colors.grey[600]),
                        ),
                ),
                const SizedBox(width: 16),
                // Order Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order ID and Date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${order['id'].toString().substring(0, 8)}...',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF233A63),
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Items Summary
                      Text(
                        order['items_summary'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Total Amount and Item Count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${order['item_count']} item${order['item_count'] > 1 ? 's' : ''} • ${order['total_items']} total',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatPeso(order['total_amount']),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF233A63),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow indicator
                Icon(
                  Icons.arrow_forward_ios,
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

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order Details',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Order details content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Order info
                    _buildOrderDetailRow('Order ID', '#${order['id'].toString().substring(0, 8)}...'),
                    _buildOrderDetailRow('Date', DateTime.parse(order['order_date']).toString().split(' ')[0]),
                    _buildOrderDetailRow('Status', order['status']),
                    _buildOrderDetailRow('Total Amount', CurrencyFormatter.formatPeso(order['total_amount'])),
                    const SizedBox(height: 20),
                    const Text(
                      'Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Order items
                    ...((order['order_items'] as List<dynamic>? ?? []).map((item) =>
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['product_title'] ?? 'Unknown Product',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Quantity: ${item['quantity'] ?? 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatPeso(item['price'] ?? 0.0),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).toList()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

}
