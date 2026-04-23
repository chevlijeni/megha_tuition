import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/api_service.dart';
import '../widgets/status_chip.dart';
import 'package:intl/intl.dart';

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
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        toolbarHeight: 70,
        flexibleSpace: Container(decoration: AppTheme.headerDecoration),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fee History',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              widget.studentName,
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
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

  Widget _buildPaymentCard(dynamic payment) {
    final date = DateTime.parse(payment['paymentDate']).toLocal();
    final dateStr = DateFormat('dd MMM yyyy').format(date);
    final amount = payment['amount'] ?? 0;
    final month = _getMonthName(payment['month']);
    final year = payment['year'];
    final method = payment['paymentMethod'] ?? 'Cash';
    final receipt = payment['receiptNumber'] ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$month $year',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Paid on $dateStr',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                Text(
                  '₹$amount',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryBlue,
                    fontSize: 18,
                  ),
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
                _buildInfoTag(Icons.account_balance_wallet_outlined, method),
                _buildInfoTag(Icons.receipt_long_outlined, receipt),
                const StatusChip(label: 'PAID', color: AppTheme.successGreen),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    return DateFormat('MMMM').format(DateTime(2022, month));
  }
}
