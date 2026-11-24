import 'package:absence_management/models/domain.dart';
import 'package:absence_management/models/enums.dart';
import 'package:absence_management/providers/auth_provider.dart';
import 'package:absence_management/providers/attendance_provider.dart';
import 'package:absence_management/widgets/status_chip.dart';
import 'package:absence_management/widgets/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AttendanceProvider>();
    final auth = context.read<AuthProvider>();
    final pending = data.pendingRecords;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des présences'),
        actions: [
          IconButton(onPressed: data.refresh, icon: const Icon(Icons.refresh_outlined)),
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
                child: Row(
                  children: [
                    const Icon(Icons.fact_check_outlined, color: Colors.white, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Déclarations à valider', style: TextStyle(color: Colors.white70)),
                          Text(
                            '${pending.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${data.stats.present} présences\n${data.stats.absent} absences',
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle('File de validation'),
            const SizedBox(height: 8),
            if (data.loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (pending.isEmpty)
              const EmptyState('Toutes les déclarations sont traitées.', icon: Icons.check_circle_outline)
            else
              ...pending.map((record) => _PendingTile(record: record, user: auth.user!)),
          ],
        ),
      ),
    );
  }
}

class _PendingTile extends StatelessWidget {
  const _PendingTile({required this.record, required this.user});

  final AttendanceRecord record;
  final Profile user;

  Future<void> _decide(BuildContext context, ValidationStatus validation) async {
    final data = context.read<AttendanceProvider>();
    final ok = await data.validate(
      user: user,
      recordId: record.id,
      validation: validation,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? data.notice ?? 'Validé.' : data.error ?? 'Erreur'),
      backgroundColor: ok ? AppColors.success : AppColors.danger,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AttendanceProvider>();
    ClassSession? session;
    for (final candidate in data.sessions) {
      if (candidate.id == record.sessionId) {
        session = candidate;
        break;
      }
    }
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(data.profileName(record.studentId)[0])),
        title: Text(
          data.profileName(record.studentId),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(session == null
            ? formatDate(record.declaredAt)
            : '${data.subjectName(session.subjectId)}  •  ${formatDate(session.startsAt)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusChip.attendance(record.status),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Approuver',
              icon: const Icon(Icons.check_circle_outline, color: AppColors.success),
              onPressed: () => _decide(context, ValidationStatus.approved),
            ),
            IconButton(
              tooltip: 'Rejeter',
              icon: const Icon(Icons.cancel_outlined, color: AppColors.danger),
              onPressed: () => _decide(context, ValidationStatus.rejected),
            ),
          ],
        ),
      ),
    );
  }
}
