import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/api_service.dart';
import '../widgets/status_chip.dart';
import 'add_student_wizard.dart';
import 'student_detail_screen.dart';
import 'package:intl/intl.dart';

class StudentListScreen extends StatefulWidget {
  final bool showOnlyPending;
  final bool isTab;
  const StudentListScreen({super.key, this.showOnlyPending = false, this.isTab = false});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  String _searchQuery = '';
  String _selectedBatch = 'All';
  String _selectedClass = 'All';
  String _selectedBoard = 'All';
  late bool _showPendingOnly;
  bool _isLoading = false;
  List<dynamic> _allStudents = [];

  @override
  void initState() {
    super.initState();
    _showPendingOnly = widget.showOnlyPending;
    _fetchStudents();
  }

  Future<void> _fetchStudents({bool forceRefresh = false}) async {
    setState(() => _isLoading = !forceRefresh && _allStudents.isEmpty);
    
    // Pass useCache: !forceRefresh to indicate whether to use cache or hit network
    final result = await ApiService.getStudents(useCache: !forceRefresh);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _allStudents = result['data'];
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message']), backgroundColor: AppTheme.errorRed),
          );
        }
      });
    }
  }

  List<dynamic> get _filteredStudents {
    return _allStudents.where((student) {
      final personal = student['personalDetails'] ?? {};
      final academic = student['academicDetails'] ?? {};
      
      final name = personal['fullName']?.toString().toLowerCase() ?? '';
      final id = student['studentId']?.toString().toLowerCase() ?? '';
      
      final matchesSearch = name.contains(_searchQuery.toLowerCase()) ||
          id.contains(_searchQuery.toLowerCase());
          
      final matchesBatch = _selectedBatch == 'All' || academic['batchTime'] == _selectedBatch;
      final matchesClass = _selectedClass == 'All' || academic['className'] == _selectedClass;
      final matchesBoard = _selectedBoard == 'All' || academic['board'] == _selectedBoard;
      final matchesPending = !_showPendingOnly || student['isPaidCurrentMonth'] == false;
      
      return matchesSearch && matchesBatch && matchesClass && matchesBoard && matchesPending;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        toolbarHeight: 120, // Taller for the search bar integration
        flexibleSpace: Container(
          decoration: AppTheme.headerDecoration,
        ),
        leading: (!widget.isTab && Navigator.canPop(context)) ? const BackButton(color: Colors.white) : null,
        title: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Students',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 22),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddStudentWizard()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                style: TextStyle(fontSize: 14, color: isDark ? Colors.white : AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search students...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryBlue, size: 20),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildFilterBar(),
          const SizedBox(height: 8),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
              : RefreshIndicator(
                onRefresh: () => _fetchStudents(forceRefresh: true),
                color: AppTheme.primaryBlue,
                child: _filteredStudents.isEmpty
                    ? ListView( // Using ListView so RefreshIndicator works even when empty
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'No students found',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _filteredStudents.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildStudentCard(context, _filteredStudents[index]);
                        },
                      ),
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasFilters = _searchQuery.isNotEmpty || _selectedBatch != 'All' || _selectedClass != 'All' || _selectedBoard != 'All' || _showPendingOnly;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDropdownFilter(
                    label: 'Batch',
                    value: _selectedBatch,
                    items: ['All', 'Morning', 'Afternoon', 'Evening'],
                    onChanged: (val) => setState(() => _selectedBatch = val!),
                  ),
                  const SizedBox(width: 8),
                  _buildDropdownFilter(
                    label: 'Class',
                    value: _selectedClass,
                    items: ['All', 'Pre Primary', ...List.generate(9, (i) => 'Grade ${i + 1}')],
                    onChanged: (val) => setState(() => _selectedClass = val!),
                  ),
                  const SizedBox(width: 8),
                  _buildDropdownFilter(
                    label: 'Board',
                    value: _selectedBoard,
                    items: ['All', 'GSEB', 'CBSC'],
                    onChanged: (val) => setState(() => _selectedBoard = val!),
                  ),
                  const SizedBox(width: 8),
                    FilterChip(
                    label: Text(
                      'Pending',
                      style: TextStyle(
                        fontSize: 12,
                        color: _showPendingOnly ? Colors.white : (isDark ? Colors.white70 : AppTheme.textSecondary),
                        fontWeight: _showPendingOnly ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: _showPendingOnly,
                    onSelected: (val) => setState(() => _showPendingOnly = val),
                    selectedColor: AppTheme.errorRed,
                    checkmarkColor: Colors.white,
                    backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
                    side: BorderSide(color: _showPendingOnly ? AppTheme.errorRed : (isDark ? Colors.white10 : Colors.grey.shade200)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ],
              ),
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedBatch = 'All';
                  _selectedClass = 'All';
                  _selectedBoard = 'All';
                  _showPendingOnly = false;
                });
              },
              icon: const Icon(Icons.restart_alt_rounded, color: AppTheme.errorRed),
              tooltip: 'Reset Filters',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isFiltered = value != 'All';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      height: 40,
      decoration: BoxDecoration(
        color: isFiltered ? AppTheme.primaryBlue : (isDark ? AppTheme.surfaceDark : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isFiltered ? AppTheme.primaryBlue : (isDark ? Colors.white10 : Colors.grey.shade200)),
        boxShadow: [
          if (isFiltered)
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded, 
            color: isFiltered ? Colors.white : AppTheme.textSecondary,
            size: 20,
          ),
          onChanged: onChanged,
          selectedItemBuilder: (context) {
            return items.map((String item) {
              return Center(
                child: Text(
                  isFiltered ? value : label,
                  style: TextStyle(
                    color: isFiltered ? Colors.white : AppTheme.textSecondary,
                    fontWeight: isFiltered ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              );
            }).toList();
          },
          items: items.map<DropdownMenuItem<String>>((String itemValue) {
            return DropdownMenuItem<String>(
              value: itemValue,
              child: Text(
                itemValue,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppTheme.textPrimary),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, dynamic student) {
    final personal = student['personalDetails'] ?? {};
    final academic = student['academicDetails'] ?? {};
    final fee = student['feeDetails'] ?? {};
    
    final name = personal['fullName'] ?? 'Unknown';
    final studentId = student['studentId'] ?? 'N/A';
    final className = academic['className'] ?? '';
    final feeAmount = fee['feeAmount']?.toString() ?? '0';
    final status = student['status'] ?? 'Active';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDetailScreen(
                mongoId: student['_id'],
                studentName: name, 
                studentId: studentId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$className • ${academic['board'] ?? ''} • ${academic['batchTime'] ?? ''}',
                      style: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹$feeAmount',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryBlue,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  StatusChip(
                    label: status,
                    color: status == 'Active' ? AppTheme.successGreen : AppTheme.errorRed,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
