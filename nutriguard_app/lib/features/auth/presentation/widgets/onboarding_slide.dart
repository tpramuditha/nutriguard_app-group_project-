import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

class OnboardingSlide extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;
  final String buttonText;
  final int currentPage;
  final bool showLogo;

  final VoidCallback onButtonPressed;
  final VoidCallback onLoginPressed;

  const OnboardingSlide({
    super.key,
    required this.imagePath,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.currentPage,
    required this.onButtonPressed,
    required this.onLoginPressed,
    this.showLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE0FFF3), Color(0xFFF4FFF9), Color(0xFFDFFFF0)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingMd,
          ),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Logo - only on the first slide
              if (showLogo) ...[
                Image.asset(
                  'assets/images/nutriguard_logo.png',
                  width: 64,
                  height: 64,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
              ],

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.primaryDark,
                  fontSize: showLogo ? 28 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                description,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary.copyWith(height: 1.45),
              ),

              const SizedBox(height: 12),

              // Main illustration
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Image.asset(imagePath, fit: BoxFit.contain),
                ),
              ),

              const SizedBox(height: 8),

              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == currentPage
                          ? AppColors.primary
                          : const Color(0xFFD5E8E3),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Main button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onButtonPressed,
                  child: Text(buttonText),
                ),
              ),

              const SizedBox(height: 12),

              // Login
              GestureDetector(
                onTap: onLoginPressed,
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.caption.copyWith(fontSize: 12),
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Log In',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
