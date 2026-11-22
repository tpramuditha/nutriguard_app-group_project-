import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/services/firebase/firebase_auth_service.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';

import '../../data/models/profile_preferences_model.dart';
import '../../data/repositories/profile_preferences_repository.dart';
import '../../data/models/notification_preferences_model.dart';

import '../widgets/profile_header.dart';
import '../widgets/personal_goals_card.dart';
import '../widgets/dietary_restrictions_card.dart';
import '../widgets/allergies_card.dart';
import '../widgets/notification_settings_card.dart';
import '../widgets/units_card.dart';
import '../widgets/account_settings_card.dart';
import '../widgets/logout_dialog.dart';
import '../widgets/edit_profile_dialog.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuthService _authService = FirebaseAuthService();

  final ProfilePreferencesRepository _preferencesRepository =
      ProfilePreferencesRepository();

  ProfilePreferencesModel _profilePreferences =
      ProfilePreferencesModel.defaultPreferences;

  NotificationPreferencesModel _notificationPreferences =
      NotificationPreferencesModel.defaultPreferences;

  bool _isLoadingPreferences = true;
  bool _isSavingPreferences = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfilePreferences();
  }

  Future<void> _loadProfilePreferences() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoadingPreferences = false;
        });
      }
      return;
    }

    try {
      final preferences = await _preferencesRepository.getProfilePreferences(
        userId: user.uid,
      );

      final notificationPreferences = await _preferencesRepository
          .getNotificationPreferences(userId: user.uid);

      if (!mounted) return;

      setState(() {
        _profilePreferences = preferences;
        _notificationPreferences = notificationPreferences;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load profile preferences.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPreferences = false;
        });
      }
    }
  }

  Future<void> _saveDietaryRestrictions(Set<String> restrictions) async {
    if (_isSavingPreferences) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to save your preferences.'),
        ),
      );
      return;
    }

    final previousPreferences = _profilePreferences;

    final updatedPreferences = ProfilePreferencesModel(
      dietaryRestrictions: restrictions.toList(),
      allergies: previousPreferences.allergies,
      unitSystem: previousPreferences.unitSystem,
    );

    setState(() {
      _profilePreferences = updatedPreferences;
      _isSavingPreferences = true;
    });

    try {
      await _preferencesRepository.saveProfilePreferences(
        userId: user.uid,
        preferences: updatedPreferences,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dietary restrictions saved successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _profilePreferences = previousPreferences;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to save dietary restrictions. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPreferences = false;
        });
      }
    }
  }

  Future<void> _saveAllergies(List<String> allergies) async {
    if (_isSavingPreferences) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to save your preferences.'),
        ),
      );
      return;
    }

    final previousPreferences = _profilePreferences;

    final updatedPreferences = ProfilePreferencesModel(
      dietaryRestrictions: previousPreferences.dietaryRestrictions,
      allergies: allergies,
      unitSystem: previousPreferences.unitSystem,
    );

    setState(() {
      _profilePreferences = updatedPreferences;
      _isSavingPreferences = true;
    });

    try {
      await _preferencesRepository.saveProfilePreferences(
        userId: user.uid,
        preferences: updatedPreferences,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Allergies saved successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _profilePreferences = previousPreferences;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save allergies. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPreferences = false;
        });
      }
    }
  }

  Future<void> _saveUnitSystem(String unitSystem) async {
    if (_isSavingPreferences) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to save your preferences.'),
        ),
      );
      return;
    }

    final previousPreferences = _profilePreferences;

    final updatedPreferences = ProfilePreferencesModel(
      dietaryRestrictions: previousPreferences.dietaryRestrictions,
      allergies: previousPreferences.allergies,
      unitSystem: unitSystem,
    );

    setState(() {
      _profilePreferences = updatedPreferences;
      _isSavingPreferences = true;
    });

    try {
      await _preferencesRepository.saveProfilePreferences(
        userId: user.uid,
        preferences: updatedPreferences,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Units saved successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _profilePreferences = previousPreferences;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save units. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPreferences = false;
        });
      }
    }
  }

  Future<void> _saveNotificationPreference(String setting, bool value) async {
    if (_isSavingPreferences) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to save your preferences.'),
        ),
      );
      return;
    }

    final previousPreferences = _notificationPreferences;

    final updatedPreferences = NotificationPreferencesModel(
      mealReminders: setting == 'mealReminders'
          ? value
          : previousPreferences.mealReminders,
      monthlyHealthMarkerReminders: setting == 'monthlyHealthMarkerReminders'
          ? value
          : previousPreferences.monthlyHealthMarkerReminders,
      aiSuggestionAlerts: setting == 'aiSuggestionAlerts'
          ? value
          : previousPreferences.aiSuggestionAlerts,
    );

    setState(() {
      _notificationPreferences = updatedPreferences;
      _isSavingPreferences = true;
    });

    try {
      await _preferencesRepository.saveNotificationPreferences(
        userId: user.uid,
        preferences: updatedPreferences,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification settings saved successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _notificationPreferences = previousPreferences;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to save notification settings. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPreferences = false;
        });
      }
    }
  }

  Future<void> _editProfile() async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => const EditProfileDialog(),
    );

    if (!mounted || updated != true) return;

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully.')),
    );
  }

  Future<void> _confirmLogout() async {
    if (_isLoggingOut) return;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => const LogoutDialog(),
    );

    if (!mounted || shouldLogout != true) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _authService.signOut();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.login,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  void _onBottomNavTap(int index) {
    if (index == 4) return;

    if (index == 0) {
      Navigator.pop(context);
      return;
    }

    const pages = ['Home', 'Scanner', 'Planner', 'Progress', 'Profile'];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${pages[index]} page is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5FAFC),
        centerTitle: true,
        title: const Text(
          'Profile & Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          TextButton(onPressed: _editProfile, child: const Text('Edit')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ProfileHeader(onEditProfile: _editProfile),

            const SizedBox(height: 16),

            PersonalGoalsCard(),

            const SizedBox(height: 16),

            DietaryRestrictionsCard(
              selectedRestrictions: _profilePreferences.dietaryRestrictions
                  .toSet(),
              onChanged: _saveDietaryRestrictions,
              enabled: !_isLoadingPreferences && !_isSavingPreferences,
            ),

            const SizedBox(height: 16),

            AllergiesCard(
              allergies: _profilePreferences.allergies,
              onChanged: _saveAllergies,
              enabled: !_isLoadingPreferences && !_isSavingPreferences,
            ),

            const SizedBox(height: 16),

            NotificationSettingsCard(
              mealReminders: _notificationPreferences.mealReminders,
              monthlyHealthMarkerReminders:
                  _notificationPreferences.monthlyHealthMarkerReminders,
              aiSuggestionAlerts: _notificationPreferences.aiSuggestionAlerts,
              onChanged: _saveNotificationPreference,
              enabled: !_isLoadingPreferences && !_isSavingPreferences,
            ),

            const SizedBox(height: 16),

            UnitsCard(
              selectedUnit: _profilePreferences.unitSystem,
              onChanged: _saveUnitSystem,
              enabled: !_isLoadingPreferences && !_isSavingPreferences,
            ),

            const SizedBox(height: 16),

            AccountSettingsCard(onLogout: _confirmLogout),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 4,
        onTap: _onBottomNavTap,
      ),
    );
  }
}
