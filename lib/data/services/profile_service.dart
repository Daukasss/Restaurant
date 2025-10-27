import 'package:flutter/material.dart';
import 'package:restauran/data/services/abstract/service_export.dart';
import '../../theme/aq_toi.dart';
import '../models/profile.dart';

class ProfileService implements AbstractProfileService {
  @override
  Future<Profile> getProfile() async {
    final response = await supabase
        .from('profiles')
        .select('id, name, phone, role')
        .eq('id', supabase.auth.currentUser!.id)
        .single();
    return Profile.fromJson(response);
  }

  @override
  Future<void> updateProfile(String name, String phone) async {
    await supabase.from('profiles').update({
      'name': name,
      'phone': phone,
    }).eq('id', supabase.auth.currentUser!.id);
  }

  @override
  Future<void> loadUserInfo(TextEditingController nameController,
      TextEditingController phoneController) async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response =
          await supabase.from('profiles').select().eq('id', user.id).single();
      nameController.text = response['name'] ?? '';
      phoneController.text = response['phone'] ?? '';
    }
  }

  Future<Map<String, String?>> getUserInfo() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return {'name': null, 'phone': null};

      final response =
          await supabase.from('profiles').select().eq('id', userId).single();

      return {
        'name': response['name'],
        'phone': response['phone'],
      };
    } catch (error) {
      debugPrint('Error getting user info: $error');
      return {'name': null, 'phone': null};
    }
  }

  @override
  Future<void> addUserProfile(Profile profile) async {
    await supabase.from('profiles').insert(profile.toJson());
  }

  @override
  Future<void> updateUserProfile(Profile profile) async {
    await supabase
        .from('profiles')
        .update(profile.toJson())
        .eq('id', profile.id);
  }

  @override
  Future<void> deleteUserProfile(String userId) async {
    await supabase.from('profiles').delete().eq('id', userId);
  }

  @override
  Future<Profile?> getUserProfile(String userId) async {
    final response =
        await supabase.from('profiles').select().eq('id', userId).maybeSingle();
    if (response == null) return null;
    return Profile.fromJson(response);
  }

  @override
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  @override
  bool isAuthenticated() {
    return supabase.auth.currentUser != null;
  }

  @override
  String? getCurrentUserId() {
    return supabase.auth.currentUser?.id;
  }
}
