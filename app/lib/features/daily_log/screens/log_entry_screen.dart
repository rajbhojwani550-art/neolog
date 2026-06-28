import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/utils/ga_calculator.dart';
import '../../babies/providers/babies_provider.dart';
import '../providers/daily_log_provider.dart';

class LogEntryScreen extends ConsumerStatefulWidget {
  final String babyId;
  final String? logId;

  const LogEntryScreen({super.key, required this.babyId, this.logId});

  @override
  ConsumerState<LogEntryScreen> createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends ConsumerState<LogEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  DateTime _logDate = DateTime.now();

  // Vitals
  final _hrController = TextEditingController();
  final _rrController = TextEditingController();
  final _tempController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _bpSysController = TextEditingController();
  final _bpDiaController = TextEditingController();
  final _weightController = TextEditingController();
  final _hcController = TextEditingController();
  final _lengthController = TextEditingController();

  // Respiratory
  String _respiratorySupport = 'room air';
  final _fio2Controller = TextEditingController();
  final _peepController = TextEditingController();
  final _pipController = TextEditingController();
  final _rateController = TextEditingController();
  final _tvController = TextEditingController();
  final _cpapController = TextEditingController();

  // Feeds
  String _feedType = 'NPO';
  final _feedVolController = TextEditingController();
  final _feedCalController = TextEditingController();
  final _totalFluidController = TextEditingController();
  final _ivfRateController = TextEditingController();
  final _ivfTypeController = TextEditingController();
  bool _tpn = false;

  // Exam
  final _generalExamController = TextEditingController();
  final _cnsExamController = TextEditingController();
  final _cvExamController = TextEditingController();
  final _respExamController = TextEditingController();
  final _abdExamController = TextEditingController();
  final _skinExamController = TextEditingController();
  final _eyesExamController = TextEditingController();

  // Assessment
  final _planController = TextEditingController();
  final _notesController = TextEditingController();
  final _doctorController = TextEditingController();
  final _problemController = TextEditingController();
  List<String> _activeProblems = [];

  final _respiratorySupportOptions = [
    'room air',
    'low-flow O2',
    'high-flow',
    'CPAP',
    'BiPAP',
    'intubated-ventilator',
  ];

  final _feedTypeOptions = [
    'NPO',
    'orogastric',
    'nasogastric',
    'oral',
    'mixed',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.logId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingLog());
    }
  }

  void _loadExistingLog() {
    final log = ref.read(dailyLogProvider(widget.babyId).notifier).getLog(widget.logId!);
    if (log == null) return;

    setState(() {
      _logDate = log.logDate;
      _hrController.text = log.heartRate?.toString() ?? '';
      _rrController.text = log.respiratoryRate?.toString() ?? '';
      _tempController.text = log.temperature?.toString() ?? '';
      _spo2Controller.text = log.spo2?.toString() ?? '';
      _bpSysController.text = log.bloodPressureSystolic?.toString() ?? '';
      _bpDiaController.text = log.bloodPressureDiastolic?.toString() ?? '';
      _weightController.text = log.weight?.toString() ?? '';
      _hcController.text = log.headCircumference?.toString() ?? '';
      _lengthController.text = log.length?.toString() ?? '';
      _respiratorySupport = log.respiratorySupport;
      _fio2Controller.text = log.fio2Percent?.toString() ?? '';
      _peepController.text = log.peep?.toString() ?? '';
      _pipController.text = log.pip?.toString() ?? '';
      _rateController.text = log.rate?.toString() ?? '';
      _tvController.text = log.tidalVolume?.toString() ?? '';
      _cpapController.text = log.cpapPressure?.toString() ?? '';
      _feedType = log.feedType;
      _feedVolController.text = log.feedVolumeMlPerKg?.toString() ?? '';
      _feedCalController.text = log.feedCaloriesDensity?.toString() ?? '';
      _totalFluidController.text = log.totalFluidMlPerKg?.toString() ?? '';
      _ivfRateController.text = log.ivfRate?.toString() ?? '';
      _ivfTypeController.text = log.ivfType ?? '';
      _tpn = log.tpn;
      _generalExamController.text = log.generalExam ?? '';
      _cnsExamController.text = log.cnsExam ?? '';
      _cvExamController.text = log.cvExam ?? '';
      _respExamController.text = log.respiratoryExam ?? '';
      _abdExamController.text = log.abdomenExam ?? '';
      _skinExamController.text = log.skinExam ?? '';
      _eyesExamController.text = log.eyesExam ?? '';
      _planController.text = log.plan ?? '';
      _notesController.text = log.notes ?? '';
      _doctorController.text = log.attendingDoctor ?? '';
      _activeProblems = List.from(log.activeProblemsList);
    });
  }

  @override
  void dispose() {
    for (final c in [
      _hrController, _rrController, _tempController, _spo2Controller,
      _bpSysController, _bpDiaController, _weightController, _hcController,
      _lengthController, _fio2Controller, _peepController, _pipController,
      _rateController, _tvController, _cpapController, _feedVolController,
      _feedCalController, _totalFluidController, _ivfRateController,
      _ivfTypeController, _generalExamController, _cnsExamController,
      _cvExamController, _respExamController, _abdExamController,
      _skinExamController, _eyesExamController, _planController,
      _notesController, _doctorController, _problemController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveLog() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final baby = ref.read(babyProvider(widget.babyId));
    if (baby == null) return;

    final dol = GACalculator.dayOfLife(baby.dateOfBirth, _logDate);
    final cga = GACalculator.computeCGA(
        baby.dateOfBirth, baby.gaWeeks, baby.gaDays, _logDate);

    final logData = {
      'logDate': _logDate.toIso8601String(),
      'dayOfLife': dol,
      'correctedGA': cga,
      'heartRate': _intOrNull(_hrController.text),
      'respiratoryRate': _intOrNull(_rrController.text),
      'temperature': _doubleOrNull(_tempController.text),
      'spo2': _intOrNull(_spo2Controller.text),
      'bloodPressureSystolic': _intOrNull(_bpSysController.text),
      'bloodPressureDiastolic': _intOrNull(_bpDiaController.text),
      'weight': _doubleOrNull(_weightController.text),
      'headCircumference': _doubleOrNull(_hcController.text),
      'length': _doubleOrNull(_lengthController.text),
      'respiratorySupport': _respiratorySupport,
      'fio2Percent': _intOrNull(_fio2Controller.text),
      'peep': _intOrNull(_peepController.text),
      'pip': _intOrNull(_pipController.text),
      'rate': _intOrNull(_rateController.text),
      'tidalVolume': _doubleOrNull(_tvController.text),
      'cpapPressure': _intOrNull(_cpapController.text),
      'feedType': _feedType,
      'feedVolumeMlPerKg': _doubleOrNull(_feedVolController.text),
      'feedCaloriesDensity': _doubleOrNull(_feedCalController.text),
      'totalFluidMlPerKg': _doubleOrNull(_totalFluidController.text),
      'ivfRate': _doubleOrNull(_ivfRateController.text),
      'ivfType': _ivfTypeController.text.isEmpty ? null : _ivfTypeController.text,
      'tpn': _tpn,
      'generalExam': _nullIfEmpty(_generalExamController.text),
      'cnsExam': _nullIfEmpty(_cnsExamController.text),
      'cvExam': _nullIfEmpty(_cvExamController.text),
      'respiratoryExam': _nullIfEmpty(_respExamController.text),
      'abdomenExam': _nullIfEmpty(_abdExamController.text),
      'skinExam': _nullIfEmpty(_skinExamController.text),
      'eyesExam': _nullIfEmpty(_eyesExamController.text),
      'activeProblemsList': _activeProblems,
      'plan': _nullIfEmpty(_planController.text),
      'attendingDoctor': _nullIfEmpty(_doctorController.text),
      'notes': _nullIfEmpty(_notesController.text),
    };

    try {
      final notifier = ref.read(dailyLogProvider(widget.babyId).notifier);
      if (widget.logId != null) {
        await notifier.updateLog(widget.logId!, logData);
      } else {
        await notifier.addLog(logData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log saved'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.alert),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int? _intOrNull(String v) => v.isEmpty ? null : int.tryParse(v);
  double? _doubleOrNull(String v) => v.isEmpty ? null : double.tryParse(v);
  String? _nullIfEmpty(String v) => v.trim().isEmpty ? null : v.trim();

  @override
  Widget build(BuildContext context) {
    final baby = ref.watch(babyProvider(widget.babyId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.logId != null ? 'Edit Log' : 'New Daily Log'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveLog,
            child: const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              // Date header
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.primary.withOpacity(0.05),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _logDate,
                            firstDate: baby?.dateOfBirth ?? DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => _logDate = picked);
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              '${_logDate.day}/${_logDate.month}/${_logDate.year}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (baby != null) ...[
                      Text(
                        'DOL ${GACalculator.dayOfLife(baby.dateOfBirth, _logDate)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'CGA ${GACalculator.computeCGA(baby.dateOfBirth, baby.gaWeeks, baby.gaDays, _logDate)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.secondary),
                      ),
                    ],
                  ],
                ),
              ),

              // VITALS
              const SectionHeader(title: 'Vitals', icon: Icons.monitor_heart),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(child: _NumberField(_hrController, 'HR (bpm)')),
                      const SizedBox(width: 12),
                      Expanded(child: _NumberField(_rrController, 'RR (/min)')),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _DecimalField(_tempController, 'Temp (°C)')),
                      const SizedBox(width: 12),
                      Expanded(child: _NumberField(_spo2Controller, 'SpO2 (%)')),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _NumberField(_bpSysController, 'BP Sys')),
                      const SizedBox(width: 12),
                      Expanded(child: _NumberField(_bpDiaController, 'BP Dia')),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _DecimalField(_weightController, 'Weight (g)')),
                      const SizedBox(width: 12),
                      Expanded(child: _DecimalField(_hcController, 'HC (cm)')),
                      const SizedBox(width: 12),
                      Expanded(child: _DecimalField(_lengthController, 'Length (cm)')),
                    ]),
                  ],
                ),
              ),

              // RESPIRATORY
              const SectionHeader(title: 'Respiratory Support', icon: Icons.air),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _respiratorySupport,
                      decoration: const InputDecoration(labelText: 'Respiratory Support'),
                      items: _respiratorySupportOptions
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _respiratorySupport = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_respiratorySupport != 'room air') ...[
                      Row(children: [
                        Expanded(child: _NumberField(_fio2Controller, 'FiO2 (%)')),
                        const SizedBox(width: 12),
                        if (_respiratorySupport == 'CPAP' || _respiratorySupport == 'BiPAP')
                          Expanded(child: _NumberField(_cpapController, 'CPAP/PEEP'))
                        else if (_respiratorySupport == 'intubated-ventilator') ...[
                          Expanded(child: _NumberField(_peepController, 'PEEP')),
                        ],
                      ]),
                      if (_respiratorySupport == 'intubated-ventilator') ...[
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: _NumberField(_pipController, 'PIP')),
                          const SizedBox(width: 12),
                          Expanded(child: _NumberField(_rateController, 'Rate')),
                          const SizedBox(width: 12),
                          Expanded(child: _DecimalField(_tvController, 'TV (ml)')),
                        ]),
                      ],
                    ],
                  ],
                ),
              ),

              // FEEDS
              const SectionHeader(title: 'Feeds & Fluids', icon: Icons.local_dining),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _feedType,
                      decoration: const InputDecoration(labelText: 'Feed Type'),
                      items: _feedTypeOptions
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _feedType = v);
                      },
                    ),
                    if (_feedType != 'NPO') ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _DecimalField(_feedVolController, 'ml/kg/day')),
                        const SizedBox(width: 12),
                        Expanded(child: _DecimalField(_feedCalController, 'Cal density')),
                      ]),
                    ],
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _DecimalField(_totalFluidController, 'Total fluid (ml/kg)')),
                      const SizedBox(width: 12),
                      Expanded(child: _DecimalField(_ivfRateController, 'IVF rate (ml/hr)')),
                    ]),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ivfTypeController,
                      decoration: const InputDecoration(labelText: 'IVF Type', hintText: 'e.g. D10, N/2 saline'),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('TPN'),
                      value: _tpn,
                      onChanged: (v) => setState(() => _tpn = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),

              // SYSTEMIC EXAMINATION
              const SectionHeader(title: 'Systemic Examination', icon: Icons.medical_services),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _ExamField(_generalExamController, 'General', 'Activity, color, cry, edema'),
                    _ExamField(_cnsExamController, 'CNS', 'Tone, activity, fontanelle, pupils'),
                    _ExamField(_cvExamController, 'CVS', 'Heart sounds, murmur, perfusion, CRT'),
                    _ExamField(_respExamController, 'Respiratory', 'Air entry, retractions, grunt'),
                    _ExamField(_abdExamController, 'Abdomen', 'Soft/distended, bowel sounds'),
                    _ExamField(_skinExamController, 'Skin', 'Jaundice, rash, bruising'),
                    _ExamField(_eyesExamController, 'Eyes', 'Conjunctiva, red reflex'),
                  ],
                ),
              ),

              // ACTIVE PROBLEMS
              const SectionHeader(title: 'Active Problems', icon: Icons.warning_amber),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _problemController,
                            decoration: const InputDecoration(
                              labelText: 'Add problem',
                              hintText: 'e.g. RDS, Sepsis, NEC',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: AppColors.primary),
                          onPressed: () {
                            if (_problemController.text.trim().isNotEmpty) {
                              setState(() {
                                _activeProblems.add(_problemController.text.trim());
                                _problemController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _activeProblems.map((p) => Chip(
                        label: Text(p),
                        onDeleted: () {
                          setState(() => _activeProblems.remove(p));
                        },
                        deleteIconColor: AppColors.alert,
                      )).toList(),
                    ),
                  ],
                ),
              ),

              // PLAN
              const SectionHeader(title: 'Plan', icon: Icons.assignment),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _planController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Plan',
                        hintText: 'Management plan for today...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _doctorController,
                      decoration: const InputDecoration(labelText: 'Attending Doctor'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveLog,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: Text(widget.logId != null ? 'Update Log' : 'Save Log'),
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const _NumberField(this.controller, this.label);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }
}

class _DecimalField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const _DecimalField(this.controller, this.label);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }
}

class _ExamField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  const _ExamField(this.controller, this.label, this.hint);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: 2,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          alignLabelWithHint: true,
        ),
      ),
    );
  }
}
