import 'package:absence_management/providers/attendance_provider.dart';
import 'package:absence_management/screens/session_detail_screen.dart';
import 'package:absence_management/widgets/status_chip.dart';
import 'package:absence_management/widgets/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  DateTime _selected = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  List<DateTime> get _week {
    final monday = _selected.subtract(Duration(days: _selected.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: DateTime(_selected.year - 1),
      lastDate: DateTime(_selected.year + 1),
    );
    if (picked != null) setState(() => _selected = picked);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AttendanceProvider>();
    final sessions = data.sessionsOn(_selected)
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emploi du temps'),
        actions: [
          IconButton(onPressed: _pickDate, icon: const Icon(Icons.calendar_month_outlined)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: data.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final day = _week[index];
                  final active = day.day == _selected.day &&
                      day.month == _selected.month &&
                      day.year == _selected.year;
                  return SizedBox(
                    width: 62,
                    child: ChoiceChip(
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_weekday(day.weekday), style: const TextStyle(fontSize: 11)),
                          Text('${day.day}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      selected: active,
                      onSelected: (_) => setState(() => _selected = day),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SectionTitle(
              formatDate(_selected),
              action: Text(
                '${sessions.length} séance${sessions.length > 1 ? 's' : ''}',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
            if (data.loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (sessions.isEmpty)
              const EmptyState('Aucune séance ce jour.', icon: Icons.event_busy_outlined)
            else
              ...sessions.map((session) {
                final count = data.recordsForSession(session.id).length;
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 5,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    title: Text(
                      data.subjectName(session.subjectId),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${session.timeLabel}  •  ${data.className(session.classId)}'
                      '${session.room == null ? '' : '  •  ${session.room}'}',
                    ),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        StatusChip.session(session.status),
                        const SizedBox(height: 4),
                        Text('$count présence(s)', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SessionDetailScreen(sessionId: session.id),
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

  String _weekday(int weekday) => switch (weekday) {
        1 => 'Lun',
        2 => 'Mar',
        3 => 'Mer',
        4 => 'Jeu',
        5 => 'Ven',
        6 => 'Sam',
        _ => 'Dim',
      };
}
