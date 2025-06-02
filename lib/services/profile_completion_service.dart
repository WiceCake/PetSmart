import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to check and manage user profile completion status
class ProfileCompletionService {
  static final ProfileCompletionService _instance = ProfileCompletionService._internal();
  factory ProfileCompletionService() => _instance;
  ProfileCompletionService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Check if user has completed their profile setup
  /// Returns ProfileCompletionStatus indicating what step user is on
  Future<ProfileCompletionStatus> checkProfileCompletion(String userId) async {
    try {
      debugPrint('ProfileCompletionService: Checking profile completion for user: $userId');

      // Query user profile data
      final response = await _supabase
          .from('profiles')
          .select('first_name, last_name, username, profile_pic')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        debugPrint('ProfileCompletionService: No profile found - needs user details');
        return ProfileCompletionStatus.needsUserDetails;
      }

      final profile = response;

      // Check if basic user details are complete
      final hasFirstName = profile['first_name'] != null && (profile['first_name'] as String).trim().isNotEmpty;
      final hasLastName = profile['last_name'] != null && (profile['last_name'] as String).trim().isNotEmpty;

      if (!hasFirstName || !hasLastName) {
        debugPrint('ProfileCompletionService: Missing basic details - needs user details');
        return ProfileCompletionStatus.needsUserDetails;
      }

      // Check if profile setup is complete
      final hasUsername = profile['username'] != null && (profile['username'] as String).trim().isNotEmpty;
      final hasProfilePic = profile['profile_pic'] != null && (profile['profile_pic'] as String).trim().isNotEmpty;

      if (!hasUsername || !hasProfilePic) {
        debugPrint('ProfileCompletionService: Missing profile setup - needs profile setup');
        return ProfileCompletionStatus.needsProfileSetup;
      }

      debugPrint('ProfileCompletionService: Profile complete');
      return ProfileCompletionStatus.complete;

    } catch (e) {
      debugPrint('ProfileCompletionService: Error checking profile completion: $e');
      // If there's an error, assume profile needs to be completed
      return ProfileCompletionStatus.needsUserDetails;
    }
  }

  /// Delete incomplete user registration from Supabase Auth and all associated data
  /// This should be called when user cancels registration
  Future<bool> deleteIncompleteRegistration() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('ProfileCompletionService: No user to delete');
        return true;
      }

      debugPrint('ProfileCompletionService: Deleting incomplete registration for user: ${user.id}');

      // Call the database function to delete the user account and all associated data
      final response = await _supabase.rpc('delete_user_account', params: {
        'user_id_to_delete': user.id,
      });

      debugPrint('ProfileCompletionService: Database function response: $response');

      // Check if the deletion was successful
      if (response == true) {
        debugPrint('ProfileCompletionService: User account deleted successfully');

        // Sign out the user (the user should already be deleted, but this ensures clean state)
        try {
          await _supabase.auth.signOut();
        } catch (e) {
          // Ignore signout errors since the user is already deleted
          debugPrint('ProfileCompletionService: Signout after deletion (expected to fail): $e');
        }

        return true;
      } else {
        debugPrint('ProfileCompletionService: Database function returned false');
        return false;
      }
    } catch (e) {
      debugPrint('ProfileCompletionService: Error deleting incomplete registration: $e');

      // If the database function fails, fall back to the old method (sign out only)
      try {
        final user = _supabase.auth.currentUser;
        if (user != null) {
          debugPrint('ProfileCompletionService: Falling back to sign out only');
          await _supabase.auth.signOut();
          return true;
        }
      } catch (signOutError) {
        debugPrint('ProfileCompletionService: Error during fallback signout: $signOutError');
      }

      return false;
    }
  }

  /// Check if current user has a complete profile
  Future<bool> isCurrentUserProfileComplete() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final status = await checkProfileCompletion(user.id);
    return status == ProfileCompletionStatus.complete;
  }
}

/// Enum representing the profile completion status
enum ProfileCompletionStatus {
  /// User needs to verify their email address
  needsEmailVerification,

  /// User needs to complete basic details (first_name, last_name, birthdate)
  needsUserDetails,

  /// User needs to complete profile setup (username, profile_pic, bio)
  needsProfileSetup,

  /// Profile is complete
  complete,
}
