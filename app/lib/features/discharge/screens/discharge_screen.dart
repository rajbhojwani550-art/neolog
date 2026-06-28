import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/ga_calculator.dart';
import '../../../core/widgets/section_header.dart';
import '../../../services/local_storage.dart';
import '../../babies/providers/babies_provider.dart';
import '../services/discharge_pdf_service.dart';

class DischargeScreen extends ConsumerStatefulWidget {
  final String babyId;
  const DischargeScreen({super.key, required this.babyId});

  @override
  ConsumerState<DischargeScreen> createState() => _DischargeScreenState();
}

class _DischargeScreenState extends ConsumerState<DischargeScreen> {
  Map<String, dynamic>? _summaryData;
  bool _isGenerating = false;

  // Editable controllers
  final _courseController = TextEditingController();
  final _diagnosesController = TextEditingController();
  final _followUpController = TextEditingController();

  @override
  void dispose() {
    _courseController.dispose();
    _diagnosesController.dispose();
    _followUpController.dispose();
    super.dispose();
  }

  void _generateSummary() {
    setState(() => _isGenerating = true);

    final baby = ref.read(babyProvider(widget.babyId));
    if (baby == null) return;

    final storage = ref.read(localStorageProvider);
    final logs = storage.getLogsForBaby(widget.babyId);
    final events = storage.getEventsForBaby(widget.babyId);
    final medications = storage.getMedicationsForBaby(widget.babyId);
    final growth = storage.getGrowthForBaby(widget.babyId);
    final ropScreenings = storage.getScreeningsForBaby(widget.babyId, 'rop');
    final ivhScreenings = storage.getScreeningsForBaby(widget.babyId, 'ivh');
    final echoScreenings = storage.getScreeningsForBaby(widget.babyId, 'echo');
    final hearingScreenings = storage.getScreeningsForBaby(widget.babyId, 'hearing');
    final nbsScreenings = storage.getScreeningsForBaby(widget.babyId, 'nbs');

    final stayDays = baby.dischargeDate != null
        ? baby.dischargeDate!.difference(baby.admissionDate).inDays
        : DateTime.now().difference(baby.admissionDate).inDays;

    // Collect diagnoses from events
    final diagnoses = events
        .where((e) => e['category'] == 'diagnosis')
        .map((e) => e['title'] as String)
        .toList();

    // Collect active problems from latest log
    if (logs.isNotEmpty) {
      logs.sort((a, b) => DateTime.parse(b['logDate'] as String)
          .compareTo(DateTime.parse(a['logDate'] as String)));
      final latestLog = logs.first;
      final problems = latestLog['activeProblemsList'] as List<dynamic>?;
      if (problems != null) {
        for (final p in problems) {
          if (!diagnoses.contains(p)) diagnoses.add(p as String);
        }
      }
    }

    // Compute growth velocity
    double? growthVelocity;
    if (growth.length >= 2) {
      growth.sort((a, b) => DateTime.parse(a['measurementDate'] as String)
          .compareTo(DateTime.parse(b['measurementDate'] as String)));
      final first = growth.first;
      final last = growth.last;
      if (first['weight'] != null && last['weight'] != null) {
        final daysBetween = DateTime.parse(last['measurementDate'] as String)
            .difference(DateTime.parse(first['measurementDate'] as String))
            .inDays;
        if (daysBetween > 0) {
          growthVelocity = ((last['weight'] as num) - (first['weight'] as num)) / daysBetween;
        }
      }
    }

    // Latest measurements
    double? latestWeight, latestHC, latestLength;
    if (growth.isNotEmpty) {
      final latest = growth.last;
      latestWeight = (latest['weight'] as num?)?.toDouble();
      latestHC = (latest['headCircumference'] as num?)?.toDouble();
      latestLength = (latest['length'] as num?)?.toDouble();
    }

    _summaryData = {
      'baby': baby.toJson(),
      'stayDays': stayDays,
      'diagnoses': diagnoses,
      'medications': medications,
      'events': events,
      'ropScreenings': ropScreenings,
      'ivhScreenings': ivhScreenings,
      'echoScreenings': echoScreenings,
      'hearingScreenings': hearingScreenings,
      'nbsScreenings': nbsScreenings,
      'growthVelocity': growthVelocity,
      'latestWeight': latestWeight,
      'latestHC': latestHC,
      'latestLength': latestLength,
    };

    _diagnosesController.text = diagnoses.join('\n');
    _courseController.text = _buildCourseSummary(events);
    _followUpController.text = _buildFollowUpPlan(baby, ropScreenings, echoScreenings);

    setState(() => _isGenerating = false);
  }

  String _buildCourseSummary(List<Map<String, dynamic>> events) {
    if (events.isEmpty) return 'Uneventful NICU course.';
    final buffer = StringBuffer();
    events.sort((a, b) => DateTime.parse(a['eventDate'] as String)
        .compareTo(DateTime.parse(b['eventDate'] as String)));
    for (final e in events) {
      final date = DateTime.parse(e['eventDate'] as String);
      buffer.writeln(
          'DOL ${e['dayOfLife']}: ${e['title']}${e['description'] != null && (e['description'] as String).isNotEmpty ? " - ${e['description']}" : ""}');
    }
    return buffer.toString().trim();
  }

  String _buildFollowUpPlan(dynamic baby, List<Map<String, dynamic>> rop, List<Map<String, dynamic>> echo) {
    final buffer = StringBuffer();
    buffer.writeln('1. Pediatrician follow-up in 1 week');
    if (rop.isNotEmpty) {
      final latest = rop.first;
      if (latest['nextExamDate'] != null) {
        buffer.writeln('2. ROP follow-up: ${AppDateUtils.formatDate(DateTime.parse(latest['nextExamDate'] as String))}');
      }
    }
    if (echo.isNotEmpty) {
      buffer.writeln('3. Echo follow-up as advised');
    }
    buffer.writeln('4. Neurodevelopmental follow-up at 3, 6, 12 months corrected age');
    buffer.writeln('5. Immunizations as per schedule');
    return buffer.toString().trim();
  }

  Future<void> _exportPdf() async {
    if (_summaryData == null) return;

    final baby = ref.read(babyProvider(widget.babyId));
    if (baby == null) return;

    final pdfBytes = await DischargePdfService.generatePdf(
      baby: baby,
      summaryData: _summaryData!,
      clinicalCourse: _courseController.text,
      diagnoses: _diagnosesController.text,
      followUpPlan: _followUpController.text,
    );

    if (mounted) {
      await Printing.layoutPdf(onLayout: (_) => pdfBytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final baby = ref.watch(babyProvider(widget.babyId));
    if (baby == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Discharge Summary')),
        body: const Center(child: Text('Patient not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discharge Summary'),
        actions: [
          if (_summaryData != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _exportPdf,
            ),
        ],
      ),
      body: _summaryData == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.summarize, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('Generate a discharge summary', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Auto-pulls all clinical data for ${baby.fullName}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateSummary,
                    icon: _isGenerating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome),
                    label: const Text('Generate Summary'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                const SectionHeader(title: 'Demographics'),
                _InfoTile('Name', baby.fullName),
                _InfoTile('MRN', baby.mrn),
                _InfoTile('DOB', AppDateUtils.formatDate(baby.dateOfBirth)),
                _InfoTile('Sex', baby.sex),
                _InfoTile('GA at Birth', '${baby.gaWeeks}+${baby.gaDays} weeks'),
                _InfoTile('Birth Weight', '${baby.birthWeightGrams}g'),
                _InfoTile('Admission', AppDateUtils.formatDate(baby.admissionDate)),
                _InfoTile('NICU Stay', '${_summaryData!['stayDays']} days'),
                _InfoTile('CGA at Discharge', baby.correctedGA),

                if (_summaryData!['latestWeight'] != null) ...[
                  const SectionHeader(title: 'Growth at Discharge'),
                  _InfoTile('Weight', '${_summaryData!['latestWeight']}g (Birth: ${baby.birthWeightGrams}g)'),
                  if (_summaryData!['latestHC'] != null) _InfoTile('HC', '${_summaryData!['latestHC']} cm'),
                  if (_summaryData!['latestLength'] != null) _InfoTile('Length', '${_summaryData!['latestLength']} cm'),
                  if (_summaryData!['growthVelocity'] != null)
                    _InfoTile('Growth Velocity', '${(_summaryData!['growthVelocity'] as double).toStringAsFixed(1)} g/day'),
                ],

                const SectionHeader(title: 'Diagnoses'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextFormField(
                    controller: _diagnosesController,
                    maxLines: 5,
                    decoration: const InputDecoration(hintText: 'One diagnosis per line'),
                  ),
                ),

                const SectionHeader(title: 'Clinical Course'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextFormField(
                    controller: _courseController,
                    maxLines: 8,
                    decoration: const InputDecoration(hintText: 'Clinical course summary'),
                  ),
                ),

                const SectionHeader(title: 'Medications at Discharge'),
                ...(_summaryData!['medications'] as List)
                    .where((m) => m['stopDate'] == null)
                    .map((m) => _InfoTile(
                          m['drugName'] as String,
                          '${m['dose']} ${m['unit']} ${m['frequency']} ${m['route']}',
                        )),

                const SectionHeader(title: 'Screening Results'),
                _ScreeningSummary('ROP', _summaryData!['ropScreenings'] as List),
                _ScreeningSummary('IVH', _summaryData!['ivhScreenings'] as List),
                _ScreeningSummary('Echo', _summaryData!['echoScreenings'] as List),
                _ScreeningSummary('Hearing', _summaryData!['hearingScreenings'] as List),
                _ScreeningSummary('NBS', _summaryData!['nbsScreenings'] as List),

                const SectionHeader(title: 'Follow-Up Plan'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextFormField(
                    controller: _followUpController,
                    maxLines: 6,
                    decoration: const InputDecoration(hintText: 'Follow-up plan'),
                  ),
                ),

                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: _exportPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export as PDF'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  ),
                ),
              ],
            ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _ScreeningSummary extends StatelessWidget {
  final String type;
  final List screenings;
  const _ScreeningSummary(this.type, this.screenings);

  @override
  Widget build(BuildContext context) {
    String summary;
    if (screenings.isEmpty) {
      summary = 'Not done';
    } else {
      switch (type) {
        case 'ROP':
          final latest = screenings.first;
          summary = 'RE: Zone ${latest['rightEye_zone']} Stage ${latest['rightEye_stage']}, '
              'LE: Zone ${latest['leftEye_zone']} Stage ${latest['leftEye_stage']}';
          break;
        case 'IVH':
          final latest = screenings.first;
          summary = 'R: ${latest['rightSide_grade']}, L: ${latest['leftSide_grade']}';
          if (latest['periventricularLeukomalacia'] == true) summary += ' (PVL+)';
          break;
        case 'Echo':
          final latest = screenings.first;
          summary = 'PDA: ${latest['pda']}, PHT: ${latest['pulmonaryHypertension'] ?? 'none'}';
          break;
        case 'Hearing':
          final latest = screenings.first;
          summary = 'RE: ${latest['rightEar']}, LE: ${latest['leftEar']} (${latest['method']})';
          break;
        case 'NBS':
          final latest = screenings.first;
          summary = 'Status: ${latest['status']}';
          break;
        default:
          summary = '${screenings.length} done';
      }
    }
    return _InfoTile(type, summary);
  }
}
