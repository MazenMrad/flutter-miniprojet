import 'package:absence_management/models/domain.dart';
import 'package:absence_management/providers/auth_provider.dart';
import 'package:absence_management/providers/attendance_provider.dart';
import 'package:absence_management/widgets/status_chip.dart';
import 'package:absence_management/widgets/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AttendanceProvider>();
    final auth = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Règlement intérieur')),
      body: RefreshIndicator(
        onRefresh: data.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const Text(
              'Les seuils appliqués aux décisions et aux statistiques.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            ...data.rules.map((rule) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.rule_outlined, color: AppColors.primary),
                    title: Text(rule.description ?? rule.key),
                    subtitle: Text('${rule.key} = ${rule.value}'),
                    trailing: IconButton(
                      tooltip: 'Modifier',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _edit(context, rule, auth.user!),
                    ),
                  ),
                )),
            if (data.rules.isEmpty) const EmptyState('Aucune règle configurée.'),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, InstitutionRule rule, Profile user) async {
    final controller = TextEditingController(text: rule.value);
    final data = context.read<AttendanceProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(rule.description ?? rule.key),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: rule.key),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (ok == true && controller.text.trim().isNotEmpty && context.mounted) {
      final saved = await data.updateRule(
        user: user,
        key: rule.key,
        value: controller.text.trim(),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(saved ? data.notice ?? 'Règle enregistrée.' : data.error ?? 'Erreur'),
        backgroundColor: saved ? AppColors.success : AppColors.danger,
      ));
    }
  }
}
