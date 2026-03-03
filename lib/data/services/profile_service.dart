import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:restauran/data/services/abstract/service_export.dart';
import '../models/profile.dart';

class ProfileService implements AbstractProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<Profile> getProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Пользователь не авторизован');
    }

    final doc =
        await _firestore.collection('profiles').doc(currentUser.uid).get();

    if (!doc.exists) {
      throw Exception('Профиль не найден');
    }

    return Profile.fromJson(doc.data()!);
  }

  @override
  Future<void> updateProfile(String name, String phone) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Пользователь не авторизован');
    }

    await _firestore.collection('profiles').doc(currentUser.uid).update({
      'name': name,
      'phone': phone,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> loadUserInfo(TextEditingController nameController,
      TextEditingController phoneController) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final doc =
          await _firestore.collection('profiles').doc(currentUser.uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        nameController.text = data['name'] ?? '';
        phoneController.text = data['phone'] ?? '';
      }
    }
  }

  Future<Map<String, String?>> getUserInfo() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return {'name': null, 'phone': null};

      final doc =
          await _firestore.collection('profiles').doc(currentUser.uid).get();

      if (!doc.exists) return {'name': null, 'phone': null};

      final data = doc.data()!;
      return {
        'name': data['name'],
        'phone': data['phone'],
      };
    } catch (error) {
      debugPrint('Error getting user info: $error');
      return {'name': null, 'phone': null};
    }
  }

  @override
  Future<void> addUserProfile(Profile profile) async {
    await _firestore.collection('profiles').doc(profile.id).set({
      ...profile.toJson(),
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateUserProfile(Profile profile) async {
    await _firestore.collection('profiles').doc(profile.id).update({
      ...profile.toJson(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteUserProfile(String userId) async {
    await _firestore.collection('profiles').doc(userId).delete();
  }

  @override
  Future<Profile?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('profiles').doc(userId).get();

    if (!doc.exists) return null;

    return Profile.fromJson(doc.data()!);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  @override
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
