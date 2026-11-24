import 'package:absence_management/providers/attendance_provider.dart';
import 'package:absence_management/widgets/status_chip.dart';
import 'package:absence_management/widgets/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuditScreen extends StatelessWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AttendanceProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Journal d’audit')),
      body: RefreshIndicator(
        onRefresh: data.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const Text(
              'Chaque déclaration, validation et décision est tracée.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            if (data.loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (data.audit.isEmpty)
              const EmptyState('Aucune opération enregistrée.', icon: Icons.history_toggle_off)
            else
              ...data.audit.map((entry) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Icon(_icon(entry.action), color: AppColors.primary, size: 20),
                      ),
                      title: Text(
                        '${entry.action}  •  ${entry.entityType}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${data.profileName(entry.actorId ?? '')}'
                        '  •  ${formatDate(entry.createdAt)} ${formatTime(entry.createdAt)}'
                        '  •  ${entry.entityId}',
                      ),
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Détail de l’opération'),
                          content: SingleChildScrollView(
                            child: Text(entry.details.toString()),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Fermer'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  IconData _icon(String action) => switch (action) {
        'INSERT' => Icons.add_circle_outline,
        'UPDATE' => Icons.edit_outlined,
        'DELETE' => Icons.delete_outline,
        _ => Icons.info_outline,
      };
}
