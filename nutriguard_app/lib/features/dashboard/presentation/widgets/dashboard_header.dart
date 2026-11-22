import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final displayName = user?.displayName?.trim() ?? '';
    final firstName = displayName.isNotEmpty
        ? displayName.split(' ').first
        : 'there';

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning,'
        : hour < 17
        ? 'Good Afternoon,'
        : 'Good Evening,';

    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.primaryLight,
          backgroundImage: user?.photoURL != null && user!.photoURL!.isNotEmpty
              ? NetworkImage(user.photoURL!)
              : null,
          child: user?.photoURL == null || user!.photoURL!.isEmpty
              ? const Icon(Icons.person, color: AppColors.primary, size: 30)
              : null,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '$firstName 👋',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, size: 28),
          color: AppColors.primaryDark,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notifications will be added later.'),
              ),
            );
          },
        ),
      ],
    );
  }
}
