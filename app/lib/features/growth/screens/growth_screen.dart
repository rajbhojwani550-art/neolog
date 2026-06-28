import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/fenton_data.dart';
import '../../../core/utils/ga_calculator.dart';
import '../../../core/utils/percentile_calc.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/section_header.dart';
import '../../../services/local_storage.dart';
import '../../babies/providers/babies_provider.dart';
import '../widgets/fenton_chart.dart';

class GrowthScreen extends ConsumerStatefulWidget {
  final String babyId;
  const GrowthScreen({super.key, required this.babyId});

  @override
  ConsumerState<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends ConsumerState<GrowthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _measurements = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMeasurements();
  }

  void _loadMeasurements() {
    final storage = ref.read(localStorageProvider);
    _measurements = storage.getGrowthForBaby(widget.babyId)
      ..sort((a, b) =>
          DateTime.parse(a['measurementDate'] as String)
              .compareTo(DateTime.parse(b['measurementDate'] as String)));
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddMeasurement() {
    final weightC = TextEditingController();
    final hcC = TextEditingController();
    final lengthC = TextEditingController();
    var date = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add Measurement',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setSheetState(() => date = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date'),
                  child: Text('${date.day}/${date.month}/${date.year}'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: weightC,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Weight (grams)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: hcC,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Head Circumference (cm)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: lengthC,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Length (cm)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _saveMeasurement(
                    date: date,
                    weight: double.tryParse(weightC.text),
                    hc: double.tryParse(hcC.text),
                    length: double.tryParse(lengthC.text),
                  );
                  Navigator.pop(ctx);
                },
                child: const Text('Save Measurement'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveMeasurement({
    required DateTime date,
    double? weight,
    double? hc,
    double? length,
  }) async {
    if (weight == null && hc == null && length == null) return;

    final baby = ref.read(babyProvider(widget.babyId));
    if (baby == null) return;

    final cgaWeeks = GACalculator.cgaInWeeks(
        baby.dateOfBirth, baby.gaWeeks, baby.gaDays, date);

    final weightData = FentonData.getWeightData(baby.sex);
    final hcData = FentonData.getHCData(baby.sex);
    final lengthData = FentonData.getLengthData(baby.sex);

    final measurement = {
      'id': const Uuid().v4(),
      'babyId': widget.babyId,
      'measurementDate': date.toIso8601String(),
      'weight': weight,
      'headCircumference': hc,
      'length': length,
      'correctedGA': GACalculator.computeCGA(
          baby.dateOfBirth, baby.gaWeeks, baby.gaDays, date),
      'correctedGAWeeks': cgaWeeks,
      'weightPercentile': weight != null
          ? PercentileCalculator.calculatePercentile(
              cgaWeeks: cgaWeeks, value: weight, referenceData: weightData)
          : null,
      'hcPercentile': hc != null
          ? PercentileCalculator.calculatePercentile(
              cgaWeeks: cgaWeeks, value: hc, referenceData: hcData)
          : null,
      'lengthPercentile': length != null
          ? PercentileCalculator.calculatePercentile(
              cgaWeeks: cgaWeeks, value: length, referenceData: lengthData)
          : null,
    };

    final storage = ref.read(localStorageProvider);
    await storage.saveGrowth(measurement);
    _loadMeasurements();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Measurement saved'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final baby = ref.watch(babyProvider(widget.babyId));
    if (baby == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Growth')),
        body: const Center(child: Text('Patient not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Growth Chart'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Weight'),
            Tab(text: 'Head Circ'),
            Tab(text: 'Length'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _GrowthTabContent(
            baby: baby,
            measurements: _measurements,
            type: 'weight',
            unit: 'g',
          ),
          _GrowthTabContent(
            baby: baby,
            measurements: _measurements,
            type: 'hc',
            unit: 'cm',
          ),
          _GrowthTabContent(
            baby: baby,
            measurements: _measurements,
            type: 'length',
            unit: 'cm',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMeasurement,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _GrowthTabContent extends StatelessWidget {
  final dynamic baby;
  final List<Map<String, dynamic>> measurements;
  final String type;
  final String unit;

  const _GrowthTabContent({
    required this.baby,
    required this.measurements,
    required this.type,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final dataKey = type == 'hc' ? 'headCircumference' : type;
    final percentileKey = '${type}Percentile';
    final filteredMeasurements = measurements
        .where((m) => m[dataKey] != null)
        .toList();

    return ListView(
      children: [
        SizedBox(
          height: 350,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FentonChart(
              baby: baby,
              measurements: filteredMeasurements,
              type: type,
            ),
          ),
        ),
        const SectionHeader(title: 'Measurements'),
        if (filteredMeasurements.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No measurements recorded yet',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          )
        else
          ...filteredMeasurements.reversed.map((m) {
            final date = DateTime.parse(m['measurementDate'] as String);
            final value = m[dataKey];
            final percentile = m[percentileKey];
            return ListTile(
              title: Text('$value $unit'),
              subtitle: Text(
                '${AppDateUtils.formatDate(date)} • CGA ${m['correctedGA']}',
              ),
              trailing: percentile != null
                  ? Text(
                      'P${percentile.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _percentileColor(percentile as double),
                      ),
                    )
                  : null,
            );
          }),
        const SizedBox(height: 80),
      ],
    );
  }

  Color _percentileColor(double p) {
    if (p < 3) return AppColors.alert;
    if (p < 10) return AppColors.warning;
    if (p > 97) return AppColors.warning;
    return AppColors.success;
  }
}
