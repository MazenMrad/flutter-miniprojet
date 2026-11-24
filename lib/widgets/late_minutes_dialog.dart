import 'package:flutter/material.dart';

Future<int?> showLateMinutesDialog(BuildContext context) {
  final controller = TextEditingController(text: '0');
  return showDialog<int>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Minutes de retard'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Retard constaté (minutes)',
          helperText: 'Au-delà du seuil, le retard compte comme une absence.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            final value = int.tryParse(controller.text.trim()) ?? 0;
            Navigator.pop(dialogContext, value < 0 ? 0 : value);
          },
          child: const Text('Valider'),
        ),
      ],
    ),
  );
}
