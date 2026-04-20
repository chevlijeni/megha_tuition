import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_chip.dart';
import 'stats_detail_screen.dart';
import 'transaction_list_screen.dart';
import 'add_student_wizard.dart';
import 'student_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _navigateToDetail(BuildContext context, String title, Color color) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatsDetailScreen(title: title, themeColor: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        toolbarHeight: 70,
        flexibleSpace: Container(
          decoration: AppTheme.headerDecoration,
        ),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Megha Tuition, Gujarat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white.withOpacity(0.8), size: 20),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.notifications_rounded, color: Colors.white, size: 26),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
              childAspectRatio: 1.3, // Made cards shorter
              children: [
                StatCard(
                  title: 'Total Students',
                  value: '150',
                  icon: Icons.people_rounded,
                  iconColor: AppTheme.primaryBlue,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF194464), Color(0xFFCEDDE8)], // Dark brand blue to very light
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => _navigateToDetail(context, 'Students', AppTheme.primaryBlue),
                ),
                StatCard(
                  title: 'Pending Fees',
                  value: '₹45,000',
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: AppTheme.errorRed,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF194464), Color(0xFFCEDDE8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => _navigateToDetail(context, 'Pending Fees', AppTheme.errorRed),
                ),
                StatCard(
                  title: 'Total Collections',
                  value: '₹1,20,000',
                  icon: Icons.payments_rounded,
                  iconColor: AppTheme.successGreen,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF194464), Color(0xFFCEDDE8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => _navigateToDetail(context, 'Collections', AppTheme.successGreen),
                ),
                StatCard(
                  title: 'New Admissions',
                  value: '12',
                  icon: Icons.person_add_rounded,
                  iconColor: AppTheme.warningYellow,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF194464), Color(0xFFCEDDE8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onTap: () => _navigateToDetail(context, 'New Admissions', AppTheme.warningYellow),
                ),
              ],
            ),
            
            const SizedBox(height: 32),

            // Recent Transactions (Student Details)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionListScreen()));
                  },
                  child: const Text('View All', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildTransactionItem(context, index);
              },
            ),
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
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
  }

  Widget _buildTransactionItem(BuildContext context, int index) {
    final names = ['Jane Smith', 'John Doe', 'Alice Johnson', 'Bob Brown'];
    final name = names[index % names.length];
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentDetailScreen(studentName: name, studentId: 'STU00${index + 1}'),
              ),
            );
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
                      name[0], 
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
                        'Class 10 • Batch Morning', 
                        style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.8), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '₹5,000', 
                      style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textPrimary, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    StatusChip(
                      label: index % 2 == 0 ? 'Paid' : 'Pending',
                      color: index % 2 == 0 ? AppTheme.successGreen : AppTheme.warningYellow,
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
