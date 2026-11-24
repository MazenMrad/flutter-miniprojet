import 'package:absence_management/models/domain.dart';
import 'package:absence_management/models/enums.dart';
import 'package:absence_management/providers/auth_provider.dart';
import 'package:absence_management/providers/attendance_provider.dart';
import 'package:absence_management/widgets/status_chip.dart';
import 'package:absence_management/widgets/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SessionDetailScreen extends StatelessWidget {
  const SessionDetailScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AttendanceProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final session = data.sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => ClassSession(
        id: sessionId, subjectId: '', classId: '', teacherId: '',
        startsAt: DateTime.now(), endsAt: DateTime.now(),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(data.subjectName(session.subjectId))),
      body: RefreshIndicator(
        onRefresh: data.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.event_available_outlined, size: 34),
                title: Text(
                  '${formatDate(session.startsAt)}  •  ${session.timeLabel}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${data.className(session.classId)}'
                  '${session.room == null ? '' : '  •  Salle ${session.room}'}'
                  '  •  ${data.profileName(session.teacherId)}',
                ),
                trailing: StatusChip.session(session.status),
              ),
            ),
            if (user?.role == AppRole.student) ...[
              const SizedBox(height: 12),
              const SectionTitle('Ma présence'),
              _StudentAttendance(session: session, studentId: user!.id),
            ] else ...[
              const SizedBox(height: 12),
              SectionTitle(
                'Émargement',
                action: Text(
                  '${data.recordsForSession(sessionId).length} déclaration(s)',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ),
              _Roster(session: session, readOnly: user?.role == AppRole.director),
            ],
          ],
        ),
      ),
    );
  }
}

class _StudentAttendance extends StatelessWidget {
  const _StudentAttendance({required this.session, required this.studentId});

  final ClassSession session;
  final String studentId;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AttendanceProvider>();
    final auth = context.read<AuthProvider>();
    final record = data.recordFor(session.id, studentId);
    final claims = record == null ? const <Claim>[] : data.claimsForRecord(record.id);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (record != null) StatusChip.attendance(record.status),
                if (record != null) const SizedBox(width: 8),
                if (record != null) StatusChip.validation(record.validation),
                if (record == null) const Text('Aucune déclaration pour cette séance.'),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: AttendanceStatus.values
                  .where((s) => record == null || record.validation == ValidationStatus.pending)
                  .map((status) => ChoiceChip(
                        label: Text(status.label),
                        selected: record?.status == status,
                        onSelected: (_) async {
                          final ok = await data.declare(
                            user: auth.user!,
                            sessionId: session.id,
                            studentId: studentId,
                            status: status,
                          );
                          if (!context.mounted) return;
                          _notice(context, data, ok);
                        },
                      ))
                  .toList(),
            ),
            if (record != null &&
                record.validation == ValidationStatus.approved &&
                record.status == AttendanceStatus.absent &&
                claims.isEmpty) ...[
              const SizedBox(height: 14),
              FilledButton.tonal(
                onPressed: () => _claimDialog(context, record),
                child: const Text('Contester cette absence'),
              ),
            ],
            if (claims.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Réclamation : ${claims.first.status.label}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _claimDialog(BuildContext context, AttendanceRecord record) async {
    final controller = TextEditingController();
    final data = context.read<AttendanceProvider>();
    final auth = context.read<AuthProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Contester une absence'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Motif',
            hintText: 'Expliquez pourquoi vous étiez absent…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (ok == true && controller.text.trim().isNotEmpty) {
      final sent = await data.submitClaim(
        user: auth.user!,
        recordId: record.id,
        reason: controller.text,
      );
      if (!context.mounted) return;
      _notice(context, data, sent);
    }
  }
}

class _Roster extends StatelessWidget {
  const _Roster({required this.session, required this.readOnly});

  final ClassSession session;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AttendanceProvider>();
    final auth = context.read<AuthProvider>();
    final students = data.profiles
        .where((p) => p.role == AppRole.student && p.classId == session.classId)
        .toList();

    if (students.isEmpty) return const EmptyState('Aucun étudiant inscrit dans cette classe.');

    return Column(
      children: students.map((student) {
        final record = data.recordFor(session.id, student.id);
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(student.fullName[0])),
            title: Text(student.fullName),
            subtitle: Row(
              children: [
                if (record != null) StatusChip.attendance(record.status),
                const SizedBox(width: 6),
                if (record != null) StatusChip.validation(record.validation),
                if (record == null) const Text('Non déclaré'),
              ],
            ),
            trailing: readOnly
                ? const Icon(Icons.visibility_outlined, color: AppColors.muted)
                : PopupMenuButton<String>(
                    tooltip: 'Actions',
                    onSelected: (action) async {
                      if (action.startsWith('set:')) {
                        final status = AttendanceStatus.from(action.substring(4));
                        final ok = await data.declare(
                          user: auth.user!,
                          sessionId: session.id,
                          studentId: student.id,
                          status: status,
                        );
                        if (!context.mounted) return;
                        _notice(context, data, ok);
                      } else if (record != null) {
                        final ok = await data.validate(
                          user: auth.user!,
                          recordId: record.id,
                          validation: ValidationStatus.from(action),
                        );
                        if (!context.mounted) return;
                        _notice(context, data, ok);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'set:present', child: Text('Marquer présent')),
                      const PopupMenuItem(value: 'set:absent', child: Text('Marquer absent')),
                      const PopupMenuItem(value: 'set:late', child: Text('Marquer retard')),
                      if (record != null) const PopupMenuDivider(),
                      if (record != null)
                        const PopupMenuItem(value: 'approved', child: Text('Valider')),
                      if (record != null)
                        const PopupMenuItem(value: 'rejected', child: Text('Rejeter')),
                    ],
                  ),
          ),
        );
      }).toList(),
    );
  }
}

void _notice(BuildContext context, AttendanceProvider data, bool ok) {
  final message = ok ? data.notice : data.error;
  if (message == null || !context.mounted) return;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: ok ? AppColors.success : AppColors.danger,
    ));
}
