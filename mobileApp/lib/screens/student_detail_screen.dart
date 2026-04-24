import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

import 'package:intl/intl.dart';
import '../utils/api_service.dart';
import 'add_student_wizard.dart';
import 'student_fees_history_screen.dart';

class StudentDetailScreen extends StatefulWidget {
  final String mongoId;
  final String studentName;
  final String studentId;

  const StudentDetailScreen({
    super.key,
    required this.mongoId,
    required this.studentName,
    required this.studentId,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _studentData;

  @override
  void initState() {
    super.initState();
    _loadFromCache();
    _fetchStudentDetails();
  }

  void _loadFromCache() {
    final cache = ApiService.allHomeData;
    if (cache != null && cache['students'] != null) {
      final cachedStudent = (cache['students'] as List).firstWhere(
        (s) => s['_id'] == widget.mongoId,
        orElse: () => null,
      );
      if (cachedStudent != null) {
        setState(() {
          _studentData = cachedStudent;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchStudentDetails() async {
    // Only show loader if we don't have cached data yet
    if (_studentData == null) {
      setState(() => _isLoading = true);
    }
    
    final result = await ApiService.getStudentById(widget.mongoId);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _studentData = result['data'];
        }
      });
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 70,
          flexibleSpace: Container(decoration: AppTheme.headerDecoration),
          title: const Text('Student Profile', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
      );
    }

    if (_studentData == null) {
      return Scaffold(
        appBar: AppBar(toolbarHeight: 70, flexibleSpace: Container(decoration: AppTheme.headerDecoration)),
        body: const Center(child: Text('Failed to load student details')),
      );
    }

    final personal = _studentData!['personalDetails'] ?? {};
    final academic = _studentData!['academicDetails'] ?? {};
    final fee = _studentData!['feeDetails'] ?? {};
    final parent = _studentData!['parentDetails'] ?? {};

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        toolbarHeight: 70,
        flexibleSpace: Container(
          decoration: AppTheme.headerDecoration,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            onPressed: () {
              if (_studentData != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddStudentWizard(initialData: _studentData),
                  ),
                ).then((_) => _fetchStudentDetails()); // Refresh after edit
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchStudentDetails,
        color: AppTheme.primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildProfileHeader(),
              _buildDetailSection(
                'Personal Details',
                Icons.person_outline,
                {
                  'Full Name': personal['fullName'] ?? widget.studentName,
                  'DOB': _formatDate(personal['dob']),
                  'Gender': personal['gender'] ?? 'N/A',
                  'Status': _studentData?['status'] ?? 'Active',
                },
              ),
              _buildDetailSection(
                'Academic Details',
                Icons.school_outlined,
                {
                  'Class': academic['className'] ?? 'N/A',
                  'Board': academic['board'] ?? 'N/A',
                  'Batch': academic['batchTime'] ?? 'N/A',
                  'School': academic['schoolName'] ?? 'N/A',
                  'Enrollment': _formatDate(academic['enrollmentDate']),
                },
              ),
              _buildDetailSection(
                'Fee Details',
                Icons.payments_outlined,
                {
                  'Fee Amount': '₹ ${fee['feeAmount'] ?? 0}',
                  'Due Day': '${fee['dueDayOfMonth'] ?? 1}${_getDaySuffix(fee['dueDayOfMonth'] ?? 1)} of Month',
                  'Cycle': fee['billCycle'] ?? 'N/A',
                  'Current Month Status': _studentData?['isPaidCurrentMonth'] == true ? 'Paid ✅' : 'Pending ⏳',
                },
                action: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentFeesHistoryScreen(
                          studentId: widget.mongoId,
                          studentName: widget.studentName,
                          studentRollId: widget.studentId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history_rounded, size: 18),
                  label: const Text('View History', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              _buildDetailSection(
                'Parent Details',
                Icons.family_restroom_outlined,
                {
                  'Guardian': parent['parentName'] ?? 'N/A',
                  'Mobile': parent['mobileNumber'] ?? 'N/A',
                  'Address': parent['address'] ?? 'N/A',
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  Widget _buildProfileHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      color: isDark ? AppTheme.surfaceDark : AppTheme.primaryBlue,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: isDark ? Colors.white10 : Colors.white,
            child: Text(
              widget.studentName.split(' ').map((e) => e[0]).join(''),
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.primaryBlue),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.studentName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            widget.studentId,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, Map<String, String> data, {Widget? action}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 20, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(icon, color: AppTheme.primaryBlue),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: action,
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: data.entries.map((e) => _buildDetailRow(e.key, e.value)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.white70 : AppTheme.textSecondary)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
        ],
      ),
    );
  }
}
