import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'app/app.dart';

Future<void> main() async {
  // Initialize Flutter before using Firebase plugins.
  WidgetsFlutterBinding.ensureInitialized();

  // Connect the app to the NutriGuard Firebase project.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Start the NutriGuard application.
  runApp(const NutriGuardApp());
}
