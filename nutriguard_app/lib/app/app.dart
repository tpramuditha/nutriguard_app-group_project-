import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'routes/route_names.dart';

class NutriGuardApp extends StatelessWidget {
  const NutriGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriGuard',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,

      initialRoute: RouteNames.welcome,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
