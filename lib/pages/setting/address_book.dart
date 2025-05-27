import 'package:flutter/material.dart';
import 'package:pet_smart/pages/setting/add_address.dart';
import 'package:pet_smart/pages/setting/edit_address.dart';

// PetSmart brand colors
const primaryBlue = Color(0xFF233A63);
const backgroundColor = Color(0xFFF8F9FA);
const cardColor = Colors.white;

class AddressBookPage extends StatefulWidget {
  const AddressBookPage({super.key});

  @override
  State<AddressBookPage> createState() => _AddressBookPageState();
}

class _AddressBookPageState extends State<AddressBookPage> with SingleTickerProviderStateMixin {
  // Animation controller for list items
  late AnimationController _animationController;

  // Sample addresses - in a real app, this would come from a database or API
  final List<Map<String, dynamic>> _addresses = [
    {
      'id': '1',
      'name': 'Home',
      'address': '123 Main Street, Quezon City, Philippines',
      'isDefault': true,
      'phoneNumber': '+63 9123456789',
    },
    {
      'id': '2',
      'name': 'Work',
      'address': '456 Office Building, Makati City, Philippines',
      'isDefault': false,
      'phoneNumber': '+63 9876543210',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Address Book',
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
      body: SafeArea(
        child: _addresses.isEmpty
            ? _buildEmptyState()
            : _buildAddressList(),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24, right: 24),
        child: Semantics(
          button: true,
          label: 'Add Address',
          child: FloatingActionButton(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddAddressPage()),
              );
              if (result != null) {
                setState(() {
                  if (result['isDefault']) {
                    for (var addr in _addresses) {
                      addr['isDefault'] = false;
                    }
                  }
                  _addresses.add({
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    ...result,
                  });
                });
                _animationController.reset();
                _animationController.forward();
              }
            },
            tooltip: 'Add Address',
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            mini: true,
            child: const Icon(Icons.add, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 24),
          const Text(
            'No addresses yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Add your first address to help us deliver to the right place',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddAddressPage()),
              );
              if (result != null) {
                setState(() {
                  if (result['isDefault']) {
                    for (var addr in _addresses) {
                      addr['isDefault'] = false;
                    }
                  }
                  _addresses.add({
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    ...result,
                  });
                });
                _animationController.reset();
                _animationController.forward();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Add Address',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _addresses.length,
          itemBuilder: (context, index) {
            final address = _addresses[index];
            final isDefault = address['isDefault'] as bool;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cardColor,
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
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: CircleAvatar(
                  backgroundColor: primaryBlue.withValues(alpha: 0.1),
                  child: Icon(_getAddressIcon(address['name']), color: primaryBlue, size: 22),
                ),
                title: Text(
                  address['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address['address'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        address['phoneNumber'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: isDefault
                    ? Icon(Icons.check_circle, color: primaryBlue, size: 22)
                    : Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditAddressPage(address: address),
                    ),
                  );
                  if (result != null) {
                    if (result['delete'] == true) {
                      setState(() {
                        _addresses.removeWhere((addr) => addr['id'] == address['id']);
                      });
                    } else {
                      setState(() {
                        if (result['isDefault']) {
                          for (var addr in _addresses) {
                            addr['isDefault'] = false;
                          }
                        }
                        final index = _addresses.indexWhere((addr) => addr['id'] == address['id']);
                        if (index != -1) {
                          _addresses[index] = result;
                        }
                      });
                    }
                    _animationController.reset();
                    _animationController.forward();
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  IconData _getAddressIcon(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('home')) {
      return Icons.home_outlined;
    } else if (lowerName.contains('work') || lowerName.contains('office')) {
      return Icons.business_outlined;
    } else if (lowerName.contains('school') || lowerName.contains('college')) {
      return Icons.school_outlined;
    } else if (lowerName.contains('gym')) {
      return Icons.fitness_center_outlined;
    } else {
      return Icons.place_outlined;
    }
  }


}