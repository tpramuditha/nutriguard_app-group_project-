import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../dashboard/presentation/pages/dashboard_page.dart';
import 'welcome_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
  }

  Future<bool> _isVerified(User user) async {
    await user.reload();
    return FirebaseAuth.instance.currentUser?.emailVerified ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Unable to check login status.')),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const WelcomePage();
        }

        return FutureBuilder<bool>(
          future: _isVerified(user),
          builder: (context, verificationSnapshot) {
            if (verificationSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (verificationSnapshot.hasError ||
                verificationSnapshot.data != true) {
              return const WelcomePage();
            }

            return const DashboardPage();
          },
        );
      },
    );
  }
}
