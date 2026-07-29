import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/api_service.dart';
import '../utils/receipt_helper.dart';
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

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is String) {
      try {
        return DateTime.parse(val).toLocal();
      } catch (_) {
        return null;
      }
    }
    if (val is int) {
      return DateTime.fromMillisecondsSinceEpoch(val).toLocal();
    }
    try {
      return (val as dynamic).toDate().toLocal();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadData() async {
    final cache = ApiService.allHomeData;
    if (cache != null) {
      _applyDataFromBundle(cache);
      return;
    }

    setState(() => _isLoading = true);
    final res = await ApiService.getSyncData();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success']) {
          _applyDataFromBundle(res['data']);
        }
      });
    }
  }

  void _applyDataFromBundle(Map<String, dynamic> bundle) {
    if (widget.type == 'Students' || widget.type == 'Fees') {
      _data = bundle['students'] ?? [];
    } else if (widget.type == 'Collections') {
      _data = bundle['payments'] ?? [];
    } else if (widget.type == 'Pending') {
      _data = (bundle['students'] as List? ?? []).where((s) => s['isPaidCurrentMonth'] != true).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        toolbarHeight: 70,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark ? [widget.themeColor.withOpacity(0.8), widget.themeColor.withOpacity(0.6)] : [widget.themeColor, widget.themeColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isDark ? widget.themeColor.withOpacity(0.2) : widget.themeColor.withOpacity(0.1),
          child: Text(
            name.isNotEmpty ? name[0] : '?',
            style: TextStyle(color: isDark ? Colors.white : widget.themeColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          name,
          style: isDark ? GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white) : const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          '${academic['className'] ?? ''} • ${academic['batchTime'] ?? ''}',
          style: isDark ? GoogleFonts.outfit(color: Colors.white60, fontSize: 12) : const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (student['isPaidCurrentMonth'] != true) ...[
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.send_rounded, color: Color(0xFF25D366), size: 20),
                onPressed: () {
                  final now = DateTime.now();
                  final months = [
                    'January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'
                  ];
                  final monthName = months[now.month - 1];
                  ReceiptHelper.sendWhatsAppReminder(
                    parentName: student['parentDetails']?['parentName'] ?? 'Parent',
                    mobileNumber: student['parentDetails']?['mobileNumber'] ?? '',
                    studentName: name,
                    amount: amount.toString(),
                    month: monthName,
                    year: now.year.toString(),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            SizedBox(
              height: 48,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '₹$amount',
                    style: isDark ? GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppTheme.accentBlue, fontSize: 15) : TextStyle(fontWeight: FontWeight.bold, color: widget.themeColor, fontSize: 13),
                  ),
                  StatusChip(
                    label: student['isPaidCurrentMonth'] == true ? 'Paid' : 'Pending',
                    color: student['isPaidCurrentMonth'] == true ? AppTheme.successGreen : AppTheme.errorRed,
                  ),
                ],
              ),
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
    final name = (personal['fullName'] ?? payment['studentName'] ?? payment['name'] ?? 'Student').toString();
    final amount = payment['amount'] ?? payment['amountPaid'] ?? 0;
    final date = _parseDate(payment['paymentDate'] ?? payment['createdAt']);
    final dateStr = date != null ? DateFormat('dd MMM').format(date) : 'Recent';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isDark ? AppTheme.successGreen.withOpacity(0.2) : AppTheme.successGreen.withOpacity(0.1),
          child: const Icon(Icons.receipt_long_rounded, color: AppTheme.successGreen, size: 20),
        ),
        title: Text(
          name,
          style: isDark ? GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white) : const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          '$dateStr • ${payment['paymentMethod'] ?? 'Cash'}',
          style: isDark ? GoogleFonts.outfit(color: Colors.white60, fontSize: 13) : const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        trailing: Text(
          '₹$amount',
          style: isDark ? GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppTheme.successGreen, fontSize: 16) : const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successGreen, fontSize: 16),
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
