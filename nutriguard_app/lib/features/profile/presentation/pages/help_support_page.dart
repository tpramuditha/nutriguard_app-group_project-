import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5FAFC),
        centerTitle: true,
        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),

            _buildSectionTitle('Getting Started'),
            _buildInfoCard(
              icon: Icons.rocket_launch_outlined,
              title: 'Getting Started with NutriGuard',
              description:
                  'Explore the dashboard, set your personal goals, '
                  'and start tracking your daily nutrition.',
              details: [
                'Set your personal nutrition goals in Profile & Settings.',
                'Add your dietary preferences and allergies.',
                'Use the Food Scanner to analyse meals.',
                'Check your progress to review your food and exercise history.',
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionTitle('Food & Nutrition'),
            _buildInfoCard(
              icon: Icons.camera_alt_outlined,
              title: 'Food Scanner Help',
              description:
                  'Learn how to scan food and review nutrition information.',
              details: [
                'Open Food Scanner from the Dashboard.',
                'Capture a clear image of your food.',
                'Review the detected food and serving size.',
                'Check the nutrition information before saving.',
                'AI food recognition may not always be accurate.',
              ],
            ),
            _buildInfoCard(
              icon: Icons.restaurant_menu_outlined,
              title: 'Meal Recommendations',
              description:
                  'Understand meal suggestions and your pantry ingredients.',
              details: [
                'Add available ingredients to My Pantry.',
                'Use Suggest Recipes to explore meal ideas.',
                'Review available and missing ingredients.',
                'Check recipe instructions and nutrition information.',
              ],
            ),
            _buildInfoCard(
              icon: Icons.calendar_month_outlined,
              title: 'Meal Planner & Food History',
              description:
                  'Learn how to manage planned meals and recorded meals.',
              details: [
                'Use Meal Planner to organise upcoming meals.',
                'Use Food History to review meals you have logged.',
                'Planned meals and consumed meals are tracked separately.',
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionTitle('Health & Exercise'),
            _buildInfoCard(
              icon: Icons.health_and_safety_outlined,
              title: 'Health Profile Help',
              description:
                  'Manage your health reports and monthly health markers.',
              details: [
                'Add health reports using the Health Profile.',
                'Record monthly health markers.',
                'Review previously saved health information.',
                'Check that entered values and units match your report.',
              ],
            ),
            _buildInfoCard(
              icon: Icons.fitness_center_outlined,
              title: 'Exercise Help',
              description:
                  'Explore exercise recommendations and track activities.',
              details: [
                'Open Exercise Recommendations to explore suggestions.',
                'Review your fitness goal and activity preferences.',
                'Log completed exercises.',
                'Use Exercise History to review recorded activities.',
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionTitle('Privacy & Account'),
            _buildInfoCard(
              icon: Icons.lock_outline,
              title: 'Privacy & Data Help',
              description: 'Understand how to manage your account information.',
              details: [
                'Use My Stored Data to review stored information.',
                'Use Export My Data to create a copy of your data.',
                'Manage notification and dietary preferences in Profile.',
                'Use Change Password to update your account password.',
                'Log out when you finish using your account.',
              ],
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Contact Support'),
            _buildContactCard(),
            const SizedBox(height: 20),

            _buildSectionTitle('About NutriGuard'),
            _buildAboutCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.support_agent, color: AppColors.primaryDark, size: 38),
          SizedBox(height: 12),
          Text(
            'How can we help you?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Find helpful information about NutriGuard features '
            'and how to use the application.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required List<String> details,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: Icon(icon, color: AppColors.primary, size: 25),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          children: details
              .map(
                (detail) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          detail,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.email_outlined, color: AppColors.primary, size: 28),
          SizedBox(height: 10),
          Text(
            'Contact Support',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Support contact details are not configured yet.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco_outlined, color: AppColors.primary, size: 28),
              SizedBox(width: 10),
              Text(
                'NutriGuard',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'NutriGuard is an AI-assisted nutrition and wellness '
            'application designed to help users track food intake, '
            'understand nutrition information, manage health records, '
            'and explore meal and exercise recommendations.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          SizedBox(height: 10),
          Text(
            'Nutrition and exercise suggestions are for informational '
            'purposes and do not replace professional medical advice.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
