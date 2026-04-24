import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _reportData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool force = false}) async {
    setState(() => _isLoading = true);
    final result = await ApiService.getSyncData(forceRefresh: force);
    if (mounted) {
      setState(() {
        if (result['success']) {
          _reportData = result['data'];
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _reportData == null) {
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 80,
          flexibleSpace: Container(decoration: AppTheme.headerDecoration),
          title: const Text('Fee Reports', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
      );
    }

    final students = (_reportData?['students'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        flexibleSpace: Container(decoration: AppTheme.headerDecoration),
        automaticallyImplyLeading: false,
        title: const Text('Fee Reports', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadData(force: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Collection Trend',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 16),
              _buildBarGraph(),
              const SizedBox(height: 32),
              const Text(
                'Monthly Collection Review',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 16),
              _buildSummaryCards(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final stats = _reportData?['stats'] ?? {};
    final collected = stats['totalCollection'] ?? 0;
    final totalExpected = stats['totalFees'] ?? 1; // avoid div by 0
    final percent = (collected / totalExpected).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSimpleStat('₹$collected', 'Collected', AppTheme.successGreen),
              _buildSimpleStat('₹${stats['pendingFees'] ?? 0}', 'Pending', AppTheme.errorRed),
            ],
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Monthly Goal Progress', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('${(percent * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryBlue)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 12,
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildBarGraph() {
    final earningsData = (_reportData?['monthlyEarnings'] as List?) ?? [];
    
    // Create exactly 6 slots for the last 6 months
    final now = DateTime.now();
    final List<Map<String, dynamic>> displayStats = [];
    
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final month = date.month;
      final year = date.year;
      
      // Find if we have real data for this month
      final realData = earningsData.firstWhere(
        (e) => e['_id']['month'] == month && e['_id']['year'] == year,
        orElse: () => null,
      );
      
      displayStats.add({
        'month': month,
        'label': _getMonthShort(month),
        'total': realData?['total']?.toDouble() ?? 0.0,
      });
    }

    double maxEarning = 1.0;
    for (var s in displayStats) {
      if (s['total'] > maxEarning) maxEarning = s['total'];
    }

    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Stack(
        children: [
          // Background Guide Lines
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (index) => Container(
              height: 1,
              margin: const EdgeInsets.only(top: 24, bottom: 8),
              color: Colors.grey.shade100,
            )),
          ),
          
          Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Y Axis Line
                    Container(width: 1.5, color: Colors.grey.shade300),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: displayStats.map((s) {
                          final factor = s['total'] / maxEarning;
                          final amountStr = s['total'] > 0 
                            ? '₹${(s['total'] / 1000).toStringAsFixed(1)}k' 
                            : '';
                          return _buildBar(s['label'], factor, amountStr);
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              // X Axis Line
              Padding(
                padding: const EdgeInsets.only(left: 0),
                child: Container(height: 1.5, color: Colors.grey.shade300),
              ),
              const SizedBox(height: 30), // Space for labels handled inside _buildBar is not enough now
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double heightFactor, String amount) {
    final double actualHeight = (120 * heightFactor).clamp(4.0, 120.0);
    final bool isZero = heightFactor == 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (amount.isNotEmpty)
          Text(amount, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue))
        else
          const SizedBox(height: 12),
        const SizedBox(height: 4),
        Container(
          width: 28,
          height: actualHeight,
          decoration: BoxDecoration(
            gradient: isZero ? null : AppTheme.primaryGradient,
            color: isZero ? Colors.grey.shade100 : null,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 4), // Small gap to X-axis
        // The label is now pushed further down
        Transform.translate(
          offset: const Offset(0, 32),
          child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        ),
      ],
    );
  }

  String _getMonthShort(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month < 1 || month > 12) return '???';
    return months[month - 1];
  }
}
