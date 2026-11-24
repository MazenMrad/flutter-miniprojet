import 'package:absence_management/models/enums.dart';
import 'package:absence_management/widgets/theme.dart';
import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  factory StatusChip.attendance(AttendanceStatus status) => StatusChip(
        label: status.label,
        color: switch (status) {
          AttendanceStatus.present => AppColors.success,
          AttendanceStatus.late => AppColors.warning,
          AttendanceStatus.absent => AppColors.danger,
          AttendanceStatus.excused => AppColors.primary,
        },
      );

  factory StatusChip.validation(ValidationStatus status) => StatusChip(
        label: status.label,
        color: switch (status) {
          ValidationStatus.approved => AppColors.success,
          ValidationStatus.pending => AppColors.warning,
          ValidationStatus.rejected => AppColors.danger,
        },
      );

  factory StatusChip.session(SessionStatus status) => StatusChip(
        label: status.label,
        color: switch (status) {
          SessionStatus.open => AppColors.success,
          SessionStatus.scheduled => AppColors.primary,
          SessionStatus.closed => AppColors.muted,
        },
      );

  factory StatusChip.claim(ClaimStatus status) => StatusChip(
        label: status.label,
        color: switch (status) {
          ClaimStatus.teacherApproved || ClaimStatus.directorApproved => AppColors.success,
          ClaimStatus.pending || ClaimStatus.escalated => AppColors.warning,
          ClaimStatus.teacherRejected || ClaimStatus.directorRejected => AppColors.danger,
        },
      );

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {this.action, super.key});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          ?action,
        ],
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.message, {super.key, this.icon = Icons.inbox_outlined});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 46, color: AppColors.muted),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
      );
}
