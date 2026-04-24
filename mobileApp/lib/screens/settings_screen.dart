import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/api_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getProfile();
    if (mounted) {
      setState(() {
        if (result['success']) {
          _userProfile = result['data'];
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeManager.instance,
      builder: (context, _) {
        final isDark = ThemeManager.instance.isDarkMode;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            toolbarHeight: 80,
            flexibleSpace: Container(decoration: AppTheme.headerDecorationWithMode(isDark)),
            automaticallyImplyLeading: false,
            title: const Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildProfileHeader(),
                        const SizedBox(height: 32),
                        _buildSettingsSection(
                          'Account',
                          [
                            _buildSettingItem(
                              Icons.person_outline, 
                              'Profile Information', 
                              'Name, Email, Mobile',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfileScreen(initialProfile: _userProfile),
                                  ),
                                ).then((_) => _loadProfile()); // Refresh after return
                              },
                            ),
                            _buildSettingItem(
                              Icons.lock_outline, 
                              'Privacy & Policy', 
                              'Terms, Data Protection',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSettingsSection(
                          'App Settings',
                          [
                            _buildSettingItem(
                              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, 
                              'Appearance', 
                              isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                              onTap: () => ThemeManager.instance.toggleTheme(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSettingsSection(
                          'More',
                          [
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
                ),
        );
      },
    );
  }

  Widget _buildProfileHeader() {
    final isDark = ThemeManager.instance.isDarkMode;
    final userName = _userProfile?['username'] ?? 'User';
    final userRole = _userProfile?['role'] ?? 'Admin';
    final email = _userProfile?['email'] ?? '$userName@mtclasses.com';

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName.toUpperCase(),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
              ),
              Text(
                '$userRole • $email',
                style: TextStyle(color: isDark ? Colors.white70 : AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    final isDark = ThemeManager.instance.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    final isDark = ThemeManager.instance.isDarkMode;
    return ListTile(
      leading: Icon(icon, color: isDark ? Colors.white70 : AppTheme.textSecondary),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : AppTheme.textSecondary)),
      trailing: Icon(Icons.chevron_right, size: 20, color: isDark ? Colors.white24 : AppTheme.textSecondary),
      onTap: onTap ?? () {},
    );
  }
}
