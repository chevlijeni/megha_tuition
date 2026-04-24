import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_chip.dart';
import 'stats_detail_screen.dart';
import 'transaction_list_screen.dart';
import 'add_student_wizard.dart';
import 'student_list_screen.dart';
import 'student_fees_history_screen.dart';
import '../utils/api_service.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  List<dynamic> _recentPayments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData({bool forceRefresh = false}) async {
    setState(() => _isLoading = !forceRefresh && _stats == null);
    
    // Use the sync data which includes stats and payments
    final result = await ApiService.getSyncData(forceRefresh: forceRefresh);
    
    if (mounted) {
      setState(() {
        if (result['success']) {
          _stats = result['data']['stats'];
          // Take only the first 4 for the recent list
          _recentPayments = (result['data']['payments'] as List).take(4).toList();
        }
        _isLoading = false;
      });
    }
  }

  void _navigateToDetail(BuildContext context, String type) {
    String title = '';
    Color color = AppTheme.primaryBlue;

    if (type == 'Students') {
      title = 'Total Students';
      color = AppTheme.primaryBlue;
    } else if (type == 'Expected') {
      // Per user request, no inner screen for Total Fees (Monthly collected)
      return; 
    } else if (type == 'Collections') {
      title = 'Recent Collections';
      color = AppTheme.successGreen;
    } else if (type == 'Pending') {
      title = 'Pending Fees';
      color = AppTheme.errorRed;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatsDetailScreen(
          type: type,
          title: title,
          themeColor: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeManager.instance,
      builder: (context, _) {
        final isDark = ThemeManager.instance.isDarkMode;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            toolbarHeight: 70,
            flexibleSpace: Container(
              decoration: AppTheme.headerDecorationWithMode(isDark),
            ),
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Megha Tuition, Gujarat',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white.withOpacity(0.8), size: 20),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, 
                    color: Colors.white, 
                    size: 24
                  ),
                  onPressed: () => ThemeManager.instance.toggleTheme(),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
        onRefresh: () => _fetchDashboardData(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Professional Stats Grid (Optimized Size)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  StatCard(
                    title: 'Total Students',
                    value: _stats?['totalStudents']?.toString() ?? '...',
                    icon: Icons.people_rounded,
                    iconColor: AppTheme.accentBlue,
                    gradient: isDark ? null : const LinearGradient(
                      colors: [Color(0xFF194464), Color(0xFFCEDDE8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => _navigateToDetail(context, 'Students'),
                  ),
                  StatCard(
                    title: 'Total Fees',
                    value: '₹${NumberFormat('#,##,000').format(_stats?['totalFees'] ?? 0)}',
                    icon: Icons.assignment_rounded,
                    iconColor: AppTheme.warningYellow,
                    gradient: isDark ? null : const LinearGradient(
                      colors: [Color(0xFF194464), Color(0xFFCEDDE8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => _navigateToDetail(context, 'Expected'),
                  ),
                  StatCard(
                    title: 'Pending Fees',
                    value: '₹${NumberFormat('#,##,000').format(_stats?['pendingFees'] ?? 0)}',
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: AppTheme.errorRed,
                    gradient: isDark ? null : const LinearGradient(
                      colors: [Color(0xFF194464), Color(0xFFCEDDE8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => _navigateToDetail(context, 'Pending'),
                  ),
                  StatCard(
                    title: 'Total Collections',
                    value: '₹${NumberFormat('#,##,000').format(_stats?['totalCollection'] ?? 0)}',
                    icon: Icons.payments_rounded,
                    iconColor: AppTheme.successGreen,
                    gradient: isDark ? null : const LinearGradient(
                      colors: [Color(0xFF194464), Color(0xFFCEDDE8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => _navigateToDetail(context, 'Collections'),
                  ),
                ],
              ),
            
            SizedBox(height: 32),

            // Recent Transactions (Student Details)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionListScreen()));
                  },
                  child: Text('View All', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                ),
              ],
            ),
            SizedBox(height: 16),
            _isLoading 
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ))
              : _recentPayments.isEmpty
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No transactions yet.'),
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
            const SizedBox(height: 100),
          ],
        ),
      ),
    ),
      floatingActionButton: isDark 
        ? Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1e3c72), Color(0xFF2a5298)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AddStudentWizard()));
              },
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              highlightElevation: 0,
              icon: const Icon(Icons.person_add_rounded, size: 24),
              label: Text(
                'ADD STUDENT', 
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, letterSpacing: 1.0, fontSize: 13),
              ),
            ),
          )
        : FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AddStudentWizard()));
            },
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 6,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('ADD STUDENT', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ),
        );
      },
    );
  }

  Widget _buildTransactionItem(BuildContext context, dynamic payment) {
    final isDark = ThemeManager.instance.isDarkMode;
    final student = payment['student'] ?? {};
    final personal = student['personalDetails'] ?? {};
    final academic = student['academicDetails'] ?? {};
    final name = personal['fullName'] ?? 'Unknown Student';
    final amount = payment['amount'] ?? 0;
    
    // Format date
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
        color: Theme.of(context).cardColor,
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
                  builder: (context) => StudentFeesHistoryScreen(
                    studentId: student['_id'],
                    studentName: name, 
                    studentRollId: student['studentId'] ?? '',
                  ),
                ),
              ).then((_) => _fetchDashboardData());
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
                        style: TextStyle(color: (isDark ? Colors.white70 : AppTheme.textSecondary).withOpacity(0.8), fontSize: 13),
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
}
