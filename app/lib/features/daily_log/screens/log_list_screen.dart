import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../providers/daily_log_provider.dart';

class LogListScreen extends ConsumerWidget {
  final String babyId;
  const LogListScreen({super.key, required this.babyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(dailyLogProvider(babyId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Logs'),
      ),
      body: logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No daily logs yet',
                      style: TextStyle(
                          fontSize: 16, color: Colors.grey.shade600)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.go('/baby/$babyId/logs/add'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Log'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: logs.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final log = logs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        'D${log.dayOfLife}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    title: Text(
                      AppDateUtils.formatDate(log.logDate),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CGA: ${log.correctedGA}'),
                        Row(
                          children: [
                            if (log.weight != null)
                              _MiniChip('${log.weight}g'),
                            if (log.respiratorySupport != 'room air')
                              _MiniChip(log.respiratorySupport),
                            if (log.feedType != 'NPO')
                              _MiniChip(log.feedType),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        context.go('/baby/$babyId/logs/${log.id}'),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/baby/$babyId/logs/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  const _MiniChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, color: AppColors.secondary),
      ),
    );
  }
}
