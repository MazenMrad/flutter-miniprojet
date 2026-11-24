import 'package:absence_management/models/enums.dart';
import 'package:absence_management/providers/auth_provider.dart';
import 'package:absence_management/services/demo_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('enum conversion matches database values', () {
    expect(ClaimStatus.from('teacher_rejected'), ClaimStatus.teacherRejected);
    expect(ClaimStatus.directorApproved.dbValue, 'director_approved');
    expect(AttendanceStatus.from('present'), AttendanceStatus.present);
    expect(AppRole.from('director'), AppRole.director);
  });

  test('student can declare attendance and it becomes pending', () async {
    final repo = DemoAttendanceRepository();
    final student = (await repo.getProfiles()).firstWhere((p) => p.id == 'student-1');
    final record = await repo.declareAttendance(
      user: student,
      sessionId: 'session-5',
      studentId: student.id,
      status: AttendanceStatus.present,
    );
    expect(record.validation, ValidationStatus.pending);
    expect(record.status, AttendanceStatus.present);
    expect((await repo.getRecordsForStudent(student.id)).length, 4);
  });

  test('validated declaration cannot be edited by a student', () async {
    final repo = DemoAttendanceRepository();
    final student = (await repo.getProfiles()).firstWhere((p) => p.id == 'student-1');
    expect(
      () => repo.declareAttendance(
        user: student,
        sessionId: 'session-1',
        studentId: student.id,
        status: AttendanceStatus.present,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('teacher validates and director decides escalated claim', () async {
    final repo = DemoAttendanceRepository();
    final profiles = await repo.getProfiles();
    final teacher = profiles.firstWhere((p) => p.id == 'teacher-1');
    final director = profiles.firstWhere((p) => p.id == 'director-1');

    final validated = await repo.validateAttendance(
      user: teacher,
      recordId: 'r2',
      validation: ValidationStatus.approved,
    );
    expect(validated.validatedBy, teacher.id);

    final decided = await repo.decideClaim(
      user: director,
      claimId: 'claim-1',
      status: ClaimStatus.directorApproved,
      note: 'Certificat accepté',
    );
    expect(decided.status, ClaimStatus.directorApproved);
    expect(decided.decisionNote, 'Certificat accepté');
  });

  test('every write is recorded in the audit log', () async {
    final repo = DemoAttendanceRepository();
    final profiles = await repo.getProfiles();
    final director = profiles.firstWhere((p) => p.role == AppRole.director);
    await repo.updateRule(user: director, key: 'max_absences', value: '5');
    final log = await repo.getAuditLog(user: director);
    expect(log.first.entityType, 'institution_rules');
    expect(log.first.actorId, director.id);
    expect((await repo.getRules()).first.value, '5');
  });

  test('demo authentication resolves role-based profiles', () async {
    final auth = AuthProvider(repository: DemoAttendanceRepository());
    expect(auth.isDemo, true);
    final ok = await auth.signIn('teacher@demo.school', 'demo1234');
    expect(ok, true);
    expect(auth.user?.role, AppRole.teacher);
    await auth.signOut();
    expect(auth.isAuthenticated, false);
  });

  test('student statistics reflect own records only', () async {
    final repo = DemoAttendanceRepository();
    final student = (await repo.getProfiles()).firstWhere((p) => p.id == 'student-1');
    final stats = await repo.getStats(user: student);
    expect(stats.totalRecords, 3);
    expect(stats.rate, closeTo(1 / 3, 0.001));
  });
}
