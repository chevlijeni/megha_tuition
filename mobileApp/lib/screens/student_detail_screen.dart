import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

import 'package:intl/intl.dart';
import '../utils/api_service.dart';
import 'add_student_wizard.dart';

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
    _fetchStudentDetails();
  }

  Future<void> _fetchStudentDetails() async {
    setState(() => _isLoading = true);
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

    return Scaffold(
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
                  'Status': _studentData!['status'] ?? 'Active',
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
                },
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
    return Container(
      width: double.infinity,
      color: AppTheme.primaryBlue,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Text(
              widget.studentName.split(' ').map((e) => e[0]).join(''),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
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

  Widget _buildDetailSection(String title, IconData icon, Map<String, String> data) {
    return Container(
      margin: const EdgeInsets.only(top: 20, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(icon, color: AppTheme.primaryBlue),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
