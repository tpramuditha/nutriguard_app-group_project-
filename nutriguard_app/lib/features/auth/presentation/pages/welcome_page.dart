import 'package:flutter/material.dart';

import '../widgets/onboarding_slide.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'image': 'assets/images/onboarding_welcome.png',
      'title': 'NutriGuard',
      'description': 'Personalized nutrition, backed by your health data',
      'button': 'Get Started',
    },
    {
      'image': 'assets/images/onboarding_scan.png',
      'title': 'Log Meals in Seconds',
      'description': 'Scan barcodes, snap photos, or search — logging food has never been easier.',
      'button': 'Next',
    },
    {
      'image': 'assets/images/onboarding_health.png',
      'title': 'Safe, Health-Aware Suggestions',
      'description': 'Every recommendation is filtered against your health markers before AI even sees it.',
      'button': 'Get Started',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Later we will navigate to the signup/onboarding setup.
      // For now, this button does nothing.
    }
  }

  void _goToLogin() {
    Navigator.pushNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        itemCount: _slides.length,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemBuilder: (context, index) {
          final slide = _slides[index];

          return OnboardingSlide(
            imagePath: slide['image']!,
            title: slide['title']!,
            description: slide['description']!,
            buttonText: slide['button']!,
            currentPage: _currentPage,

            // Show logo only on the first slide
            showLogo: index == 0,

            onButtonPressed: _nextPage,
            onLoginPressed: _goToLogin,
          );
        },
      ),
    );
  }
}
