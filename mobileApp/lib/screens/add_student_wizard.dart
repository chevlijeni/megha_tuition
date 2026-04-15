import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';

class AddStudentWizard extends StatefulWidget {
  const AddStudentWizard({super.key});

  @override
  State<AddStudentWizard> createState() => _AddStudentWizardState();
}

class _AddStudentWizardState extends State<AddStudentWizard> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Form Keys
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();
  final _step4Key = GlobalKey<FormState>();

  // Data Controllers/Variables
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _enrollmentController = TextEditingController(
    text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
  );
  String? _selectedBoard;
  String? _selectedClass;
  String? _selectedBatchTime;
  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  
  // Generic validation helper
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

  void _showDayPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const Text('Select Due Day', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(
                    initialItem: (int.tryParse(_dueDateController.text) ?? 1) - 1,
                  ),
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      _dueDateController.text = (index + 1).toString();
                    });
                  },
                  children: List<Widget>.generate(31, (int index) {
                    return Center(child: Text((index + 1).toString()));
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
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
        _showSuccessDialog();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Student'),
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

  Widget _buildPersonalStep() {
    return Form(
      key: _step1Key,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: 'Full Name'),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dobController,
            readOnly: true,
            onTap: () => _selectDate(context, _dobController),
            decoration: const InputDecoration(
              labelText: 'Date of Birth (Optional)',
              suffixIcon: Icon(Icons.calendar_today, size: 18),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Gender'),
            items: ['Male', 'Female', 'Other'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (_) {},
            validator: (value) => value == null ? 'Please select gender' : null,
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
            DropdownButtonFormField<String>(
            value: _selectedClass,
            decoration: const InputDecoration(labelText: 'Class'),
            items: [
              'Pre Primary',
              ...List.generate(9, (i) => 'Grade ${i + 1}')
            ].map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (val) => setState(() => _selectedClass = val),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedBoard,
            decoration: const InputDecoration(labelText: 'Board'),
            items: ['GSEB', 'CBSC'].map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (val) => setState(() => _selectedBoard = val),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedBatchTime,
            decoration: const InputDecoration(labelText: 'Batch Time'),
            items: ['Morning', 'Afternoon', 'Evening'].map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (val) => setState(() => _selectedBatchTime = val),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _schoolNameController,
            decoration: const InputDecoration(labelText: 'School Name (Optional)'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _enrollmentController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Enrollment Date',
              suffixIcon: Icon(Icons.calendar_today, size: 18),
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
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(7),
            ],
            decoration: const InputDecoration(labelText: 'Fee Amount', prefixText: '₹ '),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dueDateController,
            readOnly: true,
            onTap: () => _showDayPicker(context),
            decoration: const InputDecoration(
              labelText: 'Due days of every month',
              suffixIcon: Icon(Icons.unfold_more, size: 18),
            ),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Bill Cycle'),
            items: ['Monthly', 'Quarterly', 'Yearly'].map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (_) {},
            validator: _requiredValidator,
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
            decoration: const InputDecoration(labelText: 'Parent/Guardian Name'),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 16),
          TextFormField(
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            decoration: const InputDecoration(labelText: 'Mobile Number'),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (value.length != 10) return 'Enter 10-digit number';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Address'),
            validator: _requiredValidator,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _backStep,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 50),
              ),
              child: Text(_currentStep < 3 ? 'Next' : 'Register Student'),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 24),
            const Text(
              'Success!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Student has been registered successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close wizard
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
