import 'package:absence_management/config.dart';
import 'package:absence_management/models/enums.dart';
import 'package:absence_management/providers/auth_provider.dart';
import 'package:absence_management/providers/attendance_provider.dart';
import 'package:absence_management/screens/audit_screen.dart';
import 'package:absence_management/screens/claims_screen.dart';
import 'package:absence_management/screens/director_home.dart';
import 'package:absence_management/screens/rules_screen.dart';
import 'package:absence_management/screens/student_home.dart';
import 'package:absence_management/screens/teacher_home.dart';
import 'package:absence_management/screens/timetable_screen.dart';
import 'package:absence_management/widgets/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;
  String? _lastMessage;
  AttendanceProvider? _data;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _data?.addListener(_onDataChanged);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _data ??= context.read<AttendanceProvider>();
  }

  @override
  void dispose() {
    _data?.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    final data = _data;
    if (data == null) return;
    final message = data.error ?? data.notice;
    if (message == null || message == _lastMessage || !mounted) return;
    _lastMessage = message;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: data.error == null ? AppColors.success : AppColors.danger,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user!;
    final tabs = _tabsFor(user.role);
    if (_tab >= tabs.length) _tab = 0;

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  const Icon(Icons.school_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${user.role.label}  •  Mode ${AppConfig.modeLabel}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: auth.signOut,
                    icon: const Icon(Icons.logout, color: Colors.white, size: 18),
                    label: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: IndexedStack(index: _tab, children: tabs.map((t) => t.screen).toList())),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) {
          setState(() => _tab = index);
          context.read<AttendanceProvider>().clearMessages();
        },
        destinations: tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.selectedIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }

  List<_Tab> _tabsFor(AppRole role) {
    const audit = _Tab('Audit', Icons.history_outlined, Icons.history, AuditScreen());
    final timetable = _Tab('Emploi du temps', Icons.calendar_month_outlined,
        Icons.calendar_month, const TimetableScreen());
    const claims = _Tab('Réclamations', Icons.forum_outlined, Icons.forum, ClaimsScreen());
    const validation = _Tab('Validation', Icons.fact_check_outlined, Icons.fact_check, TeacherHomeScreen());

    return switch (role) {
      AppRole.student => [
          const _Tab('Accueil', Icons.home_outlined, Icons.home, StudentHomeScreen()),
          timetable,
          claims,
          audit,
        ],
      AppRole.teacher => [
          validation,
          timetable,
          claims,
          audit,
        ],
      AppRole.director => [
          const _Tab('Supervision', Icons.dashboard_outlined, Icons.dashboard, DirectorHomeScreen()),
          timetable,
          validation,
          claims,
          const _Tab('Règles', Icons.rule_outlined, Icons.rule, RulesScreen()),
          audit,
        ],
    };
  }
}

class _Tab {
  const _Tab(this.label, this.icon, this.selectedIcon, this.screen);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
}
