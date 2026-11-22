import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = FirebaseAuth.instance.currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pop(context, false);
      return;
    }

    final newName = _nameController.text.trim();

    if (newName == (user.displayName ?? '').trim()) {
      Navigator.pop(context, false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await user.updateDisplayName(newName);
      await user.reload();

      if (!mounted) return;

      Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = 'Unable to update profile. Please try again.';

      if (e.code == 'network-request-failed') {
        message = 'Network error. Check your internet connection.';
      } else if (e.code == 'requires-recent-login') {
        message = 'Please log in again and retry.';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update profile. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return AlertDialog(
      title: const Text(
        'Edit Profile',
        style: TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              enabled: !_isLoading,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name.';
                }
                if (value.trim().length < 2) {
                  return 'Name must contain at least 2 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: email,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
                helperText: 'Email address cannot be changed here.',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProfile,
          child: _isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}
