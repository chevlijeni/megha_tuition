import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StudentDetailScreen extends StatelessWidget {
  final String studentName;
  final String studentId;

  const StudentDetailScreen({
    super.key,
    required this.studentName,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildDetailSection(
              'Personal Details',
              Icons.person_outline,
              {
                'Full Name': studentName,
                'DOB': '12 May 2008',
                'Gender': 'Male',
                'Class': 'Grade 10',
              },
            ),
            _buildDetailSection(
              'Academic Details',
              Icons.school_outlined,
              {
                'Division': 'A',
                'Board': 'GSEB',
                'Subjects': 'Maths, Science, English',
                'Enrollment': '01 June 2023',
              },
            ),
            _buildDetailSection(
              'Fee Details',
              Icons.payments_outlined,
              {
                'Fee Amount': '₹ 5,000 / month',
                'Due Date': '10th of Month',
                'Discount': '₹ 0',
                'Net Payable': '₹ 5,000',
              },
            ),
            _buildDetailSection(
              'Parent Details',
              Icons.family_restroom_outlined,
              {
                'Guardian': 'Robert Smith',
                'Relationship': 'Father',
                'Mobile': '+91 98765-43210',
                'Address': '123, Street Name, City',
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
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
              studentName.split(' ').map((e) => e[0]).join(''),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            studentName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            studentId,
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
