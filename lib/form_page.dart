import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _genderOptions = ['Male', 'Female', 'Other'];
const _civilStatusOptions = ['Single', 'Married', 'Widowed', 'Separated'];
const _languageSuggestions = [
  'English',
  'Filipino',
  'Cebuano',
  'Ilocano',
  'Hiligaynon',
  'Kapampangan',
];
const _skillSuggestions = [
  'Driving',
  'Typing',
  'Welding',
  'Computer Literate',
  'Plumbing',
  'Electrical Wiring',
  'Carpentry',
  'Cooking',
];

String _formatDate(DateTime? date) =>
    date == null ? '' : DateFormat.yMMMMd().format(date);

int _ageFrom(DateTime birthDate, DateTime today) {
  int age = today.year - birthDate.year;
  if (today.month < birthDate.month ||
      (today.month == birthDate.month && today.day < birthDate.day)) {
    age--;
  }
  return age < 0 ? 0 : age;
}

class ChildEntry {
  final nameController = TextEditingController();
  DateTime? birthday;

  void dispose() => nameController.dispose();
}

class TrainingEntry {
  final titleController = TextEditingController();
  final institutionController = TextEditingController();
  final yearController = TextEditingController();

  void dispose() {
    titleController.dispose();
    institutionController.dispose();
    yearController.dispose();
  }
}

class JobEntry {
  final companyController = TextEditingController();
  final positionController = TextEditingController();
  final addressController = TextEditingController();
  DateTime? from;
  DateTime? to;
  bool present = false;

  void dispose() {
    companyController.dispose();
    positionController.dispose();
    addressController.dispose();
  }
}

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<TextEditingController> _controllers = [];

  late final TextEditingController nameController = _newController();
  late final TextEditingController placeOfBirthController = _newController();
  late final TextEditingController ageController = _newController();
  late final TextEditingController nationalityController = _newController();
  late final TextEditingController religionController = _newController();
  late final TextEditingController positionDesiredController =
      _newController();
  late final TextEditingController presentAddressController = _newController();
  late final TextEditingController permanentAddressController =
      _newController();
  late final TextEditingController heightController = _newController();
  late final TextEditingController weightController = _newController();

  late final TextEditingController fatherNameController = _newController();
  late final TextEditingController fatherOccupationController =
      _newController();
  late final TextEditingController motherNameController = _newController();
  late final TextEditingController motherOccupationController =
      _newController();
  late final TextEditingController spouseNameController = _newController();
  late final TextEditingController spouseOccupationController =
      _newController();
  late final TextEditingController emergencyNameController = _newController();
  late final TextEditingController emergencyAddressController =
      _newController();
  late final TextEditingController emergencyContactController =
      _newController();

  late final TextEditingController elementarySchoolController =
      _newController();
  late final TextEditingController elementaryAddressController =
      _newController();
  late final TextEditingController elementaryYearController = _newController();
  late final TextEditingController highSchoolController = _newController();
  late final TextEditingController highSchoolAddressController =
      _newController();
  late final TextEditingController highSchoolYearController = _newController();
  late final TextEditingController collegeSchoolController = _newController();
  late final TextEditingController collegeAddressController = _newController();
  late final TextEditingController collegeCourseController = _newController();
  late final TextEditingController collegeYearController = _newController();

  String? gender;
  String? civilStatus;
  DateTime? dateOfBirth;

  final List<String> languages = [];
  final List<String> skills = [];
  final List<ChildEntry> children = [];
  final List<TrainingEntry> trainings = [];
  final List<JobEntry> jobs = [JobEntry(), JobEntry()];

  bool _isSaving = false;

  TextEditingController _newController() {
    final controller = TextEditingController();
    _controllers.add(controller);
    return controller;
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final child in children) {
      child.dispose();
    }
    for (final training in trainings) {
      training.dispose();
    }
    for (final job in jobs) {
      job.dispose();
    }
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onBirthDateChanged(DateTime? value) {
    setState(() {
      dateOfBirth = value;
      ageController.text =
          value == null ? '' : _ageFrom(value, DateTime.now()).toString();
    });
  }

  void _addChild() => setState(() => children.add(ChildEntry()));

  void _removeChild(int index) {
    final removed = children.removeAt(index);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void _addTraining() => setState(() => trainings.add(TrainingEntry()));

  void _removeTraining(int index) {
    final removed = trainings.removeAt(index);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void _clearForm() {
    setState(() {
      for (final controller in _controllers) {
        controller.clear();
      }
      gender = null;
      civilStatus = null;
      dateOfBirth = null;
      languages.clear();
      skills.clear();

      final removedChildren = List<ChildEntry>.from(children);
      children.clear();
      final removedTrainings = List<TrainingEntry>.from(trainings);
      trainings.clear();

      for (final job in jobs) {
        job.companyController.clear();
        job.positionController.clear();
        job.addressController.clear();
        job.from = null;
        job.to = null;
        job.present = false;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final child in removedChildren) {
          child.dispose();
        }
        for (final training in removedTrainings) {
          training.dispose();
        }
      });
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showSnack('Please fill in all required fields');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _firestore.collection('biodata').add({
        'personalDetails': {
          'fullName': nameController.text.trim(),
          'gender': gender,
          'civilStatus': civilStatus,
          'dateOfBirth':
              dateOfBirth == null ? null : Timestamp.fromDate(dateOfBirth!),
          'age': ageController.text.trim(),
          'placeOfBirth': placeOfBirthController.text.trim(),
          'nationality': nationalityController.text.trim(),
          'religion': religionController.text.trim(),
          'positionDesired': positionDesiredController.text.trim(),
          'presentAddress': presentAddressController.text.trim(),
          'permanentAddress': permanentAddressController.text.trim(),
          'height': heightController.text.trim(),
          'weight': weightController.text.trim(),
          'languages': List<String>.from(languages),
        },
        'familyBackground': {
          'fatherName': fatherNameController.text.trim(),
          'fatherOccupation': fatherOccupationController.text.trim(),
          'motherName': motherNameController.text.trim(),
          'motherOccupation': motherOccupationController.text.trim(),
          'spouseName': spouseNameController.text.trim(),
          'spouseOccupation': spouseOccupationController.text.trim(),
          'children': [
            for (final child in children)
              if (child.nameController.text.trim().isNotEmpty ||
                  child.birthday != null)
                {
                  'name': child.nameController.text.trim(),
                  'birthday': child.birthday == null
                      ? null
                      : Timestamp.fromDate(child.birthday!),
                },
          ],
          'personToNotify': {
            'name': emergencyNameController.text.trim(),
            'address': emergencyAddressController.text.trim(),
            'contactNumber': emergencyContactController.text.trim(),
          },
        },
        'education': {
          'elementary': {
            'school': elementarySchoolController.text.trim(),
            'address': elementaryAddressController.text.trim(),
            'yearGraduated': elementaryYearController.text.trim(),
          },
          'highSchool': {
            'school': highSchoolController.text.trim(),
            'address': highSchoolAddressController.text.trim(),
            'yearGraduated': highSchoolYearController.text.trim(),
          },
          'college': {
            'school': collegeSchoolController.text.trim(),
            'address': collegeAddressController.text.trim(),
            'course': collegeCourseController.text.trim(),
            'yearGraduated': collegeYearController.text.trim(),
          },
          'trainings': [
            for (final training in trainings)
              if (training.titleController.text.trim().isNotEmpty ||
                  training.institutionController.text.trim().isNotEmpty)
                {
                  'title': training.titleController.text.trim(),
                  'institution': training.institutionController.text.trim(),
                  'year': training.yearController.text.trim(),
                },
          ],
        },
        'employment': [
          for (final job in jobs)
            if (job.companyController.text.trim().isNotEmpty ||
                job.positionController.text.trim().isNotEmpty)
              {
                'company': job.companyController.text.trim(),
                'position': job.positionController.text.trim(),
                'address': job.addressController.text.trim(),
                'from': job.from == null ? null : Timestamp.fromDate(job.from!),
                'to': job.to == null ? null : Timestamp.fromDate(job.to!),
                'present': job.present,
              },
        ],
        'specialSkills': List<String>.from(skills),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _showSnack('Biodata saved successfully');
      _clearForm();
    } catch (error) {
      if (!mounted) return;
      _showSnack('Failed to save: $error');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _twoCol(Widget left, Widget right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biodata Form'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPersonalSection(),
              const SizedBox(height: 16),
              _buildFamilySection(),
              const SizedBox(height: 16),
              _buildEducationSection(),
              const SizedBox(height: 16),
              _buildEmploymentSection(),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saving...' : 'Save Biodata'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalSection() {
    return SectionCard(
      title: 'Personal Details',
      children: [
        AppTextField(
          controller: nameController,
          label: 'Full Name',
          isRequired: true,
        ),
        _twoCol(
          AppDropdown(
            label: 'Gender',
            options: _genderOptions,
            value: gender,
            isRequired: true,
            onChanged: (value) => setState(() => gender = value),
          ),
          AppDropdown(
            label: 'Civil Status',
            options: _civilStatusOptions,
            value: civilStatus,
            isRequired: true,
            onChanged: (value) => setState(() => civilStatus = value),
          ),
        ),
        _twoCol(
          DatePickerField(
            label: 'Date of Birth',
            value: dateOfBirth,
            lastDate: DateTime.now(),
            onChanged: _onBirthDateChanged,
          ),
          AppTextField(
            controller: ageController,
            label: 'Age',
            hint: 'Computed from date of birth',
            readOnly: true,
          ),
        ),
        AppTextField(
          controller: placeOfBirthController,
          label: 'Place of Birth',
        ),
        _twoCol(
          AppTextField(
            controller: nationalityController,
            label: 'Nationality',
            hint: 'e.g. Filipino',
          ),
          AppTextField(
            controller: religionController,
            label: 'Religion',
          ),
        ),
        AppTextField(
          controller: positionDesiredController,
          label: 'Position Desired',
          hint: 'e.g. Sales Associate',
        ),
        AppTextField(
          controller: presentAddressController,
          label: 'Present Address',
          maxLines: 2,
        ),
        AppTextField(
          controller: permanentAddressController,
          label: 'Permanent / Provincial Address',
          maxLines: 2,
        ),
        _twoCol(
          AppTextField(
            controller: heightController,
            label: 'Height',
            hint: 'e.g. 170 cm',
            keyboardType: TextInputType.text,
          ),
          AppTextField(
            controller: weightController,
            label: 'Weight',
            hint: 'e.g. 65 kg',
            keyboardType: TextInputType.text,
          ),
        ),
        ChipInput(
          label: 'Languages',
          hint: 'Type a language and press add',
          items: languages,
          suggestions: _languageSuggestions,
        ),
      ],
    );
  }

  Widget _buildFamilySection() {
    return SectionCard(
      title: 'Family Background',
      children: [
        _twoCol(
          AppTextField(
            controller: fatherNameController,
            label: "Father's Name",
          ),
          AppTextField(
            controller: fatherOccupationController,
            label: "Father's Occupation",
          ),
        ),
        _twoCol(
          AppTextField(
            controller: motherNameController,
            label: "Mother's Name",
          ),
          AppTextField(
            controller: motherOccupationController,
            label: "Mother's Occupation",
          ),
        ),
        if (civilStatus == 'Married')
          _twoCol(
            AppTextField(
              controller: spouseNameController,
              label: "Spouse's Name",
            ),
            AppTextField(
              controller: spouseOccupationController,
              label: "Spouse's Occupation",
            ),
          ),
        const SubHeader(title: "Children's Names & Birthdays"),
        for (int i = 0; i < children.length; i++)
          _childRow(children[i], i),
        if (children.isEmpty)
          const Text(
            'No children added.',
            style: TextStyle(color: Colors.grey),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _addChild,
            icon: const Icon(Icons.add),
            label: const Text('Add child'),
          ),
        ),
        const SubHeader(title: 'Person to Notify in Case of Emergency'),
        AppTextField(
          controller: emergencyNameController,
          label: 'Name',
          isRequired: true,
        ),
        AppTextField(
          controller: emergencyAddressController,
          label: 'Address',
          maxLines: 2,
        ),
        AppTextField(
          controller: emergencyContactController,
          label: 'Contact Number',
          isRequired: true,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _childRow(ChildEntry child, int index) {
    return Container(
      key: ObjectKey(child),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: child.nameController,
                  label: 'Child ${index + 1} Name',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Remove child',
                onPressed: () => _removeChild(index),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DatePickerField(
            label: 'Birthday',
            value: child.birthday,
            lastDate: DateTime.now(),
            onChanged: (value) => setState(() => child.birthday = value),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationSection() {
    return SectionCard(
      title: 'Educational Attainment',
      children: [
        const SubHeader(title: 'Elementary / Primary School'),
        AppTextField(
          controller: elementarySchoolController,
          label: 'School Name',
        ),
        _twoCol(
          AppTextField(
            controller: elementaryAddressController,
            label: 'Address',
          ),
          AppTextField(
            controller: elementaryYearController,
            label: 'Year Graduated',
            hint: 'e.g. 2010',
            keyboardType: TextInputType.number,
          ),
        ),
        const SubHeader(title: 'High School / Secondary Education'),
        AppTextField(
          controller: highSchoolController,
          label: 'School Name',
        ),
        _twoCol(
          AppTextField(
            controller: highSchoolAddressController,
            label: 'Address',
          ),
          AppTextField(
            controller: highSchoolYearController,
            label: 'Year Graduated',
            hint: 'e.g. 2014',
            keyboardType: TextInputType.number,
          ),
        ),
        const SubHeader(title: 'College / Tertiary Education / Vocational Courses'),
        AppTextField(
          controller: collegeSchoolController,
          label: 'School Name',
        ),
        _twoCol(
          AppTextField(
            controller: collegeAddressController,
            label: 'Address',
          ),
          AppTextField(
            controller: collegeCourseController,
            label: 'Course / Program',
            hint: 'e.g. BS Information Technology',
          ),
        ),
        AppTextField(
          controller: collegeYearController,
          label: 'Year Graduated',
          hint: 'e.g. 2018',
          keyboardType: TextInputType.number,
        ),
        const SubHeader(title: 'Trainings and Certificates'),
        for (int i = 0; i < trainings.length; i++)
          _trainingRow(trainings[i], i),
        if (trainings.isEmpty)
          const Text(
            'No trainings added.',
            style: TextStyle(color: Colors.grey),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _addTraining,
            icon: const Icon(Icons.add),
            label: const Text('Add training'),
          ),
        ),
      ],
    );
  }

  Widget _trainingRow(TrainingEntry training, int index) {
    return Container(
      key: ObjectKey(training),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: training.titleController,
                  label: 'Training / Certificate ${index + 1}',
                  hint: 'e.g. NCII Welding',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Remove training',
                onPressed: () => _removeTraining(index),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: training.institutionController,
            label: 'Institution / Provider',
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: training.yearController,
            label: 'Year',
            hint: 'e.g. 2023',
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildEmploymentSection() {
    return SectionCard(
      title: 'Employment Record',
      children: [
        for (int i = 0; i < jobs.length; i++) ...[
          SubHeader(title: 'Previous Job ${i + 1}'),
          _jobFields(jobs[i]),
        ],
        const SubHeader(title: 'Special Skills'),
        ChipInput(
          label: 'Skills',
          hint: 'Type a skill and press add',
          items: skills,
          suggestions: _skillSuggestions,
        ),
      ],
    );
  }

  Widget _jobFields(JobEntry job) {
    return Container(
      key: ObjectKey(job),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _twoCol(
            AppTextField(
              controller: job.companyController,
              label: 'Company / Employer',
            ),
            AppTextField(
              controller: job.positionController,
              label: 'Position',
            ),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: job.addressController,
            label: 'Address',
          ),
          const SizedBox(height: 12),
          _twoCol(
            DatePickerField(
              label: 'From',
              value: job.from,
              onChanged: (value) => setState(() => job.from = value),
            ),
            DatePickerField(
              label: 'To',
              value: job.to,
              enabled: !job.present,
              onChanged: (value) => setState(() => job.to = value),
            ),
          ),
          CheckboxListTile(
            value: job.present,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Currently working here'),
            onChanged: (value) => setState(() {
              job.present = value ?? false;
              if (job.present) {
                job.to = null;
              }
            }),
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class SubHeader extends StatelessWidget {
  const SubHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.isRequired = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool isRequired;
  final bool readOnly;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        suffixText: isRequired ? '*' : null,
      ),
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return '$label is required';
        }
        return null;
      },
    );
  }
}

class AppDropdown extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.onChanged,
    this.value,
    this.isRequired = false,
  });

  final String label;
  final List<String> options;
  final String? value;
  final bool isRequired;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: options.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixText: isRequired ? '*' : null,
      ),
      items: [
        for (final option in options)
          DropdownMenuItem<String>(value: option, child: Text(option)),
      ],
      onChanged: onChanged,
      validator: (current) {
        if (isRequired && current == null) {
          return '$label is required';
        }
        return null;
      },
    );
  }
}

class DatePickerField extends StatefulWidget {
  const DatePickerField({
    super.key,
    required this.label,
    required this.onChanged,
    this.value,
    this.firstDate,
    this.lastDate,
    this.isRequired = false,
    this.enabled = true,
  });

  final String label;
  final DateTime? value;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool isRequired;
  final bool enabled;
  final ValueChanged<DateTime?> onChanged;

  @override
  State<DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatDate(widget.value));
  }

  @override
  void didUpdateWidget(covariant DatePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = _formatDate(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openPicker() async {
    if (!widget.enabled) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.value ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime(1900),
      lastDate: widget.lastDate ?? DateTime.now(),
    );
    if (picked != null) {
      widget.onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      enabled: widget.enabled,
      onTap: _openPicker,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today, size: 18),
        suffixText: widget.isRequired ? '*' : null,
      ),
      validator: (value) {
        if (widget.isRequired && widget.value == null) {
          return '${widget.label} is required';
        }
        return null;
      },
    );
  }
}

class ChipInput extends StatefulWidget {
  const ChipInput({
    super.key,
    required this.label,
    required this.items,
    this.suggestions = const [],
    this.hint,
  });

  final String label;
  final List<String> items;
  final List<String> suggestions;
  final String? hint;

  @override
  State<ChipInput> createState() => _ChipInputState();
}

class _ChipInputState extends State<ChipInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final value = raw.trim();
    if (value.isEmpty ||
        widget.items.any((item) => item.toLowerCase() == value.toLowerCase())) {
      return;
    }
    setState(() => widget.items.add(value));
    _controller.clear();
  }

  void _remove(String item) {
    setState(() => widget.items.remove(item));
  }

  @override
  Widget build(BuildContext context) {
    final remainingSuggestions = widget.suggestions
        .where((suggestion) => !widget.items.any(
            (item) => item.toLowerCase() == suggestion.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        if (widget.items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in widget.items)
                  Chip(
                    label: Text(item),
                    onDeleted: () => _remove(item),
                  ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: widget.hint ?? 'Type and press add',
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: _add,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle),
              tooltip: 'Add',
              onPressed: () => _add(_controller.text),
            ),
          ],
        ),
        if (remainingSuggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final suggestion in remainingSuggestions)
                ActionChip(
                  label: Text(suggestion),
                  onPressed: () => _add(suggestion),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
