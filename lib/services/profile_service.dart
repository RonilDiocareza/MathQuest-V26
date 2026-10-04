import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

/// Service to manage user profile data including image storage and persistence
class ProfileService {
  static final ProfileService _instance = ProfileService._internal();

  factory ProfileService() {
    return _instance;
  }

  ProfileService._internal();

  static const String _nameKey = 'current_user_name';
  static const String _emailKey = 'current_user_email';
  static const String _roleKey = 'current_user_role';
  static const String _lrnKey = 'current_user_lrn';
  static const String _addressKey = 'current_user_address';
  static const String _profilePhotoDataKey = 'current_user_profile_photo_data';

  /// Save user profile information
  Future<void> saveProfile({
    required String name,
    required String email,
    required String role,
    required String lrn,
    required String address,
  }) async {
    await AuthService.updateCurrentProfile(
      name: name,
      address: address,
      lrn: lrn,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_roleKey, role);
    await prefs.setString(_lrnKey, lrn);
    await prefs.setString(_addressKey, address);
  }

  /// Load user profile information
  Future<Map<String, String>> loadProfile() async {
    final user = AuthService.currentUser;
    final account = user == null ? null : await AuthService.getAccount(user.uid);
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': account?.name ?? prefs.getString(_nameKey) ?? '',
      'email': account?.email ?? user?.email ?? prefs.getString(_emailKey) ?? '',
      'role': account?.role ?? prefs.getString(_roleKey) ?? '',
      'lrn': account?.lrn ?? prefs.getString(_lrnKey) ?? '',
      'address': account?.address ?? prefs.getString(_addressKey) ?? '',
      'profilePhotoData': prefs.getString(_profilePhotoDataKey) ?? '',
    };
  }

  /// Save profile photo bytes so the same implementation works on web and mobile.
  Future<bool> saveProfilePhoto(Uint8List photoBytes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profilePhotoDataKey, base64Encode(photoBytes));
      return true;
    } catch (e) {
      print('Error saving profile photo: $e');
      return false;
    }
  }

  /// Get the persisted profile photo bytes.
  Future<Uint8List?> getProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final photoData = prefs.getString(_profilePhotoDataKey);

    if (photoData != null && photoData.isNotEmpty) {
      try {
        return base64Decode(photoData);
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  /// Delete profile photo
  Future<void> deleteProfilePhoto() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profilePhotoDataKey);
    } catch (e) {
      print('Error deleting profile photo: $e');
    }
  }

  /// Clear all profile data
  Future<void> clearProfile() async {
    try {
      await AuthService.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_nameKey);
      await prefs.remove(_emailKey);
      await prefs.remove(_roleKey);
      await prefs.remove(_lrnKey);
      await prefs.remove(_addressKey);
    } catch (e) {
      print('Error clearing profile: $e');
    }
  }
}
