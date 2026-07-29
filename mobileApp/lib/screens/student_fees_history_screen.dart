import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/api_service.dart';
import '../widgets/status_chip.dart';
import 'package:intl/intl.dart';
import '../utils/receipt_helper.dart';

class StudentFeesHistoryScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String studentRollId;

  const StudentFeesHistoryScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.studentRollId,
  });

  @override
  State<StudentFeesHistoryScreen> createState() => _StudentFeesHistoryScreenState();
}

class _StudentFeesHistoryScreenState extends State<StudentFeesHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _payments = [];
  Map<String, dynamic>? _student;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getStudentPayments(widget.studentId);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _payments = result['data']['payments'];
          _student = result['data']['student'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        toolbarHeight: 70,
        flexibleSpace: Container(decoration: AppTheme.headerDecorationWithMode(isDark)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fee History',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              widget.studentName,
              style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 12),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : RefreshIndicator(
              onRefresh: _fetchHistory,
              child: _payments.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _payments.length,
                      itemBuilder: (context, index) {
                        return _buildPaymentCard(_payments[index]);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Icon(Icons.history_edu_rounded, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text('No payment history found', style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is String) {
      try { return DateTime.parse(val).toLocal(); } catch (_) { return null; }
    }
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val).toLocal();
    try { return (val as dynamic).toDate().toLocal(); } catch (_) { return null; }
  }

  Widget _buildPaymentCard(dynamic payment) {
    final date = _parseDate(payment['paymentDate'] ?? payment['createdAt']);
    final dateStr = date != null ? DateFormat('dd MMM yyyy').format(date) : 'Recent';
    final amount = payment['amount'] ?? payment['amountPaid'] ?? 0;
    final monthVal = payment['month'] ?? (date != null ? date.month : DateTime.now().month);
    final month = _getMonthName(monthVal);
    final year = payment['year'] ?? (date != null ? date.year : DateTime.now().year);
    final method = payment['paymentMethod'] ?? 'Cash';
    final receipt = payment['receiptNumber'] ?? 'N/A';

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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$month $year',
                        style: isDark ? GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white) : const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Paid on $dateStr',
                        style: isDark ? GoogleFonts.outfit(color: Colors.white60, fontSize: 13) : const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${NumberFormat('#,###').format(amount)}',
                      style: isDark ? GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.accentBlue,
                        fontSize: 20,
                      ) : const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryBlue,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.send_rounded, size: 18, color: Color(0xFF25D366)),
                      onPressed: () {
                        ReceiptHelper.sendWhatsAppMessage(
                          parentName: _student?['parentDetails']?['parentName'] ?? 'Parent',
                          mobileNumber: _student?['parentDetails']?['mobileNumber'] ?? '',
                          studentName: widget.studentName,
                          amount: amount.toString(),
                          month: month,
                          year: year.toString(),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoTag(Icons.account_balance_wallet_outlined, method, isDark),
                _buildInfoTag(Icons.receipt_long_outlined, receipt, isDark),
                const StatusChip(label: 'PAID', color: AppTheme.successGreen),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 14, color: isDark ? Colors.white60 : AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.outfit(fontSize: 12, color: isDark ? Colors.white60 : AppTheme.textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  String _getMonthName(dynamic month) {
    if (month == null) return DateFormat('MMMM').format(DateTime.now());
    if (month is int) {
      try { return DateFormat('MMMM').format(DateTime(2022, month)); } catch (_) {}
    }
    return month.toString();
  }
}
