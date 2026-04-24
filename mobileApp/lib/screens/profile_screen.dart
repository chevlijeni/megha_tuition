import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../utils/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? initialProfile;
  const ProfileScreen({super.key, this.initialProfile});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _profile;
  
  // Controllers for editing
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    _usernameController = TextEditingController(text: _profile?['username'] ?? '');
    _emailController = TextEditingController(text: _profile?['email'] ?? '');
    _mobileController = TextEditingController(text: _profile?['mobileNumber'] ?? '');
    
    if (_profile == null) {
      _fetchProfile();
    }
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getProfile();
    if (mounted) {
      setState(() {
        if (result['success']) {
          _profile = result['data'];
          _usernameController.text = _profile?['username'] ?? '';
          _emailController.text = _profile?['email'] ?? '';
          _mobileController.text = _profile?['mobileNumber'] ?? '';
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _handleUpdate() async {
    setState(() => _isLoading = true);
    final result = await ApiService.updateProfile({
      'username': _usernameController.text,
      'email': _emailController.text,
      'mobileNumber': _mobileController.text,
    });

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppTheme.successGreen),
        );
        setState(() {
          _profile = result['data'];
          _isEditing = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        toolbarHeight: 70,
        flexibleSpace: Container(decoration: AppTheme.headerDecoration),
        title: Text(_isEditing ? 'Edit Profile' : 'Profile', style: const TextStyle(color: Colors.white)),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading && _profile == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildAvatarSection(),
                  const SizedBox(height: 32),
                  if (_isEditing) _buildEditForm() else _buildInfoList(),
                  if (_isEditing) ...[
                    const SizedBox(height: 40),
                    _buildActionButtons(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildAvatarSection() {
    final initials = (_profile?['username'] ?? 'U').substring(0, 1).toUpperCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue, width: 2),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.primaryBlue),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _profile?['role']?.toUpperCase() ?? 'ADMIN',
            style: TextStyle(
              letterSpacing: 1.2, 
              fontWeight: FontWeight.w800, 
              color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue, 
              fontSize: 12
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoList() {
    return Column(
      children: [
        _buildInfoItem(Icons.person_outline, 'Username', _profile?['username'] ?? 'N/A'),
        _buildInfoItem(Icons.email_outlined, 'Email Address', _profile?['email'] ?? 'Not set'),
        _buildInfoItem(Icons.phone_outlined, 'Mobile Number', _profile?['mobileNumber'] ?? 'Not set'),
        _buildInfoItem(Icons.calendar_today_outlined, 'Member Since', _formatDate(_profile?['createdAt'])),
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        _buildTextField('Username', _usernameController, Icons.person_outline),
        const SizedBox(height: 20),
        _buildTextField('Email Address', _emailController, Icons.email_outlined),
        const SizedBox(height: 20),
        _buildTextField('Mobile Number', _mobileController, Icons.phone_outlined),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      style: TextStyle(color: isDark ? Colors.white : AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300),
        ),
        filled: isDark,
        fillColor: isDark ? Colors.white.withOpacity(0.03) : null,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isLoading ? null : _handleUpdate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _isEditing = false),
          child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), 
            blurRadius: 10
          )
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 22),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label, 
                style: TextStyle(
                  fontSize: 12, 
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary
                )
              ),
              const SizedBox(height: 4),
              Text(
                value, 
                style: TextStyle(
                  fontSize: 15, 
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                )
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
