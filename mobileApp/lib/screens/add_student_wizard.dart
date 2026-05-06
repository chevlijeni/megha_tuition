import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/api_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import '../widgets/custom_snack_bar.dart';

class AddStudentWizard extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const AddStudentWizard({super.key, this.initialData});

  @override
  State<AddStudentWizard> createState() => _AddStudentWizardState();
}

class _AddStudentWizardState extends State<AddStudentWizard> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isEditMode = false;
  String? _mongoId;

  // Form Keys
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();
  final _step4Key = GlobalKey<FormState>();

  // Data Controllers/Variables
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _enrollmentController = TextEditingController(
    text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
  );
  String? _selectedGender;
  final TextEditingController _feeAmountController = TextEditingController();
  String? _selectedBoard;
  String? _selectedClass;
  String? _selectedBatchTime;
  String? _selectedBillCycle;
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController(text: '10');
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.initialData != null;
    if (_isEditMode) {
      _mongoId = widget.initialData!['_id'];
      final personal = widget.initialData!['personalDetails'] ?? {};
      final academic = widget.initialData!['academicDetails'] ?? {};
      final fee = widget.initialData!['feeDetails'] ?? {};
      final parent = widget.initialData!['parentDetails'] ?? {};

      _fullNameController.text = personal['fullName'] ?? '';
      _selectedGender = personal['gender'];
      if (personal['dob'] != null) {
        try {
          DateTime dt = DateTime.parse(personal['dob']);
          _dobController.text = DateFormat('dd/MM/yyyy').format(dt);
        } catch (e) {}
      }

      _selectedClass = academic['className'];
      _selectedBoard = academic['board'];
      _selectedBatchTime = academic['batchTime'];
      _schoolNameController.text = academic['schoolName'] ?? '';
      if (academic['enrollmentDate'] != null) {
        try {
          DateTime dt = DateTime.parse(academic['enrollmentDate']);
          _enrollmentController.text = DateFormat('dd/MM/yyyy').format(dt);
        } catch (e) {}
      }

      _feeAmountController.text = fee['feeAmount']?.toString() ?? '';
      _dueDateController.text = fee['dueDayOfMonth']?.toString() ?? '1';
      _selectedBillCycle = fee['billCycle'];

      _parentNameController.text = parent['parentName'] ?? '';
      _mobileNumberController.text = parent['mobileNumber'] ?? '';
      _addressController.text = parent['address'] ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _enrollmentController.dispose();
    _feeAmountController.dispose();
    _schoolNameController.dispose();
    _dueDateController.dispose();
    _parentNameController.dispose();
    _mobileNumberController.dispose();
    _addressController.dispose();
    _pageController.dispose();
    super.dispose();
  }
  
  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller, {bool firstDateToday = false}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: firstDateToday ? DateTime.now() : DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _nextStep() {
    bool isValid = false;
    if (_currentStep == 0) {
      isValid = _step1Key.currentState!.validate();
    } else if (_currentStep == 1) {
      isValid = _step2Key.currentState!.validate();
    } else if (_currentStep == 2) {
      isValid = _step3Key.currentState!.validate();
    } else if (_currentStep == 3) {
      isValid = _step4Key.currentState!.validate();
    }

    if (isValid) {
      if (_currentStep < 3) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _saveStudent();
      }
    }
  }

  void _backStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveStudent() async {
    setState(() => _isLoading = true);

    DateTime? dob;
    if (_dobController.text.isNotEmpty) {
      try {
        dob = DateFormat('dd/MM/yyyy').parse(_dobController.text);
      } catch (e) {}
    }
    
    DateTime enrollmentDate = DateTime.now();
    try {
      enrollmentDate = DateFormat('dd/MM/yyyy').parse(_enrollmentController.text);
    } catch (e) {}

    final studentData = {
      "studentId": _isEditMode 
          ? widget.initialData!['studentId'] 
          : "STU-${DateTime.now().millisecondsSinceEpoch}",
      "personalDetails": {
        "fullName": _fullNameController.text.trim(),
        "dob": dob?.toIso8601String(),
        "gender": _selectedGender
      },
      "academicDetails": {
        "className": _selectedClass,
        "board": _selectedBoard,
        "batchTime": _selectedBatchTime,
        "schoolName": _schoolNameController.text.trim(),
        "enrollmentDate": enrollmentDate.toIso8601String()
      },
      "feeDetails": {
        "feeAmount": int.tryParse(_feeAmountController.text) ?? 0,
        "dueDayOfMonth": int.tryParse(_dueDateController.text) ?? 1,
        "billCycle": _selectedBillCycle
      },
      "parentDetails": {
        "parentName": _parentNameController.text.trim(),
        "mobileNumber": _mobileNumberController.text.trim(),
        "address": _addressController.text.trim()
      }
    };

    final result = _isEditMode 
        ? await ApiService.updateStudent(_mongoId!, studentData)
        : await ApiService.createStudent(studentData);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      CustomSnackBar.show(context, message: _isEditMode ? 'Student details updated successfully.' : 'New student registered successfully.');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context, true);
      });
    } else {
      CustomSnackBar.show(context, message: result['message'], isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        flexibleSpace: Container(
          decoration: AppTheme.headerDecoration,
        ),
        title: Text(
          _isEditMode ? 'Edit Student' : 'Add New Student',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              children: [
                _buildStep(0, 'Personal Details', _buildPersonalStep()),
                _buildStep(1, 'Academic Details', _buildAcademicStep()),
                _buildStep(2, 'Fee Details', _buildFeeStep()),
                _buildStep(3, 'Parent Details', _buildParentStep()),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: AppTheme.primaryBlue,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          bool isActive = index <= _currentStep;
          return Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isActive ? AppTheme.primaryBlue : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (index < 3)
                Container(
                  width: 40,
                  height: 2,
                  color: index < _currentStep ? Colors.white : Colors.white24,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStep(int step, String title, Widget content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          content,
        ],
      ),
    );
  }

  Widget _buildSelectionField({
    required String label,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondary,
            ),
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.primaryBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value ?? 'Select $label',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: value != null ? FontWeight.bold : FontWeight.normal,
                      color: value != null 
                        ? (isDark ? Colors.white : AppTheme.textPrimary)
                        : (isDark ? Colors.white38 : Colors.grey),
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
        if (validator != null)
          FormField<String>(
            initialValue: value,
            validator: validator,
            builder: (state) {
              if (state.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: Text(
                    state.errorText!,
                    style: const TextStyle(color: AppTheme.errorRed, fontSize: 12),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
      ],
    );
  }

  void _showSelectionSheet({
    required String title,
    required List<String> options,
    required String? selectedValue,
    required Function(String) onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.backgroundDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: options.length,
                separatorBuilder: (context, index) => Divider(color: Colors.grey.withOpacity(0.1)),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = option == selectedValue;
                  return ListTile(
                    onTap: () {
                      onSelected(option);
                      Navigator.pop(context);
                    },
                    title: Text(
                      option,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppTheme.primaryBlue : (isDark ? Colors.white : Colors.black),
                      ),
                    ),
                    trailing: isSelected 
                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryBlue) 
                      : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDayPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: 350,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.backgroundDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                    const Text('Due Day of Month', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 45,
                  scrollController: FixedExtentScrollController(
                    initialItem: (int.tryParse(_dueDateController.text) ?? 1) - 1,
                  ),
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      _dueDateController.text = (index + 1).toString();
                    });
                  },
                  children: List<Widget>.generate(31, (int index) {
                    return Center(
                      child: Text(
                        (index + 1).toString(),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 20),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPersonalStep() {
    return Form(
      key: _step1Key,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(labelText: 'Full Name'),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _dobController,
            readOnly: true,
            onTap: () => _selectDate(context, _dobController),
            decoration: const InputDecoration(
              labelText: 'Date of Birth (Optional)',
              suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 24),
          _buildSelectionField(
            label: 'Gender',
            value: _selectedGender,
            icon: Icons.person_outline_rounded,
            onTap: () => _showSelectionSheet(
              title: 'Select Gender',
              options: ['Male', 'Female', 'Other'],
              selectedValue: _selectedGender,
              onSelected: (val) => setState(() => _selectedGender = val),
            ),
            validator: (value) => _selectedGender == null ? 'Please select gender' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicStep() {
    return Form(
      key: _step2Key,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          _buildSelectionField(
            label: 'Class',
            value: _selectedClass,
            icon: Icons.school_outlined,
            onTap: () => _showSelectionSheet(
              title: 'Select Class',
              options: ['Pre Primary', ...List.generate(12, (i) => 'Grade ${i + 1}')],
              selectedValue: _selectedClass,
              onSelected: (val) => setState(() => _selectedClass = val),
            ),
            validator: (value) => _selectedClass == null ? 'Please select class' : null,
          ),
          const SizedBox(height: 24),
          _buildSelectionField(
            label: 'Board',
            value: _selectedBoard,
            icon: Icons.assignment_outlined,
            onTap: () => _showSelectionSheet(
              title: 'Select Board',
              options: ['GSEB', 'CBSC', 'Gujarati Medium', 'Other'],
              selectedValue: _selectedBoard,
              onSelected: (val) => setState(() => _selectedBoard = val),
            ),
            validator: (value) => _selectedBoard == null ? 'Please select board' : null,
          ),
          const SizedBox(height: 24),
          _buildSelectionField(
            label: 'Batch Time',
            value: _selectedBatchTime,
            icon: Icons.access_time_rounded,
            onTap: () => _showSelectionSheet(
              title: 'Select Batch Time',
              options: ['Morning', 'Afternoon', 'Evening'],
              selectedValue: _selectedBatchTime,
              onSelected: (val) => setState(() => _selectedBatchTime = val),
            ),
            validator: (value) => _selectedBatchTime == null ? 'Please select batch' : null,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _schoolNameController,
            decoration: const InputDecoration(labelText: 'School Name (Optional)'),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _enrollmentController,
            readOnly: true,
            onTap: () => _selectDate(context, _enrollmentController),
            decoration: const InputDecoration(
              labelText: 'Enrollment Date',
              suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeStep() {
    return Form(
      key: _step3Key,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          TextFormField(
            controller: _feeAmountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
            decoration: const InputDecoration(labelText: 'Fee Amount', prefixText: '₹ '),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 24),
          _buildSelectionField(
            label: 'Due Day of Every Month',
            value: _dueDateController.text.isNotEmpty ? 'Day ${_dueDateController.text}' : null,
            icon: Icons.calendar_month_outlined,
            onTap: () => _showDayPicker(context),
            validator: (value) => _dueDateController.text.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 24),
          _buildSelectionField(
            label: 'Bill Cycle',
            value: _selectedBillCycle,
            icon: Icons.repeat_rounded,
            onTap: () => _showSelectionSheet(
              title: 'Select Bill Cycle',
              options: ['Monthly', 'Quarterly', 'Half-Yearly', 'Yearly'],
              selectedValue: _selectedBillCycle,
              onSelected: (val) => setState(() => _selectedBillCycle = val),
            ),
            validator: (value) => _selectedBillCycle == null ? 'Please select bill cycle' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildParentStep() {
    return Form(
      key: _step4Key,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          TextFormField(
            controller: _parentNameController,
            decoration: const InputDecoration(labelText: 'Parent/Guardian Name'),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _mobileNumberController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            decoration: const InputDecoration(labelText: 'Mobile Number'),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (value.length != 10) return 'Enter 10-digit number';
              return null;
            },
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _addressController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Address (Optional)'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _backStep,
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_currentStep < 3 ? 'Next' : (_isEditMode ? 'Update Student' : 'Register Student')),
            ),
          ),
        ],
      ),
    );
  }
}
