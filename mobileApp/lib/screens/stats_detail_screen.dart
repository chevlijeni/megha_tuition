import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/status_chip.dart';

class StatsDetailScreen extends StatelessWidget {
  final String title;
  final Color themeColor;

  const StatsDetailScreen({
    super.key,
    required this.title,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: themeColor,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 15,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildDetailItem(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildChip('AllTime', isSelected: true),
            _buildChip('This Month'),
            _buildChip('Last Month'),
            const SizedBox(width: 16),
            const VerticalDivider(width: 1),
            const SizedBox(width: 16),
            _buildChip('Class 10'),
            _buildChip('Class 9'),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
        selected: isSelected,
        onSelected: (val) {},
        selectedColor: themeColor,
        checkmarkColor: Colors.white,
        backgroundColor: Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
      ),
    );
  }

  Widget _buildDetailItem(int index) {
    bool isPayment = title.contains('Collected') || title.contains('Pending') || title.contains('Overdue');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: themeColor.withOpacity(0.1),
            child: Text('${index + 1}', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPayment ? 'Transaction #TXN$index' : 'Student Name $index',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  isPayment ? 'John Doe • Class 10' : 'GSEB • Roll No: $index',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹5,000',
                style: TextStyle(fontWeight: FontWeight.bold, color: themeColor),
              ),
              const SizedBox(height: 4),
              StatusChip(
                label: title.contains('Pending') ? 'Pending' : (title.contains('Overdue') ? 'Overdue' : 'Paid'),
                color: title.contains('Pending') ? AppTheme.warningYellow : (title.contains('Overdue') ? AppTheme.errorRed : AppTheme.successGreen),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
