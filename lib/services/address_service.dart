import 'package:supabase_flutter/supabase_flutter.dart';

class AddressService {
  static final AddressService _instance = AddressService._internal();
  final SupabaseClient _supabase = Supabase.instance.client;

  factory AddressService() {
    return _instance;
  }

  AddressService._internal();

  /// Get user's addresses
  Future<List<Map<String, dynamic>>> getUserAddresses() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      final response = await _supabase
          .from('addresses')
          .select('*')
          .eq('user_id', user.id)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('AddressService: Error fetching addresses: $e');
      return [];
    }
  }

  /// Add a new address (compatible with existing forms)
  Future<Map<String, dynamic>?> addAddress({
    required String name,
    required String address,
    required String phoneNumber,
    bool isDefault = false,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate required fields
      if (name.trim().isEmpty) {
        throw Exception('Address name is required');
      }
      if (address.trim().isEmpty) {
        throw Exception('Full address is required');
      }
      if (phoneNumber.trim().isEmpty) {
        throw Exception('Phone number is required');
      }

      // Validate phone number format (basic validation)
      // More lenient validation - just check if not empty and has some digits
      if (phoneNumber.trim().isEmpty || !RegExp(r'\d').hasMatch(phoneNumber)) {
        throw Exception('Please enter a valid phone number');
      }

      // If this is set as default, unset other defaults first
      if (isDefault) {
        await _supabase
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', user.id);
      }

      final response = await _supabase
          .from('addresses')
          .insert({
            'user_id': user.id,
            'label': name.trim(),
            'full_address': address.trim(),
            'phone_number': phoneNumber.trim(),
            'is_default': isDefault,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      print('AddressService: Error adding address: $e');
      return null;
    }
  }

  /// Update an existing address (compatible with existing forms)
  Future<Map<String, dynamic>?> updateAddress({
    required String addressId,
    required String name,
    required String address,
    required String phoneNumber,
    bool isDefault = false,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate required fields
      if (name.trim().isEmpty) {
        throw Exception('Address name is required');
      }
      if (address.trim().isEmpty) {
        throw Exception('Full address is required');
      }
      if (phoneNumber.trim().isEmpty) {
        throw Exception('Phone number is required');
      }

      // Validate phone number format (basic validation)
      // Temporarily disabled for testing
      // if (!_isValidPhoneNumber(phoneNumber)) {
      //   throw Exception('Please enter a valid phone number');
      // }

      // If this is set as default, unset other defaults first
      if (isDefault) {
        await _supabase
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', user.id)
            .neq('id', addressId);
      }

      final response = await _supabase
          .from('addresses')
          .update({
            'label': name.trim(),
            'full_address': address.trim(),
            'phone_number': phoneNumber.trim(),
            'is_default': isDefault,
          })
          .eq('id', addressId)
          .eq('user_id', user.id)
          .select()
          .single();

      return response;
    } catch (e) {
      print('AddressService: Error updating address: $e');
      return null;
    }
  }

  /// Delete an address
  Future<bool> deleteAddress(String addressId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      await _supabase
          .from('addresses')
          .delete()
          .eq('id', addressId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      print('AddressService: Error deleting address: $e');
      return false;
    }
  }

  /// Set an address as default
  Future<bool> setDefaultAddress(String addressId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      // First, unset all defaults
      await _supabase
          .from('addresses')
          .update({'is_default': false})
          .eq('user_id', user.id);

      // Then set the selected address as default
      await _supabase
          .from('addresses')
          .update({'is_default': true})
          .eq('id', addressId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      print('AddressService: Error setting default address: $e');
      return false;
    }
  }

  /// Get the default address
  Future<Map<String, dynamic>?> getDefaultAddress() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return null;
      }

      final response = await _supabase
          .from('addresses')
          .select('*')
          .eq('user_id', user.id)
          .eq('is_default', true)
          .maybeSingle();

      return response;
    } catch (e) {
      print('AddressService: Error fetching default address: $e');
      return null;
    }
  }

  /// Get address by ID
  Future<Map<String, dynamic>?> getAddressById(String addressId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return null;
      }

      final response = await _supabase
          .from('addresses')
          .select('*')
          .eq('id', addressId)
          .eq('user_id', user.id)
          .single();

      return response;
    } catch (e) {
      print('AddressService: Error fetching address: $e');
      return null;
    }
  }

  /// Format address for display (compatible with existing UI)
  static String formatAddress(Map<String, dynamic> address) {
    return address['full_address']?.toString() ?? '';
  }

  /// Convert database address to UI format
  static Map<String, dynamic> toUIFormat(Map<String, dynamic> dbAddress) {
    return {
      'id': dbAddress['id'],
      'name': dbAddress['label'] ?? 'Address',
      'address': dbAddress['full_address'] ?? '',
      'phoneNumber': dbAddress['phone_number'] ?? '',
      'isDefault': dbAddress['is_default'] ?? false,
    };
  }

  /// Convert UI format to database format
  static Map<String, dynamic> fromUIFormat(Map<String, dynamic> uiAddress) {
    return {
      'label': uiAddress['name'] ?? 'Address',
      'full_address': uiAddress['address'] ?? '',
      'phone_number': uiAddress['phoneNumber'] ?? '',
      'is_default': uiAddress['isDefault'] ?? false,
    };
  }

  /// Format address for single line display
  static String formatAddressOneLine(Map<String, dynamic> address) {
    return address['full_address']?.toString() ?? '';
  }

  /// Validate phone number format (flexible validation)
  bool _isValidPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // More flexible phone number validation
    // Accept any phone number with 7-15 digits (international standard)
    if (digitsOnly.length >= 7 && digitsOnly.length <= 15) {
      return true;
    }

    // Also accept if the original string contains common phone patterns
    final phonePattern = RegExp(r'^[\+]?[\d\s\-\(\)]{7,20}$');
    if (phonePattern.hasMatch(phoneNumber.trim())) {
      return true;
    }

    return false;
  }
}
