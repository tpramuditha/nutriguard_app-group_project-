import 'package:flutter/material.dart';

import '../../features/auth/presentation/pages/auth_gate.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/meals/presentation/pages/meal_recommendation_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/health/presentation/pages/health_profile_page.dart';
import '../../features/health/presentation/pages/log_health_marker_page.dart';
import '../../features/health/presentation/pages/add_health_report_page.dart';
import '../../features/health/presentation/pages/confirm_detected_values_page.dart';
import '../../features/health/presentation/pages/scan_health_report_page.dart';
import '../../features/food_scanner/presentation/pages/food_scanner_page.dart';
import '../../features/food_history/presentation/pages/food_history_page.dart';
import '../../features/planner/presentation/pages/daily_meal_planner_page.dart';
import '../../features/progress/presentation/pages/progress_page.dart';
import '../../features/exercise/presentation/pages/exercise_history_page.dart';
import '../../features/weight/presentation/pages/weight_history_page.dart';
import '../../features/exercise_recommendation/presentation/pages/exercise_recommendation_page.dart';
import '../../features/profile/presentation/pages/help_support_page.dart';
import 'route_names.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.welcome:
        return MaterialPageRoute(builder: (_) => const AuthGate());

      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case RouteNames.signup:
        return MaterialPageRoute(builder: (_) => const SignupPage());

      case RouteNames.dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardPage());

      case RouteNames.foodScanner:
        return MaterialPageRoute(builder: (_) => const FoodScannerPage());

      case RouteNames.foodHistory:
        return MaterialPageRoute(builder: (_) => const FoodHistoryPage());

      case RouteNames.mealRecommendation:
        return MaterialPageRoute(
          builder: (_) => const MealRecommendationPage(),
        );

      case RouteNames.planner:
        return MaterialPageRoute(builder: (_) => const DailyMealPlannerPage());

      case RouteNames.profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());

      case RouteNames.helpSupport:
        return MaterialPageRoute(builder: (_) => const HelpSupportPage());

      case RouteNames.health:
        return MaterialPageRoute(builder: (_) => const HealthProfilePage());

      case RouteNames.logHealthMarker:
        final selectedMonth = settings.arguments as DateTime?;

        return MaterialPageRoute(
          builder: (_) => LogHealthMarkerPage(selectedMonth: selectedMonth),
        );

      case RouteNames.addHealthReport:
        return MaterialPageRoute(builder: (_) => const AddHealthReportPage());

      case RouteNames.confirmDetectedValues:
        return MaterialPageRoute(
          builder: (_) => const ConfirmDetectedValuesPage(),
        );

      case RouteNames.scanHealthReport:
        return MaterialPageRoute(builder: (_) => const ScanHealthReportPage());

      case RouteNames.progress:
        return MaterialPageRoute(builder: (_) => const ProgressPage());

      case RouteNames.exercise:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ExerciseHistoryPage(),
        );

      case RouteNames.weightHistory:
        return MaterialPageRoute(builder: (_) => const WeightHistoryPage());

      case RouteNames.exerciseRecommendation:
        return MaterialPageRoute(
          builder: (_) => const ExerciseRecommendationPage(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Page not found'))),
        );
    }
  }
}
