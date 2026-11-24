import 'package:absence_management/providers/attendance_provider.dart';
import 'package:absence_management/widgets/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DirectorHomeScreen extends StatelessWidget {
  const DirectorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AttendanceProvider>();
    final stats = data.stats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervision'),
        actions: [
          IconButton(onPressed: data.refresh, icon: const Icon(Icons.refresh_outlined)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: data.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              'Vue d’ensemble de l’établissement',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricCard(
                  icon: Icons.people_outline,
                  label: 'Étudiants',
                  value: '${stats.studentCount}',
                  color: AppColors.primary,
                ),
                _MetricCard(
                  icon: Icons.fact_check_outlined,
                  label: 'Déclarations',
                  value: '${stats.totalRecords}',
                  color: AppColors.accent,
                ),
                _MetricCard(
                  icon: Icons.pending_actions_outlined,
                  label: 'À valider',
                  value: '${stats.pendingValidation}',
                  color: AppColors.warning,
                ),
                _MetricCard(
                  icon: Icons.gavel_outlined,
                  label: 'Litiges',
                  value: '${stats.escalatedClaims}',
                  color: AppColors.danger,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Taux de présence', style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          '${(stats.rate * 100).toStringAsFixed(1)} %',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: stats.rate,
                      minHeight: 12,
                      backgroundColor: AppColors.danger.withValues(alpha: 0.15),
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Répartition', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    _Bar(label: 'Présents', value: stats.present, total: stats.totalRecords, color: AppColors.success),
                    _Bar(label: 'Absents', value: stats.absent, total: stats.totalRecords, color: AppColors.danger),
                    _Bar(label: 'Retards', value: stats.late, total: stats.totalRecords, color: AppColors.warning),
                    _Bar(label: 'Excusés', value: stats.excused, total: stats.totalRecords, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Réclamations', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Text('En attente enseignant : ${stats.pendingClaims}'),
                    Text('Transmises au directeur : ${stats.escalatedClaims}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 160,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color),
                const SizedBox(height: 8),
                Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
        ),
      );
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value, required this.total, required this.color});

  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(label), Text('$value')],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: total == 0 ? 0 : value / total,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.12),
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
      );
}
