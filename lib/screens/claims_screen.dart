import 'package:absence_management/models/domain.dart';
import 'package:absence_management/models/enums.dart';
import 'package:absence_management/providers/auth_provider.dart';
import 'package:absence_management/providers/attendance_provider.dart';
import 'package:absence_management/widgets/status_chip.dart';
import 'package:absence_management/widgets/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ClaimsScreen extends StatelessWidget {
  const ClaimsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AttendanceProvider>();
    final auth = context.read<AuthProvider>();
    final user = auth.user!;
    final claims = data.actionableClaims;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Réclamations'),
        actions: [
          if (user.role == AppRole.student)
            IconButton(
              tooltip: 'Nouvelle réclamation',
              icon: const Icon(Icons.add_comment_outlined),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const _NewClaimDialog(),
              ),
            ),
          IconButton(onPressed: data.refresh, icon: const Icon(Icons.refresh_outlined)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: data.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              user.role == AppRole.student
                  ? 'Suivez vos contestations et leur décision finale.'
                  : 'Traitez les contestations selon votre niveau de responsabilité.',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            if (data.loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (claims.isEmpty)
              const EmptyState('Aucune réclamation à afficher.', icon: Icons.mark_chat_read_outlined)
            else
              ...claims.map((claim) => _ClaimCard(claim: claim, user: user)),
          ],
        ),
      ),
    );
  }
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({required this.claim, required this.user});

  final Claim claim;
  final Profile user;

  Future<void> _decide(BuildContext context, ClaimStatus status) async {
    final controller = TextEditingController();
    final data = context.read<AttendanceProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(status == ClaimStatus.escalated ? 'Transmettre au directeur' : 'Motiver la décision'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Commentaire (facultatif)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final saved = await data.decideClaim(
      user: user,
      claimId: claim.id,
      status: status,
      note: controller.text,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(saved ? data.notice ?? 'Décision enregistrée.' : data.error ?? 'Erreur'),
      backgroundColor: saved ? AppColors.success : AppColors.danger,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AttendanceProvider>();
    final record = data.records.where((r) => r.id == claim.recordId).firstOrNull;
    var sessionTitle = 'Séance';
    if (record != null) {
      for (final session in data.sessions) {
        if (session.id == record.sessionId) {
          sessionTitle = data.subjectName(session.subjectId);
          break;
        }
      }
    }

    final canTeacherAct = user.role == AppRole.teacher && claim.status == ClaimStatus.pending;
    final canDirectorAct = user.role == AppRole.director &&
        (claim.status == ClaimStatus.escalated || claim.status == ClaimStatus.pending);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    sessionTitle,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                StatusChip.claim(claim.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${data.profileName(claim.studentId)}  •  ${formatDate(claim.createdAt)}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 10),
            Text(claim.reason),
            if (claim.decisionNote != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Décision : ${claim.decisionNote}', style: const TextStyle(fontSize: 13)),
              ),
            ],
            if (canTeacherAct || canDirectorAct) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _decide(
                      context,
                      user.role == AppRole.director
                          ? ClaimStatus.directorApproved
                          : ClaimStatus.teacherApproved,
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accepter'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _decide(
                      context,
                      user.role == AppRole.director
                          ? ClaimStatus.directorRejected
                          : ClaimStatus.teacherRejected,
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Rejeter'),
                  ),
                  if (canTeacherAct)
                    OutlinedButton.icon(
                      onPressed: () => _decide(context, ClaimStatus.escalated),
                      icon: const Icon(Icons.arrow_upward_outlined, size: 18),
                      label: const Text('Escalader'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NewClaimDialog extends StatefulWidget {
  const _NewClaimDialog();

  @override
  State<_NewClaimDialog> createState() => _NewClaimDialogState();
}

class _NewClaimDialogState extends State<_NewClaimDialog> {
  String? _recordId;
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AttendanceProvider>();
    final auth = context.read<AuthProvider>();
    final eligible = data.records
        .where((r) =>
            r.studentId == auth.user!.id &&
            r.status == AttendanceStatus.absent &&
            r.validation == ValidationStatus.approved &&
            data.claimsForRecord(r.id).isEmpty)
        .toList();

    return AlertDialog(
      title: const Text('Nouvelle réclamation'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (eligible.isEmpty)
              const Text('Aucune absence validée ne peut être contestée pour le moment.')
            else
              DropdownButtonFormField<String>(
                initialValue: _recordId,
                decoration: const InputDecoration(labelText: 'Absence contestée'),
                items: eligible.map((r) {
                  ClassSession? session;
                  for (final s in data.sessions) {
                    if (s.id == r.sessionId) session = s;
                  }
                  final label = session == null
                      ? formatDate(r.declaredAt)
                      : '${data.subjectName(session.subjectId)} — ${formatDate(session.startsAt)}';
                  return DropdownMenuItem(value: r.id, child: Text(label));
                }).toList(),
                onChanged: (value) => setState(() => _recordId = value),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Motif de la contestation'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: eligible.isEmpty || _recordId == null || _reason.text.trim().length < 5
              ? null
              : () async {
                  final ok = await data.submitClaim(
                    user: auth.user!,
                    recordId: _recordId!,
                    reason: _reason.text,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok ? data.notice ?? 'Réclamation envoyée.' : data.error ?? 'Erreur'),
                    backgroundColor: ok ? AppColors.success : AppColors.danger,
                  ));
                },
          child: const Text('Envoyer'),
        ),
      ],
    );
  }
}
