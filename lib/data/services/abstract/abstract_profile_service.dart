import 'package:flutter/material.dart';
import '../../models/profile.dart';

abstract class AbstractProfileService {
  Future<Profile> getProfile();
  Future<void> updateProfile(String name, String phone);

  Future<void> loadUserInfo(
    TextEditingController nameController,
    TextEditingController phoneController,
  );

  Future<void> addUserProfile(Profile profile);
  Future<void> updateUserProfile(Profile profile);
  Future<void> deleteUserProfile(String userId);
  Future<Profile?> getUserProfile(String userId);

  Future<void> signOut();
  bool isAuthenticated();
  String? getCurrentUserId();
}
