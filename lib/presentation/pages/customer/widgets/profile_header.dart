import 'package:flutter/material.dart';
import '../../../../data/models/profile.dart';

class ProfileHeader extends StatelessWidget {
  final Profile profile;
  // final String phone;
  final VoidCallback onEditProfile;
  final VoidCallback? onNavigateToSellerDashboard;

  const ProfileHeader({
    super.key,
    required this.profile,
    // required this.phone,
    required this.onEditProfile,
    this.onNavigateToSellerDashboard,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            child: Icon(
              Icons.person,
              size: 50,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Text(
          //   phone,
          //   style: TextStyle(
          //     color: Colors.grey[600],
          //   ),
          // ),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: onEditProfile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(120, 40),
                ),
                child: const Text('Редактировать'),
              ),
              if (profile.isSeller) ...[],
            ],
          ),
        ],
      ),
    );
  }
}
