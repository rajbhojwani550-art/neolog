import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../providers/babies_provider.dart';
import '../widgets/baby_status_banner.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/ga_calculator.dart';

class BabyDetailScreen extends ConsumerWidget {
  final String babyId;
  const BabyDetailScreen({super.key, required this.babyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baby = ref.watch(babyProvider(babyId));

    if (baby == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Patient')),
        body: const Center(child: Text('Patient not found')),
      );
    }

    return DefaultTabController(
      length: 8,
      child: Scaffold(
        appBar: AppBar(
          title: Text(baby.fullName),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {},
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Daily Logs'),
              Tab(text: 'Growth'),
              Tab(text: 'Screenings'),
              Tab(text: 'Medications'),
              Tab(text: 'Events'),
              Tab(text: 'Investigations'),
              Tab(text: 'Discharge'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(babyId: babyId),
            _DailyLogsTab(babyId: babyId),
            _GrowthTab(babyId: babyId),
            _ScreeningsTab(babyId: babyId),
            _MedicationsTab(babyId: babyId),
            _EventsTab(babyId: babyId),
            _InvestigationsTab(babyId: babyId),
            _DischargeTab(babyId: babyId),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  final String babyId;
  const _OverviewTab({required this.babyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baby = ref.watch(babyProvider(babyId));
    if (baby == null) return const SizedBox.shrink();

    return ListView(
      children: [
        BabyStatusBanner(baby: baby),
        const SectionHeader(title: 'Demographics', icon: Icons.person),
        _DetailCard(children: [
          _DetailRow('Full Name', baby.fullName),
          _DetailRow('MRN', baby.mrn),
          _DetailRow('Sex', baby.sex[0].toUpperCase() + baby.sex.substring(1)),
          _DetailRow('Date of Birth', AppDateUtils.formatDate(baby.dateOfBirth)),
          _DetailRow('GA at Birth', '${baby.gaWeeks}+${baby.gaDays} weeks'),
          _DetailRow('Birth Weight', '${baby.birthWeightGrams} grams'),
          _DetailRow('Mode of Delivery', baby.modeOfDelivery),
          if (baby.apgarScore1min != null)
            _DetailRow('APGAR 1/5 min', '${baby.apgarScore1min}/${baby.apgarScore5min ?? "-"}'),
        ]),
        const SectionHeader(title: 'Parents', icon: Icons.people),
        _DetailCard(children: [
          _DetailRow('Mother', baby.motherName),
          _DetailRow('Father', baby.fatherName),
          if (baby.motherAge != null)
            _DetailRow('Mother\'s Age', '${baby.motherAge} years'),
        ]),
        const SectionHeader(title: 'Admission', icon: Icons.local_hospital),
        _DetailCard(children: [
          _DetailRow('Admission Date', AppDateUtils.formatDate(baby.admissionDate)),
          _DetailRow('Reason', baby.admissionReason),
          _DetailRow('Antenatal Steroids', baby.antenatalSteroids),
          if (baby.antenatalHistory != null && baby.antenatalHistory!.isNotEmpty)
            _DetailRow('Antenatal History', baby.antenatalHistory!),
        ]),
        const SectionHeader(title: 'Screening Schedule', icon: Icons.schedule),
        _DetailCard(children: [
          if (GACalculator.needsRopScreening(baby.gaWeeks, baby.birthWeightGrams)) ...[
            _DetailRow(
              'ROP First Exam',
              AppDateUtils.formatDate(
                GACalculator.ropFirstScreeningDate(baby.dateOfBirth, baby.gaWeeks, baby.gaDays),
              ),
            ),
          ],
          _DetailRow(
            'IVH First Scan (72h)',
            AppDateUtils.formatDate(GACalculator.ivhFirstScanDate(baby.dateOfBirth)),
          ),
          _DetailRow(
            'IVH Second Scan (Day 7)',
            AppDateUtils.formatDate(GACalculator.ivhSecondScanDate(baby.dateOfBirth)),
          ),
          if (GACalculator.needsRoutineEcho(baby.gaWeeks))
            _DetailRow('Echo', 'Day 3, 7, 28'),
        ]),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _DailyLogsTab extends StatelessWidget {
  final String babyId;
  const _DailyLogsTab({required this.babyId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Daily Logs', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.go('/baby/$babyId/logs/add'),
            icon: const Icon(Icons.add),
            label: const Text('Add Today\'s Log'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => context.go('/baby/$babyId/logs'),
            child: const Text('View All Logs'),
          ),
        ],
      ),
    );
  }
}

class _GrowthTab extends StatelessWidget {
  final String babyId;
  const _GrowthTab({required this.babyId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.go('/baby/$babyId/growth'),
            icon: const Icon(Icons.trending_up),
            label: const Text('View Growth Chart'),
          ),
        ],
      ),
    );
  }
}

class _ScreeningsTab extends StatelessWidget {
  final String babyId;
  const _ScreeningsTab({required this.babyId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ScreeningCard(
          title: 'ROP Screening',
          subtitle: 'Retinopathy of Prematurity',
          icon: Icons.visibility,
          color: AppColors.alert,
          onTap: () => context.go('/baby/$babyId/rop'),
        ),
        _ScreeningCard(
          title: 'IVH Screening',
          subtitle: 'Intraventricular Hemorrhage',
          icon: Icons.monitor_heart,
          color: AppColors.warning,
          onTap: () => context.go('/baby/$babyId/ivh'),
        ),
        _ScreeningCard(
          title: '2D Echo',
          subtitle: 'Echocardiography',
          icon: Icons.favorite,
          color: AppColors.primary,
          onTap: () => context.go('/baby/$babyId/echo'),
        ),
        _ScreeningCard(
          title: 'Hearing Screen',
          subtitle: 'OAE / AABR',
          icon: Icons.hearing,
          color: AppColors.secondary,
          onTap: () => context.go('/baby/$babyId/hearing'),
        ),
        _ScreeningCard(
          title: 'Newborn Blood Spot',
          subtitle: 'Metabolic screening',
          icon: Icons.bloodtype,
          color: const Color(0xFF7B1FA2),
          onTap: () => context.go('/baby/$babyId/nbs'),
        ),
      ],
    );
  }
}

class _MedicationsTab extends StatelessWidget {
  final String babyId;
  const _MedicationsTab({required this.babyId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => context.go('/baby/$babyId/medications'),
        icon: const Icon(Icons.medication),
        label: const Text('Manage Medications'),
      ),
    );
  }
}

class _EventsTab extends StatelessWidget {
  final String babyId;
  const _EventsTab({required this.babyId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => context.go('/baby/$babyId/events'),
        icon: const Icon(Icons.event_note),
        label: const Text('View Clinical Events'),
      ),
    );
  }
}

class _InvestigationsTab extends StatelessWidget {
  final String babyId;
  const _InvestigationsTab({required this.babyId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => context.go('/baby/$babyId/investigations'),
        icon: const Icon(Icons.science),
        label: const Text('View Investigations'),
      ),
    );
  }
}

class _DischargeTab extends StatelessWidget {
  final String babyId;
  const _DischargeTab({required this.babyId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => context.go('/baby/$babyId/discharge'),
        icon: const Icon(Icons.summarize),
        label: const Text('Generate Discharge Summary'),
      ),
    );
  }
}

class _ScreeningCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ScreeningCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
