import 'package:absence_management/config.dart';
import 'package:absence_management/providers/attendance_provider.dart';
import 'package:absence_management/providers/auth_provider.dart';
import 'package:absence_management/screens/app_shell.dart';
import 'package:absence_management/screens/login_screen.dart';
import 'package:absence_management/services/attendance_repository.dart';
import 'package:absence_management/services/demo_repository.dart';
import 'package:absence_management/services/supabase_repository.dart';
import 'package:absence_management/widgets/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.hasBackend) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseKey,
    );
  }
  final AttendanceRepository repository = AppConfig.hasBackend
      ? SupabaseAttendanceRepository(Supabase.instance.client)
      : DemoAttendanceRepository();
  runApp(AbsenceApp(repository: repository));
}

class AbsenceApp extends StatelessWidget {
  const AbsenceApp({required this.repository, super.key});

  final AttendanceRepository repository;

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(repository: repository)),
          ChangeNotifierProvider(create: (_) => AttendanceProvider(repository)),
        ],
        child: MaterialApp(
          title: 'Assiduité – Gestion des absences',
          theme: AppTheme.light,
          debugShowCheckedModeBanner: false,
          home: const Root(),
        ),
      );
}

class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  bool _restored = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_restored) return;
      _restored = true;
      context.read<AuthProvider>().restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final data = context.read<AttendanceProvider>();

    if (user != null && data.user?.id != user.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) => data.load(user));
    } else if (user == null && data.user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => data.clear());
    }

    if (!auth.isAuthenticated) {
      if (auth.busy && !AppConfig.hasBackend) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return const LoginScreen();
    }
    return const AppShell();
  }
}
