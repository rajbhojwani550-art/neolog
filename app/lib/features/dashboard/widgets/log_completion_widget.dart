import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../babies/models/baby_model.dart';

class LogCompletionWidget extends StatelessWidget {
  final List<BabyModel> babies;

  const LogCompletionWidget({super.key, required this.babies});

  @override
  Widget build(BuildContext context) {
    final admitted = babies.where((b) => b.status == 'admitted').toList();
    if (admitted.isEmpty) return const SizedBox.shrink();

    // In real app, check which babies have today's log
    final completed = 0;
    final total = admitted.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Log Completion",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$completed / $total',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: completed == total && total > 0
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                completed == total && total > 0
                    ? AppColors.success
                    : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            completed == total && total > 0
                ? 'All logs completed for today!'
                : '${total - completed} logs pending for today',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
