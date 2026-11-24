import 'package:absence_management/models/domain.dart';
import 'package:absence_management/models/enums.dart';
import 'package:absence_management/providers/attendance_provider.dart';
import 'package:absence_management/screens/session_detail_screen.dart';
import 'package:absence_management/widgets/status_chip.dart';
import 'package:absence_management/widgets/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  AttendanceStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AttendanceProvider>();
    final user = data.user;
    final stats = data.stats;
    var records = List<AttendanceRecord>.from(data.records)
      ..sort((a, b) => b.declaredAt.compareTo(a.declaredAt));
    if (_filter != null) {
      records = records.where((r) => r.status == _filter).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon assiduité'),
        actions: [
          IconButton(
            onPressed: data.refresh,
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: data.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Card(
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour ${user?.fullName.split(' ').first ?? ''}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(stats.rate * 100).toStringAsFixed(0)} % de présence',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: stats.rate,
                      backgroundColor: Colors.white24,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${stats.present} présences  •  ${stats.absent} absences  •  '
                      '${stats.late} retards',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Builder(
              builder: (context) {
                final effective = data.records.where(data.isEffectiveAbsence).length;
                final over = effective > data.maxAbsences;
                return Card(
                  color: over ? AppColors.danger.withValues(alpha: 0.1) : null,
                  child: ListTile(
                    leading: Icon(
                      over ? Icons.warning_amber_outlined : Icons.info_outlined,
                      color: over ? AppColors.danger : AppColors.primary,
                    ),
                    title: Text(
                      'Absences prises en compte : $effective / ${data.maxAbsences}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: over ? AppColors.danger : null,
                      ),
                    ),
                    subtitle: Text(
                      'Retards comptés au-delà de ${data.lateThresholdMinutes} min '
                      '• Réclamation sous ${data.claimDelayDays} jours',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            const SectionTitle('Historique'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Tout'),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                  const SizedBox(width: 8),
                  ...AttendanceStatus.values.map((status) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(status.label),
                          selected: _filter == status,
                          onSelected: (_) => setState(() => _filter = status),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (data.loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (records.isEmpty)
              const EmptyState('Aucune déclaration pour ce filtre.', icon: Icons.history_toggle_off)
            else
              ...records.map((record) {
                ClassSession? session;
                for (final candidate in data.sessions) {
                  if (candidate.id == record.sessionId) {
                    session = candidate;
                    break;
                  }
                }
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.school_outlined, color: AppColors.primary),
                    ),
                    title: Text(
                      session == null ? 'Séance' : data.subjectName(session.subjectId),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      session == null
                          ? formatDate(record.declaredAt)
                          : '${formatDate(session.startsAt)}  •  ${session.timeLabel}',
                    ),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        StatusChip.attendance(record.status),
                        const SizedBox(height: 4),
                        Text(record.validation.label, style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                    onTap: session == null
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SessionDetailScreen(sessionId: session!.id),
                            ),
                          ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
