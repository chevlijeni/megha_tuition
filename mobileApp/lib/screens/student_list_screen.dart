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
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddStudentWizard()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by name or ID...',
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
          _buildFilterBar(),
          const SizedBox(height: 16),
          Expanded(
            child: _filteredStudents.isEmpty
                ? const Center(child: Text('No students found matching filters'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  const SizedBox(width: 12),
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
              icon: const Icon(Icons.filter_list_off, color: AppTheme.errorRed),
              tooltip: 'Reset Filters',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {required bool isSelected, required VoidCallback onTap}) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryBlue,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300),
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isFiltered ? AppTheme.primaryBlue : Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
          style: TextStyle(
            color: isFiltered ? AppTheme.primaryBlue : AppTheme.textSecondary,
            fontWeight: isFiltered ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
          onChanged: onChanged,
          selectedItemBuilder: (context) {
            return items.map((String item) {
              return Center(
                child: Text(
                  isFiltered ? '$label: $value' : label,
                  style: TextStyle(
                    color: isFiltered ? AppTheme.primaryBlue : AppTheme.textSecondary,
                  ),
                ),
              );
            }).toList();
          },
          items: items.map<DropdownMenuItem<String>>((String itemValue) {
            return DropdownMenuItem<String>(
              value: itemValue,
              child: Text(itemValue),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, Map<String, String> student) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentDetailScreen(studentName: student['name']!, studentId: student['id']!),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              radius: 24,
              child: const Icon(Icons.person, color: AppTheme.primaryBlue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['name']!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text('${student['id']} • ${student['class']} • ${student['batch']}', 
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  student['fee']!,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                ),
                const SizedBox(height: 4),
                StatusChip(
                  label: student['status']!,
                  color: student['status'] == 'Paid' ? Colors.green : AppTheme.warningYellow,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
