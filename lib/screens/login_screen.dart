import 'package:absence_management/config.dart';
import 'package:absence_management/models/enums.dart';
import 'package:absence_management/providers/auth_provider.dart';
import 'package:absence_management/widgets/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  AppRole _demoRole = AppRole.student;

  static const _demoEmails = {
    AppRole.student: 'student@demo.school',
    AppRole.teacher: 'teacher@demo.school',
    AppRole.director: 'director@demo.school',
  };

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signIn(
      _email.text.trim(),
      _password.text,
      demoRole: auth.isDemo ? _demoRole : null,
    );
    if (ok && mounted) context.read<AuthProvider>().clearError();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school_rounded, size: 56, color: AppColors.primary),
                        const SizedBox(height: 12),
                        Text(
                          'Assiduité',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gestion centralisée des absences scolaires',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 8),
                        Chip(
                          avatar: const Icon(Icons.cloud_outlined, size: 16),
                          label: Text('Mode ${AppConfig.modeLabel}'),
                        ),
                        const SizedBox(height: 22),
                        if (auth.isDemo) ...[
                          DropdownButtonFormField<AppRole>(
                            initialValue: _demoRole,
                            decoration: const InputDecoration(
                              labelText: 'Profil de démonstration',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            items: AppRole.values
                                .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _demoRole = value ?? AppRole.student;
                                _email.text = _demoEmails[_demoRole]!;
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Adresse e-mail',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          validator: (value) => (value ?? '').contains('@') ? null : 'E-mail invalide',
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (value) =>
                              (value ?? '').length >= 6 ? null : '6 caractères minimum',
                        ),
                        if (auth.error != null) ...[
                          const SizedBox(height: 12),
                          Text(auth.error!, style: const TextStyle(color: AppColors.danger)),
                        ],
                        const SizedBox(height: 22),
                        FilledButton(
                          onPressed: auth.busy ? null : _submit,
                          child: auth.busy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Se connecter'),
                        ),
                        if (auth.isDemo) ...[
                          const SizedBox(height: 14),
                          const Text(
                            'Démo : mot de passe « demo1234 ». Les données sont simulées localement.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
