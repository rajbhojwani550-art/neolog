import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/section_header.dart';
import '../providers/babies_provider.dart';

class AddBabyScreen extends ConsumerStatefulWidget {
  const AddBabyScreen({super.key});

  @override
  ConsumerState<AddBabyScreen> createState() => _AddBabyScreenState();
}

class _AddBabyScreenState extends ConsumerState<AddBabyScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _mrnController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthWeightController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _motherAgeController = TextEditingController();
  final _apgar1Controller = TextEditingController();
  final _apgar5Controller = TextEditingController();
  final _admissionReasonController = TextEditingController();
  final _antenatalHistoryController = TextEditingController();

  DateTime _dateOfBirth = DateTime.now();
  DateTime _admissionDate = DateTime.now();
  int _gaWeeks = 28;
  int _gaDays = 0;
  String _sex = 'male';
  String _modeOfDelivery = 'NVD';
  String _antenatalSteroids = 'none';

  @override
  void dispose() {
    _mrnController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthWeightController.dispose();
    _motherNameController.dispose();
    _fatherNameController.dispose();
    _motherAgeController.dispose();
    _apgar1Controller.dispose();
    _apgar5Controller.dispose();
    _admissionReasonController.dispose();
    _antenatalHistoryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isBirth) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isBirth ? _dateOfBirth : _admissionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isBirth) {
          _dateOfBirth = picked;
        } else {
          _admissionDate = picked;
        }
      });
    }
  }

  Future<void> _saveBaby() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final baby = await ref.read(babiesProvider.notifier).addBaby(
            mrn: _mrnController.text.trim(),
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            dateOfBirth: _dateOfBirth,
            gaWeeks: _gaWeeks,
            gaDays: _gaDays,
            birthWeightGrams: int.parse(_birthWeightController.text),
            sex: _sex,
            motherName: _motherNameController.text.trim(),
            fatherName: _fatherNameController.text.trim(),
            motherAge: _motherAgeController.text.isNotEmpty
                ? int.parse(_motherAgeController.text)
                : null,
            modeOfDelivery: _modeOfDelivery,
            apgarScore1min: _apgar1Controller.text.isNotEmpty
                ? int.parse(_apgar1Controller.text)
                : null,
            apgarScore5min: _apgar5Controller.text.isNotEmpty
                ? int.parse(_apgar5Controller.text)
                : null,
            admissionDate: _admissionDate,
            admissionReason: _admissionReasonController.text.trim(),
            antenatalSteroids: _antenatalSteroids,
            antenatalHistory: _antenatalHistoryController.text.trim().isEmpty
                ? null
                : _antenatalHistoryController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Baby registered successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/baby/${baby.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.alert,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register New Baby'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Saving...',
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              const SectionHeader(title: 'Baby Information', icon: Icons.child_care),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _mrnController,
                      decoration: const InputDecoration(labelText: 'MRN / Hospital Number *'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(labelText: 'First Name *'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(labelText: 'Last Name *'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, true),
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Date of Birth *'),
                              child: Text(
                                '${_dateOfBirth.day}/${_dateOfBirth.month}/${_dateOfBirth.year}',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _sex,
                            decoration: const InputDecoration(labelText: 'Sex *'),
                            items: const [
                              DropdownMenuItem(value: 'male', child: Text('Male')),
                              DropdownMenuItem(value: 'female', child: Text('Female')),
                              DropdownMenuItem(value: 'ambiguous', child: Text('Ambiguous')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _sex = v);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SectionHeader(title: 'Birth Details', icon: Icons.cake),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _gaWeeks,
                            decoration: const InputDecoration(labelText: 'GA Weeks *'),
                            items: List.generate(19, (i) => i + 22)
                                .map((w) => DropdownMenuItem(
                                    value: w, child: Text('$w weeks')))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _gaWeeks = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _gaDays,
                            decoration: const InputDecoration(labelText: 'GA Days'),
                            items: List.generate(7, (i) => i)
                                .map((d) => DropdownMenuItem(
                                    value: d, child: Text('$d days')))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _gaDays = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _birthWeightController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Birth Weight (grams) *',
                        suffixText: 'g',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final w = int.tryParse(v);
                        if (w == null || w < 200 || w > 6000) {
                          return 'Enter a valid weight (200-6000g)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _modeOfDelivery,
                            decoration: const InputDecoration(labelText: 'Mode of Delivery *'),
                            items: const [
                              DropdownMenuItem(value: 'NVD', child: Text('NVD')),
                              DropdownMenuItem(value: 'LSCS', child: Text('LSCS')),
                              DropdownMenuItem(value: 'instrumental', child: Text('Instrumental')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _modeOfDelivery = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _apgar1Controller,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(labelText: 'APGAR 1 min'),
                            validator: (v) {
                              if (v != null && v.isNotEmpty) {
                                final s = int.tryParse(v);
                                if (s == null || s < 0 || s > 10) return '0-10';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _apgar5Controller,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(labelText: 'APGAR 5 min'),
                            validator: (v) {
                              if (v != null && v.isNotEmpty) {
                                final s = int.tryParse(v);
                                if (s == null || s < 0 || s > 10) return '0-10';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SectionHeader(title: 'Parent Information', icon: Icons.people),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _motherNameController,
                      decoration: const InputDecoration(labelText: 'Mother\'s Name *'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _fatherNameController,
                            decoration: const InputDecoration(labelText: 'Father\'s Name *'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            controller: _motherAgeController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(labelText: 'Mother Age'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SectionHeader(title: 'Admission', icon: Icons.local_hospital),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Admission Date *'),
                        child: Text(
                          '${_admissionDate.day}/${_admissionDate.month}/${_admissionDate.year}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _admissionReasonController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Admission Reason *',
                        hintText: 'e.g. Prematurity, RDS, Birth asphyxia',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _antenatalSteroids,
                      decoration: const InputDecoration(labelText: 'Antenatal Steroids'),
                      items: const [
                        DropdownMenuItem(value: 'none', child: Text('None')),
                        DropdownMenuItem(value: 'partial', child: Text('Partial')),
                        DropdownMenuItem(value: 'complete', child: Text('Complete')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _antenatalSteroids = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _antenatalHistoryController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Antenatal History',
                        hintText: 'GDM, PIH, PROM, etc.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveBaby,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Register Baby'),
          ),
        ),
      ),
    );
  }
}
