import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'transaction_list_screen.dart';
import '../utils/api_service.dart';
import 'package:intl/intl.dart';
import 'student_detail_screen.dart';
import '../widgets/custom_snack_bar.dart';
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
  String _activeFilter = 'Pending'; // 'Pending' or 'All'

  @override
  void initState() {
    super.initState();
    _fetchFeesData();
    _searchController.addListener(() {
      if (_searchController.text.isEmpty && _selectedStudent != null) {
        _selectedStudent = null;
      }
      setState(() {});
    });
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

  List<dynamic> get _pendingStudents {
    final query = _searchController.text.trim().toLowerCase();
    return _allStudents.where((student) {
      final status = student['status'] ?? 'Active';
      if (status != 'Active') return false;

      final personal = student['personalDetails'] ?? {};
      final name = (personal['fullName'] ?? '').toString().toLowerCase();
      final id = (student['studentId'] ?? '').toString().toLowerCase();

      if (query.isNotEmpty) {
        if (!name.contains(query) && !id.contains(query)) {
          return false;
        }
      }

      final bool isPaid = student['isPaidCurrentMonth'] ?? false;
      final num pending = student['pendingBalance'] ?? student['balance'] ?? 0;
      if (_activeFilter == 'Pending') {
        if (isPaid) return false;
        if ((student.containsKey('pendingBalance') || student.containsKey('balance')) && pending <= 0) {
          return false;
        }
        return true;
      }
      return true;
    }).toList();
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
          'Fee Management',
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
              const SizedBox(height: 20),
              
              // Search Bar
              _buildSearchSection(),
              const SizedBox(height: 24),

              // If a student is searched/selected manually
              if (_selectedStudent != null) ...[
                _buildSelectedStudentCard(),
                const SizedBox(height: 24),
                _buildPaymentForm(),
              ] else ...[
                // Filter Tabs (Pending Fees vs All)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildFilterChip('Pending', 'Pending Fees'),
                        const SizedBox(width: 8),
                        _buildFilterChip('All', 'All Students'),
                      ],
                    ),
                    Text(
                      '${_pendingStudents.length} Students',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Pending Students List (Teacher-Friendly 1-Tap Collection)
                _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _pendingStudents.isEmpty
                        ? _buildAllPaidState()
                        : Column(
                            children: _pendingStudents.map((student) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildPendingStudentCard(student),
                              );
                            }).toList(),
                          ),

              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _activeFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.accentBlue : AppTheme.primaryBlue)
              : (isDark ? AppTheme.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? Colors.white10 : Colors.grey.withOpacity(0.2)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingStudentCard(dynamic student) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final personal = student['personalDetails'] ?? {};
    final academic = student['academicDetails'] ?? {};
    final feeDetails = student['feeDetails'] ?? {};
    final name = personal['fullName'] ?? 'Unknown Student';
    
    num pending = student['pendingBalance'] ?? student['balance'] ?? feeDetails['feeAmount'] ?? 0;
    num monthlyFee = feeDetails['feeAmount'] ?? 0;
    bool isPaid = student['isPaidCurrentMonth'] ?? false;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStudent = student;
          final fee = student['feeDetails']?['feeAmount'] ?? 0;
          _amountController.text = fee.toString();
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPaid
                ? AppTheme.successGreen.withOpacity(0.3)
                : (isDark ? Colors.white10 : Colors.grey.withOpacity(0.1)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Student Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isPaid
                      ? AppTheme.successGreen.withOpacity(0.1)
                      : (isDark ? AppTheme.accentBlue.withOpacity(0.15) : AppTheme.primaryBlue.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.outfit(
                      color: isPaid
                          ? AppTheme.successGreen
                          : (isDark ? AppTheme.accentBlue : AppTheme.primaryBlue),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Student Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${academic['className'] ?? ''} • ${academic['batchTime'] ?? 'Class'}',
                      style: GoogleFonts.outfit(
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? AppTheme.successGreen.withOpacity(0.1)
                            : AppTheme.errorRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isPaid ? 'Fully Paid' : '₹${NumberFormat('#,##0').format(pending > 0 ? pending : monthlyFee)} Pending',
                        style: GoogleFonts.outfit(
                          color: isPaid ? AppTheme.successGreen : AppTheme.errorRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 1-Tap Collect Fee Button
              ElevatedButton(
                onPressed: isPaid
                    ? null
                    : () {
                        _openQuickCollectBottomSheet(student);
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(80, 40),
                  backgroundColor: isPaid
                      ? (isDark ? Colors.white10 : Colors.grey[200])
                      : AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isPaid ? 'Paid' : 'Collect',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Teacher-friendly Quick Collect Bottom Sheet
  void _openQuickCollectBottomSheet(dynamic student) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final personal = student['personalDetails'] ?? {};
    final academic = student['academicDetails'] ?? {};
    final feeDetails = student['feeDetails'] ?? {};
    final name = personal['fullName'] ?? 'Student';
    num amountToCollect = student['pendingBalance'] ?? student['balance'] ?? feeDetails['feeAmount'] ?? 0;
    if (amountToCollect <= 0) amountToCollect = feeDetails['feeAmount'] ?? 0;

    final TextEditingController bottomSheetAmountController = TextEditingController(text: amountToCollect.toString());
    final TextEditingController bottomSheetRefController = TextEditingController();
    String selectedPaymentMode = 'Cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header with Student Name
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                        radius: 22,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Class: ${academic['className'] ?? ''} • ${academic['batchTime'] ?? ''}',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Amount Field
                  Text(
                    'Amount to Collect',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: bottomSheetAmountController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mode selection chips
                  Text(
                    'Payment Method',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: _modes.map((mode) {
                      bool isSelected = selectedPaymentMode == mode;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(mode),
                          selected: isSelected,
                          onSelected: (val) {
                            setBottomSheetState(() => selectedPaymentMode = mode);
                          },
                          selectedColor: AppTheme.primaryBlue,
                          backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppTheme.textPrimary),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Collect Button
                  ElevatedButton(
                    onPressed: () async {
                      if (bottomSheetAmountController.text.isEmpty) return;

                      Navigator.pop(context); // Close bottom sheet
                      setState(() => _isLoading = true);

                      final res = await ApiService.collectFee({
                        'studentId': student['_id'] ?? student['id'],
                        'amount': double.parse(bottomSheetAmountController.text),
                        'paymentMethod': selectedPaymentMode,
                        'referenceNumber': bottomSheetRefController.text.trim(),
                      });

                      if (mounted) {
                        setState(() => _isLoading = false);
                        if (res['success']) {
                          _selectedStudent = student;
                          _amountController.text = bottomSheetAmountController.text;
                          _showSuccessDialog();
                        } else {
                          CustomSnackBar.show(context, message: res['message'], isError: true);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'CONFIRM PAYMENT',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAllPaidState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded, size: 48, color: AppTheme.successGreen),
            ),
            const SizedBox(height: 12),
            Text(
              'All Fees Clear!',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'All active students have paid their fees.',
              style: GoogleFonts.outfit(color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary, fontSize: 13),
            ),
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
            : Column(
                children: _recentPayments.map((payment) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildTransactionItem(context, payment),
                  );
                }).toList(),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _searchFocusNode.hasFocus 
            ? (isDark ? AppTheme.accentBlue : AppTheme.primaryBlue) 
            : (isDark ? Colors.white10 : Colors.grey.withOpacity(0.2)),
          width: 1.5,
        ),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: 'Search by Name or ID...',
          hintStyle: GoogleFonts.outfit(color: isDark ? Colors.white30 : Colors.grey),
          prefixIcon: Icon(Icons.search, color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: isDark ? Colors.white70 : Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _selectedStudent = null;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
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
      CustomSnackBar.show(context, message: 'Please enter amount', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.collectFee({
      'studentId': _selectedStudent!['_id'] ?? _selectedStudent!['id'],
      'amount': double.parse(_amountController.text),
      'paymentMethod': _selectedMode,
      'referenceNumber': _referenceController.text.trim(),
    });

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        _showSuccessDialog();
      } else {
        CustomSnackBar.show(context, message: result['message'], isError: true);
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
                
                // Share on WhatsApp Button
                Link(
                  uri: Uri.parse(ReceiptHelper.getWhatsAppUrl(
                    parentName: _selectedStudent!['parentDetails']?['parentName'] ?? 'Parent',
                    mobileNumber: _selectedStudent!['parentDetails']?['mobileNumber'] ?? '',
                    studentName: personal['fullName'] ?? 'Student',
                    amount: amount,
                    month: DateFormat('MMMM').format(DateTime.now()),
                    year: DateTime.now().year.toString(),
                  )),
                  target: LinkTarget.blank,
                  builder: (context, followLink) => ElevatedButton.icon(
                    onPressed: followLink,
                    icon: const Icon(Icons.send_rounded, size: 20),
                    label: const Text('Share on WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Done Button (Main Action)
                TextButton(
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
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    foregroundColor: isDark ? Colors.white70 : AppTheme.textSecondary,
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
