import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'transaction_list_screen.dart';

class CollectFeeScreen extends StatefulWidget {
  const CollectFeeScreen({super.key});

  @override
  State<CollectFeeScreen> createState() => _CollectFeeScreenState();
}

class _CollectFeeScreenState extends State<CollectFeeScreen> {
  String _selectedMode = 'Cash';
  final List<String> _modes = ['Cash', 'Online Payment', 'Bank Transfer'];
  Map<String, String>? _selectedStudent;
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // Mock student data for demonstration
  final List<Map<String, String>> _allStudents = [
    {'name': 'Jane Smith', 'id': 'STU001', 'class': 'Grade 10', 'batch': 'Morning', 'fee': '₹6,500', 'status': 'Pending'},
    {'name': 'John Doe', 'id': 'STU002', 'class': 'Grade 9', 'batch': 'Afternoon', 'fee': '₹5,000', 'status': 'Paid'},
    {'name': 'Alice Johnson', 'id': 'STU003', 'class': 'Grade 10', 'batch': 'Evening', 'fee': '₹6,500', 'status': 'Pending'},
    {'name': 'Bob Brown', 'id': 'STU004', 'class': 'Grade 8', 'batch': 'Morning', 'fee': '₹4,500', 'status': 'Paid'},
    {'name': 'Ankit Sharma', 'id': 'STU005', 'class': 'Grade 10', 'batch': 'Morning', 'fee': '₹5,000', 'status': 'Pending'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collect Fees'),
      ),
      body: SingleChildScrollView(
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
    );
  }

  Widget _buildSummaryDashboard() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            label: 'Collected Today',
            value: '₹12,500',
            icon: Icons.payments_outlined,
            color: AppTheme.successGreen,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            label: 'Transactions',
            value: '08',
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
          const SizedBox(height: 24),
          const Text(
            'Ready to collect fees?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Search for a student to get started',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Tip: Search by Student ID for faster results',
                  style: TextStyle(fontSize: 13, color: Colors.orange, fontWeight: FontWeight.w500),
                ),
              ],
            ),
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
        _buildRecentItem('Rahul Verma', '₹4,500', '10 mins ago'),
        _buildRecentItem('Sneha Gupta', '₹6,000', '1 hour ago'),
        _buildRecentItem('Priya Singh', '₹3,500', '2 hours ago'),
      ],
    );
  }

  Widget _buildRecentItem(String name, String amount, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.successGreen.withOpacity(0.1),
            child: const Icon(Icons.check, size: 16, color: AppTheme.successGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                Text(time, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue)),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Autocomplete<Map<String, String>>(
      displayStringForOption: (option) => option['name']!,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<Map<String, String>>.empty();
        }
        return _allStudents.where((student) {
          return student['name']!.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
              student['id']!.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (selection) {
        setState(() {
          _selectedStudent = selection;
          // Parse fee amount (remove ₹ and commas) and autofill
          final feeStr = selection['fee'] ?? '';
          final numericFee = feeStr.replaceAll(RegExp(r'[₹, ]'), '');
          _amountController.text = numericFee;
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
                Text(_selectedStudent!['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  'ID: ${_selectedStudent!['id']} • ${_selectedStudent!['class']} • Pending: ${_selectedStudent!['fee']}',
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
        const TextField(
          decoration: InputDecoration(
            labelText: 'Reference Number (Optional)',
            hintText: 'TXN123456789',
          ),
        ),
        const SizedBox(height: 48),
        ElevatedButton.icon(
          onPressed: () => _showSuccessDialog(),
          icon: const Icon(Icons.account_balance_wallet_outlined),
          label: const Text('Collect Payment'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
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
                  'Collected ₹${_amountController.text} from ${_selectedStudent!['name']}',
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
