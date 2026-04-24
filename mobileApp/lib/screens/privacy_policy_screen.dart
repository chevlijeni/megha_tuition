import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        toolbarHeight: 70,
        flexibleSpace: Container(decoration: AppTheme.headerDecoration),
        title: const Text('Privacy Policy', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Privacy Policy',
              'Last updated: April 2024\n\nWelcome to Megha Tuition Classes. We value your privacy and are committed to protecting your personal data.',
            ),
            const Divider(height: 48),
            _buildSection(
              '1. Information We Collect',
              'We collect information that you provide to us directly, such as student names, contact details, academic information, and payment records. This information is used solely for managing tuition activities and tracking fee collections.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '2. How We Use Data',
              'Your data is used to:\n• Provide and maintain our service\n• Track student performance and fees\n• Notify you about important updates\n• Generate financial reports for administrative use',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '3. Data Security',
              'We implement industry-standard security measures to protect your data from unauthorized access, alteration, or disclosure. However, no method of transmission over the internet is 100% secure.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '4. Third-Party Services',
              'We do not sell or trade your personal information to third parties. We may use trusted third-party services (like MongoDB Atlas) to store and process data securely.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '5. Contact Us',
              'If you have any questions about this Privacy Policy, please contact Megha Mam directly at the coaching center.',
            ),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                '© 2024 Megha Tuition Classes. All rights reserved.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.6),
        ),
      ],
    );
  }
}
