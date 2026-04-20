import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/status_chip.dart';
import 'student_detail_screen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, String>> _allTransactions = List.generate(20, (index) {
    final names = ['Ankit Sharma', 'Jane Doe', 'Rahul Patel', 'Sneha Gupta', 'Mehul Mehta'];
    final parents = ['Rajesh Sharma', 'Robert Doe', 'Suresh Patel', 'Sunita Gupta', 'Vijay Mehta'];
    final stds = ['10', '9', '10', '8', '7'];
    final mobiles = ['9876543210', '8765432109', '7654321098', '6543210987', '5432109876'];
    
    return {
      'name': names[index % names.length],
      'parent': parents[index % parents.length],
      'std': stds[index % stds.length],
      'mobile': mobiles[index % mobiles.length],
      'id': 'TXN_ID_$index',
      'date': '12/04/2026',
      'amount': '₹5,000',
      'status': 'Paid',
    };
  });

  List<Map<String, String>> _filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _filteredTransactions = _allTransactions;
    _searchController.addListener(_filterTransactions);
  }

  void _filterTransactions() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      if (query.length < 3) {
        _filteredTransactions = _allTransactions;
      } else {
        _filteredTransactions = _allTransactions.where((txn) {
          return txn['name']!.toLowerCase().contains(query) ||
                 txn['id']!.toLowerCase().contains(query) ||
                 txn['mobile']!.toLowerCase().contains(query) ||
                 txn['parent']!.toLowerCase().contains(query) ||
                 txn['std']!.toLowerCase().contains(query);
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
    return Scaffold(
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
                fillColor: Colors.white,
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
            child: _filteredTransactions.isEmpty
                ? const Center(child: Text('No transactions found'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredTransactions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildTransactionItem(context, _filteredTransactions[index], index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Map<String, String> txn, int index) {
    final name = txn['name']!;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentDetailScreen(studentName: name, studentId: 'STU001'),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              child: Text(name.split(' ').map((e) => e[0]).join(''), style: const TextStyle(color: AppTheme.primaryBlue)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text('Class ${txn['std']} • ${txn['mobile']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  txn['amount']!,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                StatusChip(label: txn['status']!, color: AppTheme.successGreen),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
