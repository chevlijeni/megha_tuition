import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/status_chip.dart';
import '../utils/api_service.dart';
import 'student_fees_history_screen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allTransactions = [];
  List<dynamic> _filteredTransactions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
    _searchController.addListener(_filterTransactions);
  }

  Future<void> _fetchTransactions({bool forceRefresh = false}) async {
    setState(() => _isLoading = !forceRefresh && _allTransactions.isEmpty);
    
    final result = await ApiService.getPayments(useCache: !forceRefresh);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _allTransactions = result['data'];
          _filteredTransactions = _allTransactions;
        }
      });
    }
  }

  void _filterTransactions() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      if (query.isEmpty) {
        _filteredTransactions = _allTransactions;
      } else {
        _filteredTransactions = _allTransactions.where((payment) {
          final student = payment['student'] ?? {};
          final personal = student['personalDetails'] ?? {};
          final academic = student['academicDetails'] ?? {};
          
          final name = personal['fullName']?.toString().toLowerCase() ?? '';
          final mobile = personal['phoneNumber']?.toString().toLowerCase() ?? '';
          final className = academic['className']?.toString().toLowerCase() ?? '';
          final ref = payment['receiptNumber']?.toString().toLowerCase() ?? '';
          
          return name.contains(query) ||
                 mobile.contains(query) ||
                 ref.contains(query) ||
                 className.contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        toolbarHeight: 70,
        flexibleSpace: Container(
          decoration: AppTheme.headerDecoration,
        ),
        title: const Text(
          'Transaction History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Name, Mobile, Parent or Class...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                fillColor: isDark ? Colors.white10 : Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty && _searchController.text.length < 3)
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Type at least 3 characters to search',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => _fetchTransactions(forceRefresh: true),
                  child: _filteredTransactions.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                          const Center(child: Text('No transactions found')),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredTransactions.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildTransactionItem(context, _filteredTransactions[index]);
                        },
                      ),
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, dynamic payment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final student = payment['student'] ?? {};
    final personal = student['personalDetails'] ?? {};
    final academic = student['academicDetails'] ?? {};
    final name = personal['fullName'] ?? 'Unknown Student';
    final amount = payment['amount'] ?? 0;
    
    String dateStr = 'Unknown Date';
    if (payment['paymentDate'] != null) {
      final date = DateTime.parse(payment['paymentDate']).toLocal();
      dateStr = '${date.day}/${date.month}/${date.year}';
    }

    return InkWell(
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isDark ? Colors.white10 : AppTheme.primaryBlue.withOpacity(0.1),
              child: Text(name.isNotEmpty ? name[0] : '?', style: TextStyle(color: isDark ? Colors.white : AppTheme.primaryBlue)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : AppTheme.textPrimary),
                  ),
                  Text(
                    'Class ${academic['className'] ?? ''} • $dateStr', 
                    style: TextStyle(color: isDark ? Colors.white70 : AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹$amount',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : AppTheme.textPrimary),
                ),
                StatusChip(label: payment['paymentMethod'] ?? 'Paid', color: AppTheme.successGreen),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
