import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/api_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        toolbarHeight: 80,
        flexibleSpace: Container(
          decoration: AppTheme.headerDecoration,
        ),
        automaticallyImplyLeading: false,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildProfileHeader(),
            const SizedBox(height: 32),
            _buildSettingsSection(
              'Account',
              [
                _buildSettingItem(Icons.person_outline, 'Profile Information', 'Name, Email, Mobile'),
                _buildSettingItem(Icons.lock_outline, 'Privacy & Security', 'Change Password, Biometrics'),
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingsSection(
              'App Settings',
              [
                _buildSettingItem(Icons.notifications_none, 'Notifications', 'Fee Alerts, Announcements'),
                _buildSettingItem(Icons.language_outlined, 'Language', 'English'),
                _buildSettingItem(Icons.dark_mode_outlined, 'Appearance', 'Light Mode'),
              ],
            ),
            const SizedBox(height: 24),
            _buildSettingsSection(
              'More',
              [
                _buildSettingItem(Icons.help_outline, 'Help & Support', 'FAQs, Contact us'),
                _buildSettingItem(Icons.info_outline, 'About MT Classes', 'Version 1.0.0'),
              ],
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: OutlinedButton(
                onPressed: () async {
                  await ApiService.clearToken();
                  ApiService.clearCache();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Logout'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 40, color: AppTheme.primaryBlue),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin User',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                'admin@mtclasses.com',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: AppTheme.textSecondary),
      onTap: () {},
    );
  }
}
