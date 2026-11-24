import 'package:absence_management/models/enums.dart';
import 'package:absence_management/providers/attendance_provider.dart';
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

  test('teacher can correct a declaration that was already validated', () async {
    final repo = DemoAttendanceRepository();
    final teacher = (await repo.getProfiles()).firstWhere((p) => p.id == 'teacher-1');
    final corrected = await repo.declareAttendance(
      user: teacher,
      sessionId: 'session-2',
      studentId: 'student-2',
      status: AttendanceStatus.absent,
    );
    expect(corrected.status, AttendanceStatus.absent);
    expect(corrected.validation, ValidationStatus.approved);
  });

  test('late threshold rule turns long lateness into an effective absence', () async {
    final repo = DemoAttendanceRepository();
    final provider = AttendanceProvider(repo);
    final profiles = await repo.getProfiles();
    final student = profiles.firstWhere((p) => p.id == 'student-1');
    final teacher = profiles.firstWhere((p) => p.id == 'teacher-1');
    await provider.load(student);
    await provider.declare(
      user: student,
      sessionId: 'session-5',
      studentId: student.id,
      status: AttendanceStatus.late,
      lateMinutes: 30,
    );
    final record = provider.records.firstWhere((r) => r.sessionId == 'session-5');
    await repo.validateAttendance(
      user: teacher,
      recordId: record.id,
      validation: ValidationStatus.approved,
    );
    await provider.load(student);
    final validated = provider.records.firstWhere((r) => r.sessionId == 'session-5');
    expect(provider.isEffectiveAbsence(validated), isTrue);

    await provider.declare(
      user: teacher,
      sessionId: 'session-5',
      studentId: student.id,
      status: AttendanceStatus.late,
      lateMinutes: 5,
    );
    await provider.load(student);
    final corrected = provider.records.firstWhere((r) => r.sessionId == 'session-5');
    expect(provider.isEffectiveAbsence(corrected), isFalse);
  });

  test('claim delay rule rejects contestations outside the allowed window', () async {
    final repo = DemoAttendanceRepository();
    final provider = AttendanceProvider(repo);
    final profiles = await repo.getProfiles();
    final director = profiles.firstWhere((p) => p.role == AppRole.director);
    final student = profiles.firstWhere((p) => p.id == 'student-1');
    await provider.load(director);
    await provider.updateRule(user: director, key: 'claim_delay_days', value: '-1');
    await provider.load(student);
    final ok = await provider.submitClaim(
      user: student,
      recordId: 'r1',
      reason: 'Motif suffisamment détaillé pour être accepté.',
    );
    expect(ok, isFalse);
    expect(provider.error, contains('Délai de réclamation dépassé'));
  });

  test('director detects students above the absence limit', () async {
    final repo = DemoAttendanceRepository();
    final provider = AttendanceProvider(repo);
    final director = (await repo.getProfiles()).firstWhere((p) => p.role == AppRole.director);
    await provider.load(director);
    await provider.updateRule(user: director, key: 'max_absences', value: '0');
    await provider.load(director);
    final flagged = provider.studentsOverAbsenceLimit();
    expect(flagged, isNotEmpty);
    expect(flagged.first.name, 'Lina Benali');
  });

  test('student statistics reflect own records only', () async {
    final repo = DemoAttendanceRepository();
    final student = (await repo.getProfiles()).firstWhere((p) => p.id == 'student-1');
    final stats = await repo.getStats(user: student);
    expect(stats.totalRecords, 3);
    expect(stats.rate, closeTo(1 / 3, 0.001));
  });
}
