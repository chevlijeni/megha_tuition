import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/api_service.dart';
import '../widgets/status_chip.dart';
import 'package:intl/intl.dart';
import 'student_detail_screen.dart';
import 'student_fees_history_screen.dart';

class StatsDetailScreen extends StatefulWidget {
  final String type; // 'Students', 'Fees', 'Collections', 'Pending'
  final String title;
  final Color themeColor;

  const StatsDetailScreen({
    super.key,
    required this.type,
    required this.title,
    required this.themeColor,
  });

  @override
  State<StatsDetailScreen> createState() => _StatsDetailScreenState();
}

class _StatsDetailScreenState extends State<StatsDetailScreen> {
  List<dynamic> _data = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final cache = ApiService.allHomeData;
    if (cache == null) return;

    setState(() {
      if (widget.type == 'Students' || widget.type == 'Fees') {
        _data = cache['students'] ?? [];
      } else if (widget.type == 'Collections') {
        _data = cache['payments'] ?? [];
      } else if (widget.type == 'Pending') {
        _data = (cache['students'] as List? ?? []).where((s) => s['isPaidCurrentMonth'] == false).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        toolbarHeight: 70,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.themeColor, widget.themeColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _data.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _data.length,
              itemBuilder: (context, index) {
                return _buildListItem(_data[index], index);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: widget.themeColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No data available for ${widget.title}',
            style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(dynamic item, int index) {
    if (widget.type == 'Collections') {
      return _buildCollectionItem(item, index);
    } else {
      return _buildStudentItem(item, index);
    }
  }

  Widget _buildStudentItem(dynamic student, int index) {
    final personal = student['personalDetails'] ?? {};
    final academic = student['academicDetails'] ?? {};
    final fee = student['feeDetails'] ?? {};
    final name = personal['fullName'] ?? 'Unknown';
    final rollId = student['studentId'] ?? 'N/A';
    final amount = fee['feeAmount'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: widget.themeColor.withOpacity(0.1),
          child: Text(
            name.isNotEmpty ? name[0] : '?',
            style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          '${academic['className'] ?? ''} • $rollId',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹$amount',
              style: TextStyle(fontWeight: FontWeight.bold, color: widget.themeColor, fontSize: 14),
            ),
            StatusChip(
              label: student['isPaidCurrentMonth'] == true ? 'Paid' : 'Pending',
              color: student['isPaidCurrentMonth'] == true ? AppTheme.successGreen : AppTheme.errorRed,
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDetailScreen(
                mongoId: student['_id'],
                studentName: name,
                studentId: rollId,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCollectionItem(dynamic payment, int index) {
    final student = payment['student'] ?? {};
    final personal = student['personalDetails'] ?? {};
    final name = personal['fullName'] ?? 'Unknown';
    final amount = payment['amount'] ?? 0;
    final date = DateTime.parse(payment['paymentDate']).toLocal();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.successGreen.withOpacity(0.1),
          child: const Icon(Icons.receipt_long_rounded, color: AppTheme.successGreen, size: 20),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          '${DateFormat('dd MMM').format(date)} • ${payment['paymentMethod'] ?? 'Cash'}',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        trailing: Text(
          '₹$amount',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successGreen, fontSize: 16),
        ),
        onTap: () {
          if (student['_id'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentFeesHistoryScreen(
                  studentId: student['_id'],
                  studentName: name,
                  studentRollId: student['studentId'] ?? '',
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
