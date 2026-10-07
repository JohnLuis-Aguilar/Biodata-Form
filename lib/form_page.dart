import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _genderOptions = ['Male', 'Female', 'Other'];
const _civilStatusOptions = ['Single', 'Married', 'Widowed', 'Separated'];

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
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
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

  final List<ChildEntry> children = [];
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

  void _clearForm() {
    setState(() {
      for (final controller in _controllers) {
        controller.clear();
      }
      gender = null;
      civilStatus = null;
      dateOfBirth = null;

      final removedChildren = List<ChildEntry>.from(children);
      children.clear();

      for (final job in jobs) {
        job.from = null;
        job.to = null;
        job.present = false;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final child in removedChildren) {
          child.dispose();
        }
      });
    });
  }

  Future<void> saveData() async {
    if (nameController.text.trim().isEmpty ||
        gender == null ||
        civilStatus == null ||
        emergencyNameController.text.trim().isEmpty ||
        emergencyContactController.text.trim().isEmpty) {
      _showSnack('Please fill in all required fields');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await firestore.collection('biodata').add({
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
        'notifyName': emergencyNameController.text.trim(),
        'notifyAddress': emergencyAddressController.text.trim(),
        'notifyContact': emergencyContactController.text.trim(),
        'elementarySchool': elementarySchoolController.text.trim(),
        'elementaryAddress': elementaryAddressController.text.trim(),
        'elementaryYear': elementaryYearController.text.trim(),
        'highSchool': highSchoolController.text.trim(),
        'highSchoolAddress': highSchoolAddressController.text.trim(),
        'highSchoolYear': highSchoolYearController.text.trim(),
        'collegeSchool': collegeSchoolController.text.trim(),
        'collegeAddress': collegeAddressController.text.trim(),
        'collegeCourse': collegeCourseController.text.trim(),
        'collegeYear': collegeYearController.text.trim(),
        'jobs': [
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
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _showSnack('Data saved successfully');
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

  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _field(Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biodata Form'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _title('Personal Details'),
            _field(AppTextField(
              controller: nameController,
              label: 'Full Name',
              icon: Icons.person,
            )),
            _field(AppDropdown(
              label: 'Gender',
              options: _genderOptions,
              value: gender,
              icon: Icons.wc,
              onChanged: (value) => setState(() => gender = value),
            )),
            _field(AppDropdown(
              label: 'Civil Status',
              options: _civilStatusOptions,
              value: civilStatus,
              icon: Icons.favorite_outline,
              onChanged: (value) => setState(() => civilStatus = value),
            )),
            _field(DatePickerField(
              label: 'Date of Birth',
              value: dateOfBirth,
              lastDate: DateTime.now(),
              icon: Icons.cake,
              onChanged: _onBirthDateChanged,
            )),
            _field(AppTextField(
              controller: ageController,
              label: 'Age',
              hint: 'Computed from date of birth',
              icon: Icons.calendar_month,
              readOnly: true,
            )),
            _field(AppTextField(
              controller: placeOfBirthController,
              label: 'Place of Birth',
              icon: Icons.location_on,
            )),
            _field(AppTextField(
              controller: nationalityController,
              label: 'Nationality',
              hint: 'e.g. Filipino',
              icon: Icons.flag,
            )),
            _field(AppTextField(
              controller: religionController,
              label: 'Religion',
              icon: Icons.church,
            )),
            _field(AppTextField(
              controller: positionDesiredController,
              label: 'Position Desired',
              hint: 'e.g. Sales Associate',
              icon: Icons.work,
            )),
            _field(AppTextField(
              controller: presentAddressController,
              label: 'Present Address',
              icon: Icons.home,
              maxLines: 2,
            )),
            _field(AppTextField(
              controller: permanentAddressController,
              label: 'Permanent / Provincial Address',
              icon: Icons.home,
              maxLines: 2,
            )),
            _field(AppTextField(
              controller: heightController,
              label: 'Height',
              hint: 'e.g. 170 cm',
              icon: Icons.height,
            )),
            _field(AppTextField(
              controller: weightController,
              label: 'Weight',
              hint: 'e.g. 65 kg',
              icon: Icons.monitor_weight,
            )),

            _title('Family Background'),
            _field(AppTextField(
              controller: fatherNameController,
              label: "Father's Name",
              icon: Icons.person,
            )),
            _field(AppTextField(
              controller: fatherOccupationController,
              label: "Father's Occupation",
              icon: Icons.work,
            )),
            _field(AppTextField(
              controller: motherNameController,
              label: "Mother's Name",
              icon: Icons.person,
            )),
            _field(AppTextField(
              controller: motherOccupationController,
              label: "Mother's Occupation",
              icon: Icons.work,
            )),
            if (civilStatus == 'Married') ...[
              _field(AppTextField(
                controller: spouseNameController,
                label: "Spouse's Name",
                icon: Icons.person,
              )),
              _field(AppTextField(
                controller: spouseOccupationController,
                label: "Spouse's Occupation",
                icon: Icons.work,
              )),
            ],
            _title("Children's Names & Birthdays"),
            for (int i = 0; i < children.length; i++) _childRow(children[i], i),
            if (children.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'No children added.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _addChild,
                icon: const Icon(Icons.add),
                label: const Text('Add child'),
              ),
            ),
            _title('Person to Notify in Case of Emergency'),
            _field(AppTextField(
              controller: emergencyNameController,
              label: 'Name',
              icon: Icons.person,
            )),
            _field(AppTextField(
              controller: emergencyAddressController,
              label: 'Address',
              icon: Icons.home,
              maxLines: 2,
            )),
            _field(AppTextField(
              controller: emergencyContactController,
              label: 'Contact Number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            )),

            _title('Educational Attainment'),
            _title('Elementary / Primary School'),
            _field(AppTextField(
              controller: elementarySchoolController,
              label: 'School Name',
              icon: Icons.school,
            )),
            _field(AppTextField(
              controller: elementaryAddressController,
              label: 'Address',
              icon: Icons.location_on,
            )),
            _field(AppTextField(
              controller: elementaryYearController,
              label: 'Year Graduated',
              hint: 'e.g. 2010',
              icon: Icons.calendar_month,
              keyboardType: TextInputType.number,
            )),
            _title('High School / Secondary Education'),
            _field(AppTextField(
              controller: highSchoolController,
              label: 'School Name',
              icon: Icons.school,
            )),
            _field(AppTextField(
              controller: highSchoolAddressController,
              label: 'Address',
              icon: Icons.location_on,
            )),
            _field(AppTextField(
              controller: highSchoolYearController,
              label: 'Year Graduated',
              hint: 'e.g. 2014',
              icon: Icons.calendar_month,
              keyboardType: TextInputType.number,
            )),
            _title('College / Tertiary Education / Vocational Courses'),
            _field(AppTextField(
              controller: collegeSchoolController,
              label: 'School Name',
              icon: Icons.school,
            )),
            _field(AppTextField(
              controller: collegeAddressController,
              label: 'Address',
              icon: Icons.location_on,
            )),
            _field(AppTextField(
              controller: collegeCourseController,
              label: 'Course / Program',
              hint: 'e.g. BS Information Technology',
              icon: Icons.menu_book,
            )),
            _field(AppTextField(
              controller: collegeYearController,
              label: 'Year Graduated',
              hint: 'e.g. 2018',
              icon: Icons.calendar_month,
              keyboardType: TextInputType.number,
            )),

            _title('Employment Record'),
            for (int i = 0; i < jobs.length; i++) ...[
              _title('Previous Job ${i + 1}'),
              _jobFields(jobs[i]),
            ],

            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isSaving ? null : saveData,
              child: Text(_isSaving ? 'Saving...' : 'Save to Firebase'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: child.nameController,
                  label: 'Child ${index + 1} Name',
                  icon: Icons.child_care,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Remove child',
                onPressed: () => _removeChild(index),
              ),
            ],
          ),
          DatePickerField(
            label: 'Birthday',
            value: child.birthday,
            lastDate: DateTime.now(),
            icon: Icons.cake,
            onChanged: (value) => setState(() => child.birthday = value),
          ),
        ],
      ),
    );
  }

  Widget _jobFields(JobEntry job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(AppTextField(
          controller: job.companyController,
          label: 'Company / Employer',
          icon: Icons.business,
        )),
        _field(AppTextField(
          controller: job.positionController,
          label: 'Position',
          icon: Icons.work,
        )),
        _field(AppTextField(
          controller: job.addressController,
          label: 'Address',
          icon: Icons.location_on,
        )),
        _field(DatePickerField(
          label: 'From',
          value: job.from,
          icon: Icons.calendar_month,
          onChanged: (value) => setState(() => job.from = value),
        )),
        _field(DatePickerField(
          label: 'To',
          value: job.to,
          icon: Icons.calendar_month,
          enabled: !job.present,
          onChanged: (value) => setState(() => job.to = value),
        )),
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
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.readOnly = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool readOnly;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        prefixIcon: icon == null ? null : Icon(icon),
      ),
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
    this.icon,
  });

  final String label;
  final List<String> options;
  final String? value;
  final IconData? icon;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: options.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: icon == null ? null : Icon(icon),
      ),
      items: [
        for (final option in options)
          DropdownMenuItem<String>(value: option, child: Text(option)),
      ],
      onChanged: onChanged,
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
    this.icon,
    this.enabled = true,
  });

  final String label;
  final DateTime? value;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final IconData? icon;
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
    return TextField(
      controller: _controller,
      readOnly: true,
      enabled: widget.enabled,
      onTap: _openPicker,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        prefixIcon: widget.icon == null ? null : Icon(widget.icon),
        suffixIcon: const Icon(Icons.calendar_today, size: 18),
      ),
    );
  }
}
