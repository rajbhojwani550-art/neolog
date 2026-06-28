import 'package:flutter/material.dart';
import '../constants/colors.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  factory StatusChip.admitted() => const StatusChip(
        label: 'Admitted',
        backgroundColor: Color(0xFFE3F2FD),
        textColor: AppColors.primary,
        icon: Icons.local_hospital,
      );

  factory StatusChip.discharged() => const StatusChip(
        label: 'Discharged',
        backgroundColor: Color(0xFFE8F5E9),
        textColor: AppColors.success,
        icon: Icons.check_circle_outline,
      );

  factory StatusChip.transferred() => const StatusChip(
        label: 'Transferred',
        backgroundColor: Color(0xFFFFF3E0),
        textColor: AppColors.warning,
        icon: Icons.swap_horiz,
      );

  factory StatusChip.expired() => const StatusChip(
        label: 'Expired',
        backgroundColor: Color(0xFFFFEBEE),
        textColor: AppColors.alert,
        icon: Icons.cancel_outlined,
      );

  factory StatusChip.fromStatus(String status) {
    switch (status.toLowerCase()) {
      case 'admitted':
        return StatusChip.admitted();
      case 'discharged':
        return StatusChip.discharged();
      case 'transferred':
        return StatusChip.transferred();
      case 'expired':
        return StatusChip.expired();
      default:
        return StatusChip(label: status);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor ?? AppColors.textSecondary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor ?? AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
