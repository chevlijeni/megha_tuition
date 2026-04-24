import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'transaction_list_screen.dart';
import '../utils/api_service.dart';
import 'package:intl/intl.dart';
import 'student_detail_screen.dart';
import '../widgets/status_chip.dart';
import '../utils/receipt_helper.dart';

class CollectFeeScreen extends StatefulWidget {
  final bool isTab;
  const CollectFeeScreen({super.key, this.isTab = false});

  @override
  State<CollectFeeScreen> createState() => _CollectFeeScreenState();
}

class _CollectFeeScreenState extends State<CollectFeeScreen> {
  String _selectedMode = 'Cash';
  final List<String> _modes = ['Cash', 'Online Payment', 'Bank Transfer'];
  dynamic _selectedStudent;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  Map<String, dynamic>? _stats;
  List<dynamic> _recentPayments = [];
  List<dynamic> _allStudents = [];
  bool _isLoading = true;
  final GlobalKey _autocompleteKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchFeesData();
  }

  Future<void> _fetchFeesData() async {
    setState(() => _isLoading = true);
    
    final statsResult = await ApiService.getDashboardStats();
    final paymentsResult = await ApiService.getPayments();
    final studentsResult = await ApiService.getStudents();
    
    if (mounted) {
      setState(() {
        if (statsResult['success']) _stats = statsResult['data'];
        if (paymentsResult['success']) {
          _recentPayments = (paymentsResult['data'] as List).take(4).toList();
        }
        if (studentsResult['success']) {
          _allStudents = studentsResult['data'] as List;
        }
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _searchController.dispose();
    _referenceController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        toolbarHeight: 80,
        flexibleSpace: Container(
          decoration: AppTheme.headerDecoration,
        ),
        leading: (!widget.isTab && Navigator.canPop(context)) ? const BackButton(color: Colors.white) : null,
        title: const Text(
          'Collect Fees',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchFeesData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryDashboard(),
            const SizedBox(height: 24),
            Text(
              'Search Student',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            _buildSearchSection(),
            if (_selectedStudent != null) ...[
              const SizedBox(height: 24),
              _buildSelectedStudentCard(),
              const SizedBox(height: 32),
              _buildPaymentForm(),
            ] else ...[
              const SizedBox(height: 48),
              _buildEmptyState(),
              const SizedBox(height: 48),
              _buildRecentActivity(),
            ],
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSummaryDashboard() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            label: 'Collected Today',
            value: '₹${NumberFormat('#,###').format(_stats?['collectedToday'] ?? 0)}',
            icon: Icons.payments_outlined,
            color: AppTheme.successGreen,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            label: 'Transactions',
            value: (_stats?['transactionsToday'] ?? 0).toString().padLeft(2, '0'),
            icon: Icons.receipt_long_outlined,
            color: AppTheme.primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.transparent),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textPrimary)),
          Text(label, style: GoogleFonts.outfit(fontSize: 12, color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : AppTheme.primaryBlue.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_search_outlined, size: 64, color: isDark ? Colors.white24 : AppTheme.primaryBlue.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            'Ready to collect fees?',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for a student to get started',
            style: GoogleFonts.outfit(color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Collections',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TransactionListScreen()),
                );
              },
              child: const Text('View All', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _isLoading 
          ? const Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ))
          : _recentPayments.isEmpty
            ? const Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No transactions today.'),
              ))
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentPayments.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildTransactionItem(context, _recentPayments[index]);
                },
              ),
      ],
    );
  }

  Widget _buildTransactionItem(BuildContext context, dynamic payment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final student = payment['student'] ?? {};
    final personal = student['personalDetails'] ?? {};
    final academic = student['academicDetails'] ?? {};
    final name = personal['fullName'] ?? 'Unknown Student';
    final amount = payment['amount'] ?? 0;
    
    String timeStr = 'Recent';
    if (payment['paymentDate'] != null) {
      final date = DateTime.parse(payment['paymentDate']).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 60) {
        timeStr = '${diff.inMinutes} mins ago';
      } else if (diff.inHours < 24) {
        timeStr = '${diff.inHours} hours ago';
      } else {
        timeStr = DateFormat('dd MMM').format(date);
      }
    }


    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            if (student['_id'] != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentDetailScreen(
                    mongoId: student['_id'],
                    studentName: name, 
                    studentId: student['studentId'] ?? '',
                  ),
                ),
              ).then((_) => _fetchFeesData());
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?', 
                      style: TextStyle(color: isDark ? Colors.white : AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name, 
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${academic['className'] ?? ''} • ${timeStr}', 
                        style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.8), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '₹${NumberFormat('#,###').format(amount)}', 
                      style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.textPrimary, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    StatusChip(
                      label: payment['paymentMethod'] ?? 'Paid',
                      color: AppTheme.successGreen,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Autocomplete<Map<String, dynamic>>(
      textEditingController: _searchController,
      focusNode: _searchFocusNode,
      displayStringForOption: (option) {
        final personal = option['personalDetails'] ?? {};
        return personal['fullName'] ?? '';
      },
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<Map<String, dynamic>>.empty();
        }
        return _allStudents.where((student) {
          final personal = student['personalDetails'] ?? {};
          final name = personal['fullName']?.toString().toLowerCase() ?? '';
          final id = student['studentId']?.toString().toLowerCase() ?? '';
          final query = textEditingValue.text.toLowerCase();
          return name.contains(query) || id.contains(query);
        }).cast<Map<String, dynamic>>();
      },
      onSelected: (selection) {
        setState(() {
          _selectedStudent = selection;
          final fee = selection['feeDetails']?['feeAmount'] ?? 0;
          _amountController.text = fee.toString();
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: focusNode.hasFocus 
                ? (isDark ? AppTheme.accentBlue : AppTheme.primaryBlue) 
                : (isDark ? Colors.white10 : Colors.grey.withOpacity(0.2)),
              width: 1.5,
            ),
            boxShadow: isDark ? null : [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Search by Name or ID',
              hintStyle: GoogleFonts.outfit(color: isDark ? Colors.white30 : Colors.grey),
              prefixIcon: Icon(Icons.search, color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            color: isDark ? AppTheme.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: MediaQuery.of(context).size.width - 32,
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final option = options.elementAt(index);
                  final personal = option['personalDetails'] ?? {};
                  final academic = option['academicDetails'] ?? {};
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                      child: Text(personal['fullName'][0].toUpperCase(), style: const TextStyle(color: AppTheme.primaryBlue)),
                    ),
                    title: Text(personal['fullName'], style: TextStyle(color: isDark ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                    subtitle: Text('ID: ${option['studentId']} • ${academic['className']}', style: TextStyle(color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary)),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedStudentCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final personal = _selectedStudent!['personalDetails'] ?? {};
    final academic = _selectedStudent!['academicDetails'] ?? {};
    final name = personal['fullName'] ?? 'Unknown';
    final feeAmount = _selectedStudent!['feeDetails']?['feeAmount'] ?? 0;
    
    final bool isPaid = _selectedStudent!['isPaidCurrentMonth'] ?? false;
    final paymentDateStr = isPaid ? _selectedStudent!['paymentDetails']['paymentDate'] : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPaid ? AppTheme.successGreen.withOpacity(0.05) : (isDark ? AppTheme.accentBlue.withOpacity(0.05) : AppTheme.primaryBlue.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPaid ? AppTheme.successGreen.withOpacity(0.5) : (isDark ? AppTheme.accentBlue.withOpacity(0.5) : AppTheme.primaryBlue.withOpacity(0.5)),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isPaid ? AppTheme.successGreen : (isDark ? Colors.white10 : AppTheme.primaryBlue.withOpacity(0.1)),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isPaid 
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(color: isDark ? Colors.white : AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
                Text(
                  'ID: ${_selectedStudent!['studentId']} • ${academic['className']} • Fee: ₹$feeAmount',
                  style: TextStyle(color: isDark ? Colors.white70 : AppTheme.textSecondary, fontSize: 14),
                ),
                if (isPaid && paymentDateStr != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline, color: AppTheme.successGreen, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Fees already collected on ${DateFormat('dd MMM yyyy').format(DateTime.parse(paymentDateStr).toLocal())}',
                          style: const TextStyle(color: AppTheme.successGreen, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedStudent = null;
              });
              // Clear the autocomplete search field
              _searchController.clear();
            },
            style: TextButton.styleFrom(
              foregroundColor: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue,
            ),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isPaid = _selectedStudent!['isPaidCurrentMonth'] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textPrimary),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _amountController,
          enabled: !isPaid,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount to Collect',
            prefixText: '₹ ',
            hintText: '5000',
          ),
        ),
        const SizedBox(height: 16),
        const Text('Payment Mode', style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: _modes.map((mode) {
            bool isSelected = _selectedMode == mode;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(mode),
                selected: isSelected,
                onSelected: isPaid ? null : (val) {
                  setState(() => _selectedMode = mode);
                },
                selectedColor: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue,
                backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected 
                    ? Colors.white 
                    : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected 
                      ? (isDark ? AppTheme.accentBlue : AppTheme.primaryBlue) 
                      : Colors.transparent,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _referenceController,
          enabled: !isPaid,
          decoration: const InputDecoration(
            labelText: 'Reference Number (Optional)',
            hintText: 'TXN123456789',
          ),
        ),
        const SizedBox(height: 48),
        ElevatedButton.icon(
          onPressed: (_isLoading || isPaid) ? null : () => _handleCollectPayment(),
          icon: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(isPaid ? Icons.check_circle_rounded : Icons.account_balance_wallet_rounded),
          label: Text(_isLoading ? 'Processing...' : (isPaid ? 'Already Collected' : 'Collect Payment')),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: isPaid ? (isDark ? Colors.white10 : Colors.grey[200]) : AppTheme.primaryBlue,
            foregroundColor: isPaid ? (isDark ? Colors.white30 : Colors.grey[400]) : Colors.white,
            disabledBackgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
            disabledForegroundColor: isDark ? Colors.white24 : Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Future<void> _handleCollectPayment() async {
    if (_selectedStudent == null) return;
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter amount')));
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.collectFee({
      'studentId': _selectedStudent!['_id'],
      'amount': double.parse(_amountController.text),
      'paymentMethod': _selectedMode,
      'referenceNumber': _referenceController.text.trim(),
    });

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        final transaction = result['data'];
        final student = transaction['student'] ?? {};
        final personal = student['personalDetails'] ?? {};
        final parent = student['parentDetails'] ?? {};
        
        final studentName = personal['fullName'] ?? 'Student';
        final parentName = parent['parentName'] ?? 'Parent';
        final mobile = parent['mobileNumber'] ?? '';
        final amount = transaction['amount']?.toString() ?? _amountController.text;
        final month = DateFormat('MMMM').format(DateTime.now());
        final year = DateTime.now().year.toString();

        // 1. Trigger PDF Sharing (Automatic)
        // We do this immediately to catch the user gesture context if possible
        ReceiptHelper.generateAndShareReceipt(
          studentName: studentName,
          studentId: student['studentId'] ?? '',
          amount: amount,
          month: month,
          year: year,
          paymentMode: _selectedMode,
          parentName: parentName,
          mobileNumber: mobile,
        ).catchError((e) => print('SHARE ERROR: $e'));

        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      }
    }
  }

  void _showSuccessDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final personal = _selectedStudent!['personalDetails'] ?? {};
    final studentName = personal['fullName'] ?? 'Student';
    final amount = _amountController.text;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppTheme.successGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text(
                  'Payment Successful!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                Text(
                  'Collected ₹$amount from $studentName',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary),
                ),
                const SizedBox(height: 32),
                
                // Done Button (Main Action)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    setState(() {
                      _selectedStudent = null;
                      _amountController.clear();
                      _referenceController.clear();
                      _searchController.clear(); // Important: Reset search
                      _selectedMode = 'Cash'; // Reset mode
                    });
                    _fetchFeesData(); // Refresh stats and list
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
