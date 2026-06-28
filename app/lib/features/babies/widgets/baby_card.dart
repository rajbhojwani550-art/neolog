import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/status_chip.dart';
import '../models/baby_model.dart';

class BabyCard extends StatelessWidget {
  final BabyModel baby;

  const BabyCard({super.key, required this.baby});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => context.go('/baby/${baby.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _sexColor.withOpacity(0.15),
                child: Icon(
                  baby.sex == 'male' ? Icons.male : Icons.female,
                  color: _sexColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            baby.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        StatusChip.fromStatus(baby.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MRN: ${baby.mrn}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _InfoBadge(
                          label: 'DOL ${baby.dayOfLife}',
                          icon: Icons.calendar_today,
                        ),
                        const SizedBox(width: 10),
                        _InfoBadge(
                          label: 'CGA ${baby.correctedGA}',
                          icon: Icons.access_time,
                        ),
                        const SizedBox(width: 10),
                        _InfoBadge(
                          label: '${baby.birthWeightGrams}g',
                          icon: Icons.monitor_weight_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Color get _sexColor =>
      baby.sex == 'male' ? AppColors.primary : const Color(0xFFE91E63);
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
