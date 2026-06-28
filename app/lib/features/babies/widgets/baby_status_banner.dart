import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../models/baby_model.dart';
import '../../../core/utils/date_utils.dart';

class BabyStatusBanner extends StatelessWidget {
  final BabyModel baby;

  const BabyStatusBanner({super.key, required this.baby});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(
                  baby.sex == 'male' ? Icons.male : Icons.female,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      baby.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'MRN: ${baby.mrn}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _statusColor.withOpacity(0.5)),
                ),
                child: Text(
                  baby.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _BannerStat('DOL', '${baby.dayOfLife}'),
              _BannerStat('CGA', baby.correctedGA),
              _BannerStat('GA at Birth', baby.gestationalAge),
              _BannerStat('Birth Wt', '${baby.birthWeightGrams}g'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Admitted: ${AppDateUtils.formatDate(baby.admissionDate)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Color get _statusColor {
    switch (baby.status) {
      case 'admitted':
        return Colors.white;
      case 'discharged':
        return AppColors.successLight;
      case 'transferred':
        return AppColors.warningLight;
      case 'expired':
        return AppColors.alertLight;
      default:
        return Colors.white;
    }
  }
}

class _BannerStat extends StatelessWidget {
  final String label;
  final String value;

  const _BannerStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
