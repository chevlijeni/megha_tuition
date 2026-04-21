import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'transaction_list_screen.dart';
import '../utils/api_service.dart';
import 'package:intl/intl.dart';
import 'student_detail_screen.dart';
import '../widgets/status_chip.dart';

class CollectFeeScreen extends StatefulWidget {
  const CollectFeeScreen({super.key});

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
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        flexibleSpace: Container(
          decoration: AppTheme.headerDecoration,
        ),
        automaticallyImplyLeading: false,
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
            const Text(
              'Search Student',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_search_outlined, size: 64, color: AppTheme.primaryBlue.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ready to collect fees?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Search for a student to get started',
            style: TextStyle(color: AppTheme.textSecondary),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0] : '?', 
                      style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 18),
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
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary),
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
                      style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textPrimary, fontSize: 15),
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
    return Autocomplete<Map<String, dynamic>>(
      textEditingController: _searchController,
      focusNode: _searchFocusNode,
      displayStringForOption: (option) => option['personalDetails']['fullName']!,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<Map<String, dynamic>>.empty();
        }
        return _allStudents.where((student) {
          final name = student['personalDetails']['fullName']!.toString().toLowerCase();
          final id = student['studentId']!.toString().toLowerCase();
          final query = textEditingValue.text.toLowerCase();
          return name.contains(query) || id.contains(query);
        }).cast<Map<String, dynamic>>();
      },
      onSelected: (selection) {
        setState(() {
          _selectedStudent = selection;
          final fee = selection['feeDetails']['feeAmount'] ?? 0;
          _amountController.text = fee.toString();
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: const InputDecoration(
              hintText: 'Search by Name or ID',
              prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedStudentCard() {
    final personal = _selectedStudent!['personalDetails'] ?? {};
    final academic = _selectedStudent!['academicDetails'] ?? {};
    final name = personal['fullName'] ?? 'Unknown';
    final feeAmount = _selectedStudent!['feeDetails']?['feeAmount'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppTheme.primaryBlue,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  'ID: ${_selectedStudent!['studentId']} • ${academic['className']} • Fee: ₹$feeAmount',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
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
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _amountController,
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
                onSelected: (val) {
                  setState(() => _selectedMode = mode);
                },
                selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _referenceController,
          decoration: InputDecoration(
            labelText: 'Reference Number (Optional)',
            hintText: 'TXN123456789',
          ),
        ),
        const SizedBox(height: 48),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _handleCollectPayment(),
          icon: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.account_balance_wallet_outlined),
          label: Text(_isLoading ? 'Processing...' : 'Collect Payment'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
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
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                const Text(
                  'Payment Successful!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                Text(
                  'Collected ₹${_amountController.text} from ${_selectedStudent!['personalDetails']['fullName']}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    setState(() {
                      _selectedStudent = null;
                      _amountController.clear();
                    });
                    _fetchFeesData(); // Refresh stats and list
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 45),
                    backgroundColor: AppTheme.primaryBlue,
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
