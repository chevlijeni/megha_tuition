import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/status_chip.dart';
import 'add_student_wizard.dart';
import 'student_detail_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  String _searchQuery = '';
  String _selectedBatch = 'All';
  String _selectedClass = 'All';

  // Mock student data for demonstration
  final List<Map<String, String>> _allStudents = [
    {'name': 'Jane Smith', 'id': 'STU001', 'class': 'Grade 10', 'batch': 'Morning', 'fee': '₹6,500', 'status': 'Pending'},
    {'name': 'John Doe', 'id': 'STU002', 'class': 'Grade 9', 'batch': 'Afternoon', 'fee': '₹5,000', 'status': 'Paid'},
    {'name': 'Alice Johnson', 'id': 'STU003', 'class': 'Grade 10', 'batch': 'Evening', 'fee': '₹6,500', 'status': 'Pending'},
    {'name': 'Bob Brown', 'id': 'STU004', 'class': 'Grade 8', 'batch': 'Morning', 'fee': '₹4,500', 'status': 'Paid'},
    {'name': 'Charlie Davis', 'id': 'STU005', 'class': 'Pre Primary', 'batch': 'Morning', 'fee': '₹3,500', 'status': 'Pending'},
    {'name': 'Diana Prince', 'id': 'STU006', 'class': 'Grade 7', 'batch': 'Afternoon', 'fee': '₹4,000', 'status': 'Paid'},
    {'name': 'Ethan Hunt', 'id': 'STU007', 'class': 'Grade 9', 'batch': 'Evening', 'fee': '₹5,000', 'status': 'Pending'},
    {'name': 'Fiona Gallagher', 'id': 'STU008', 'class': 'Grade 10', 'batch': 'Morning', 'fee': '₹6,500', 'status': 'Paid'},
  ];

  List<Map<String, String>> get _filteredStudents {
    return _allStudents.where((student) {
      final matchesSearch = student['name']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          student['id']!.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesBatch = _selectedBatch == 'All' || student['batch'] == _selectedBatch;
      final matchesClass = _selectedClass == 'All' || student['class'] == _selectedClass;
      return matchesSearch && matchesBatch && matchesClass;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        toolbarHeight: 120, // Taller for the search bar integration
        flexibleSpace: Container(
          decoration: AppTheme.headerDecoration,
        ),
        automaticallyImplyLeading: false,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
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
            child: _filteredStudents.isEmpty
                ? Center(
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
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final bool hasFilters = _searchQuery.isNotEmpty || _selectedBatch != 'All' || _selectedClass != 'All';

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
    final bool isFiltered = value != 'All';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      height: 40,
      decoration: BoxDecoration(
        color: isFiltered ? AppTheme.primaryBlue : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isFiltered ? AppTheme.primaryBlue : Colors.grey.shade200),
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
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, Map<String, String> student) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
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
              builder: (context) => StudentDetailScreen(studentName: student['name']!, studentId: student['id']!),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(2),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.person_rounded, color: AppTheme.primaryBlue, size: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['name']!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${student['id']} • ${student['class']}',
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
                    student['fee']!,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryBlue,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  StatusChip(
                    label: student['status']!,
                    color: student['status'] == 'Paid' ? AppTheme.successGreen : AppTheme.warningYellow,
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
