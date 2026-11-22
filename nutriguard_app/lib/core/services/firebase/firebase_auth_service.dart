import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Register a new user with email and password
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = userCredential.user;

    if (user != null) {
      // Save the user's name in Firebase Authentication
      await user.updateDisplayName(name.trim());

      // Ask the user to verify their email address
      await user.sendEmailVerification();

      // Return to a signed-out state until login
      await _auth.signOut();
    }
  }

  // Login with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Refresh the user information from Firebase
    await userCredential.user?.reload();

    final user = _auth.currentUser;

    // Only allow verified accounts to continue
    if (user == null || !user.emailVerified) {
      await _auth.signOut();

      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'Please verify your email before logging in.',
      );
    }

    return userCredential;
  }

  // Change password after verifying the current password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;

    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'user-not-authenticated',
        message: 'Please log in to change your password.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);

    await user.updatePassword(newPassword);
  }

  // Sign out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
