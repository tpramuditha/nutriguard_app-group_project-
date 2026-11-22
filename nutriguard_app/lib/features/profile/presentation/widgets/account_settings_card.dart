import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import 'change_password_dialog.dart';
import '../pages/my_stored_data_page.dart';
import '../../../../app/routes/route_names.dart';

class AccountSettingsCard extends StatelessWidget {
  final VoidCallback onLogout;

  const AccountSettingsCard({super.key, required this.onLogout});

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const ChangePasswordDialog(),
    );

    if (!context.mounted) return;

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.settings_outlined, color: AppColors.primary, size: 26),
              SizedBox(width: 10),
              Text(
                'Account Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _settingsItem(
            context,
            title: 'Change Password',
            onTap: () => _showChangePasswordDialog(context),
          ),
          const Divider(height: 1),
          _settingsItem(
            context,
            title: 'Privacy & Data',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyStoredDataPage()),
              );
            },
          ),
          const Divider(height: 1),
          _settingsItem(
            context,
            title: 'Help & Support',
            onTap: () {
              Navigator.pushNamed(context, RouteNames.helpSupport);
            },
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text(
              'Log Out',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }

  Widget _settingsItem(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.primaryDark),
      onTap: onTap,
    );
  }
}
