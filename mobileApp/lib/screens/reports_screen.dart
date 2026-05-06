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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        toolbarHeight: 80,
        flexibleSpace: Container(decoration: AppTheme.headerDecorationWithMode(isDark)),
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
              Text(
                'Collection Trend',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary
                ),
              ),
              const SizedBox(height: 16),
              _buildBarGraph(),
              const SizedBox(height: 32),
              Text(
                'Monthly Collection Review',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimary
                ),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), 
            blurRadius: 20
          )
        ],
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
                  Text(
                    'Monthly Goal Progress', 
                    style: TextStyle(
                      fontWeight: FontWeight.w600, 
                      fontSize: 13,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                    )
                  ),
                  Text(
                    '${(percent * 100).toInt()}%', 
                    style: TextStyle(
                      fontWeight: FontWeight.w800, 
                      color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue
                    )
                  ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(
          label, 
          style: TextStyle(
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary, 
            fontSize: 12, 
            fontWeight: FontWeight.w600
          )
        ),
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
        'collected': realData?['collected']?.toDouble() ?? 0.0,
        'expected': realData?['expected']?.toDouble() ?? 0.0,
      });
    }

    double maxVal = 1.0;
    for (var s in displayStats) {
      if (s['expected'] > maxVal) maxVal = s['expected'];
      if (s['collected'] > maxVal) maxVal = s['collected'];
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), 
            blurRadius: 20
          )
        ],
      ),
      child: Stack(
        children: [
          // Legend
          Positioned(
            right: 0,
            top: 0,
            child: Row(
              children: [
                _buildLegendItem('Expected', AppTheme.primaryBlue.withOpacity(0.3), isDark),
                const SizedBox(width: 12),
                _buildLegendItem('Collected', AppTheme.primaryBlue, isDark),
              ],
            ),
          ),
          
          // Background Guide Lines
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (index) => Container(
              height: 1,
              margin: const EdgeInsets.only(top: 32, bottom: 8),
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
            )),
          ),
          
          Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Y Axis Line
                    Container(width: 1.5, color: isDark ? Colors.white10 : Colors.grey.shade300),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: displayStats.map((s) {
                          return _buildDualBar(s['label'], s['expected'], s['collected'], maxVal);
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              // X Axis Line
              Container(height: 1.5, color: isDark ? Colors.white10 : Colors.grey.shade300),
              const SizedBox(height: 25),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.grey)),
      ],
    );
  }

  Widget _buildDualBar(String label, double expected, double collected, double maxVal) {
    final double expHeight = (120 * (expected / maxVal)).clamp(4.0, 120.0);
    final double collHeight = (120 * (collected / maxVal)).clamp(4.0, 120.0);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Expected Bar (Lighter)
            Container(
              width: 12,
              height: expHeight,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.1) : AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
            const SizedBox(width: 2),
            // Collected Bar (Primary)
            Container(
              width: 12,
              height: collHeight,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Transform.translate(
          offset: const Offset(0, 0),
          child: Text(
            label, 
            style: TextStyle(
              fontSize: 10, 
              fontWeight: FontWeight.w600, 
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary
            )
          ),
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
