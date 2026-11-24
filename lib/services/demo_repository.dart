import 'package:absence_management/models/domain.dart';
import 'package:absence_management/models/enums.dart';
import 'package:absence_management/services/attendance_repository.dart';
import 'package:uuid/uuid.dart';

class DemoAttendanceRepository implements AttendanceRepository {
  DemoAttendanceRepository() {
    _seed();
  }

  final _uuid = const Uuid();
  final List<SchoolClass> _classes = [];
  final List<Profile> _profiles = [];
  final List<SubjectInfo> _subjects = [];
  final List<ClassSession> _sessions = [];
  final List<AttendanceRecord> _records = [];
  final List<Claim> _claims = [];
  final List<AuditEntry> _audit = [];
  final List<InstitutionRule> _rules = [];

  void _seed() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime at(int dayOffset, int hour) =>
        today.add(Duration(days: dayOffset, hours: hour));

    _classes.addAll([
      const SchoolClass(id: 'c1', name: '2nde A', level: 'Lycée'),
      const SchoolClass(id: 'c2', name: '1ère B', level: 'Lycée'),
    ]);

    _profiles.addAll([
      const Profile(id: 'student-1', fullName: 'Lina Benali', role: AppRole.student, classId: 'c1'),
      const Profile(id: 'student-2', fullName: 'Karim Sassi', role: AppRole.student, classId: 'c1'),
      const Profile(id: 'student-3', fullName: 'Nour Gharbi', role: AppRole.student, classId: 'c2'),
      const Profile(id: 'teacher-1', fullName: 'Mme Chatbouri', role: AppRole.teacher),
      const Profile(id: 'teacher-2', fullName: 'M. Ferjani', role: AppRole.teacher),
      const Profile(id: 'director-1', fullName: 'M. Directeur', role: AppRole.director),
    ]);

    _subjects.addAll([
      const SubjectInfo(id: 'sub1', name: 'Mathématiques', code: 'MATH', teacherId: 'teacher-1'),
      const SubjectInfo(id: 'sub2', name: 'Français', code: 'FR', teacherId: 'teacher-1'),
      const SubjectInfo(id: 'sub3', name: 'Physique', code: 'PHY', teacherId: 'teacher-2'),
    ]);

    _sessions.addAll([
      ClassSession(
        id: 'session-1', subjectId: 'sub1', classId: 'c1', teacherId: 'teacher-1',
        startsAt: at(-1, 8), endsAt: at(-1, 10), room: 'A12', status: SessionStatus.closed,
      ),
      ClassSession(
        id: 'session-2', subjectId: 'sub1', classId: 'c1', teacherId: 'teacher-1',
        startsAt: at(0, 8), endsAt: at(0, 10), room: 'A12', status: SessionStatus.open,
      ),
      ClassSession(
        id: 'session-3', subjectId: 'sub2', classId: 'c1', teacherId: 'teacher-1',
        startsAt: at(0, 10), endsAt: at(0, 12), room: 'B04', status: SessionStatus.open,
      ),
      ClassSession(
        id: 'session-4', subjectId: 'sub3', classId: 'c2', teacherId: 'teacher-2',
        startsAt: at(0, 14), endsAt: at(0, 16), room: 'Labo 2', status: SessionStatus.scheduled,
      ),
      ClassSession(
        id: 'session-5', subjectId: 'sub1', classId: 'c1', teacherId: 'teacher-1',
        startsAt: at(1, 8), endsAt: at(1, 10), room: 'A12', status: SessionStatus.scheduled,
      ),
    ]);

    _records.addAll([
      AttendanceRecord(
        id: 'r1', sessionId: 'session-1', studentId: 'student-1', status: AttendanceStatus.absent,
        declaredAt: at(-1, 10), validation: ValidationStatus.approved,
        validatedBy: 'teacher-1', validatedAt: at(-1, 11),
      ),
      AttendanceRecord(
        id: 'r2', sessionId: 'session-2', studentId: 'student-1', status: AttendanceStatus.present,
        declaredAt: at(0, 8, ), validation: ValidationStatus.pending,
      ),
      AttendanceRecord(
        id: 'r3', sessionId: 'session-3', studentId: 'student-1', status: AttendanceStatus.absent,
        declaredAt: at(0, 10), validation: ValidationStatus.pending,
      ),
      AttendanceRecord(
        id: 'r4', sessionId: 'session-2', studentId: 'student-2', status: AttendanceStatus.present,
        declaredAt: at(0, 8), validation: ValidationStatus.approved,
        validatedBy: 'teacher-1', validatedAt: at(0, 9),
      ),
      AttendanceRecord(
        id: 'r5', sessionId: 'session-4', studentId: 'student-3', status: AttendanceStatus.late,
        declaredAt: at(0, 14), validation: ValidationStatus.pending,
      ),
    ]);

    _claims.add(
      Claim(
        id: 'claim-1', recordId: 'r1', studentId: 'student-1',
        reason: 'J’étais malade ce jour-là, voici un certificat médical.',
        status: ClaimStatus.escalated, createdAt: at(0, 9),
      ),
    );

    _rules.addAll([
      const InstitutionRule(key: 'max_absences', value: '4', description: 'Absences tolérées par trimestre'),
      const InstitutionRule(key: 'late_threshold_minutes', value: '15', description: 'Retard au-delà duquel une absence est relevée'),
      const InstitutionRule(key: 'claim_delay_days', value: '7', description: 'Délai maximal pour contester une absence'),
    ]);
  }

  void _log(String entityType, String entityId, String action, Profile user) {
    _audit.insert(
      0,
      AuditEntry(
        id: _uuid.v4(),
        entityType: entityType,
        entityId: entityId,
        action: action,
        actorId: user.id,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<SchoolClass>> getClasses() async => List.unmodifiable(_classes);

  @override
  Future<List<SubjectInfo>> getSubjects() async => List.unmodifiable(_subjects);

  @override
  Future<List<Profile>> getProfiles() async => List.unmodifiable(_profiles);

  @override
  Future<List<ClassSession>> getSessions({required Profile user}) async {
    if (user.role == AppRole.student) {
      return _sessions.where((s) => s.classId == user.classId).toList();
    }
    if (user.role == AppRole.teacher) {
      return _sessions.where((s) => s.teacherId == user.id).toList();
    }
    return List.unmodifiable(_sessions);
  }

  @override
  Future<List<AttendanceRecord>> getRecordsForStudent(String studentId) async =>
      _records.where((r) => r.studentId == studentId).toList();

  @override
  Future<List<AttendanceRecord>> getAllRecords() async => List.unmodifiable(_records);

  @override
  Future<List<AttendanceRecord>> getRecordsForSession(String sessionId) async =>
      _records.where((r) => r.sessionId == sessionId).toList();

  @override
  Future<List<Claim>> getClaims({required Profile user, ClaimStatus? status}) async {
    var result = _claims.where((c) {
      if (user.role == AppRole.director) return true;
      if (user.role == AppRole.student) return c.studentId == user.id;
      final record = _records.firstWhere((r) => r.id == c.recordId);
      final session = _sessions.firstWhere((s) => s.id == record.sessionId);
      return session.teacherId == user.id;
    });
    if (status != null) result = result.where((c) => c.status == status);
    return result.toList();
  }

  @override
  Future<AttendanceRecord> declareAttendance({
    required Profile user,
    required String sessionId,
    required String studentId,
    required AttendanceStatus status,
    int? lateMinutes,
  }) async {
    if (user.role == AppRole.student && studentId != user.id) {
      throw const RepositoryException('Un étudiant ne peut déclarer que sa propre présence.');
    }
    final existing = _records.firstWhere(
      (r) => r.sessionId == sessionId && r.studentId == studentId,
      orElse: () => AttendanceRecord(
        id: _uuid.v4(),
        sessionId: sessionId,
        studentId: studentId,
        status: status,
        declaredBy: user.id,
        declaredAt: DateTime.now(),
        lateMinutes: status == AttendanceStatus.late ? lateMinutes : null,
      ),
    );
    if (existing.validation != ValidationStatus.pending && user.role == AppRole.student) {
      throw const RepositoryException('Cette déclaration est déjà validée et ne peut plus être modifiée.');
    }
    final updated = AttendanceRecord(
      id: existing.id,
      sessionId: existing.sessionId,
      studentId: existing.studentId,
      status: status,
      source: existing.source,
      declaredBy: existing.declaredBy,
      declaredAt: existing.declaredAt,
      validation: existing.validation,
      validatedBy: existing.validatedBy,
      validatedAt: existing.validatedAt,
      note: null,
      lateMinutes: status == AttendanceStatus.late ? lateMinutes : null,
    );
    if (!_records.contains(existing)) {
      _records.add(updated);
    } else {
      _records[_records.indexOf(existing)] = updated;
    }
    _log('attendance_record', updated.id, 'INSERT', user);
    return updated;
  }

  @override
  Future<AttendanceRecord> validateAttendance({
    required Profile user,
    required String recordId,
    required ValidationStatus validation,
  }) async {
    if (user.role == AppRole.student) {
      throw const RepositoryException('Seul un enseignant ou le directeur peut valider.');
    }
    final index = _records.indexWhere((r) => r.id == recordId);
    if (index == -1) throw const RepositoryException('Déclaration introuvable.');
    final updated = _records[index].copyWith(
      validation: validation,
      validatedBy: user.id,
      validatedAt: DateTime.now(),
    );
    _records[index] = updated;
    _log('attendance_record', recordId, 'UPDATE', user);
    return updated;
  }

  @override
  Future<Claim> submitClaim({
    required Profile user,
    required String recordId,
    required String reason,
  }) async {
    if (reason.trim().length < 5) {
      throw const RepositoryException('Motif trop court (5 caractères minimum).');
    }
    final record = _records.firstWhere(
      (r) => r.id == recordId,
      orElse: () => throw const RepositoryException('Déclaration introuvable.'),
    );
    if (record.studentId != user.id) {
      throw const RepositoryException('Vous ne pouvez contester que vos propres absences.');
    }
    final claim = Claim(
      id: _uuid.v4(),
      recordId: recordId,
      studentId: user.id,
      reason: reason.trim(),
      status: ClaimStatus.pending,
      createdAt: DateTime.now(),
    );
    _claims.insert(0, claim);
    _log('claim', claim.id, 'INSERT', user);
    return claim;
  }

  @override
  Future<Claim> decideClaim({
    required Profile user,
    required String claimId,
    required ClaimStatus status,
    required String note,
  }) async {
    if (user.role == AppRole.student) {
      throw const RepositoryException('Décision réservée à l’administration.');
    }
    final index = _claims.indexWhere((c) => c.id == claimId);
    if (index == -1) throw const RepositoryException('Réclamation introuvable.');
    final updated = _claims[index].copyWith(
      status: status,
      decidedBy: user.id,
      decidedAt: DateTime.now(),
      decisionNote: note.trim().isEmpty ? null : note.trim(),
    );
    _claims[index] = updated;
    _log('claim', claimId, 'UPDATE', user);
    return updated;
  }

  @override
  Future<List<AuditEntry>> getAuditLog({required Profile user}) async {
    if (user.role == AppRole.director) return List.unmodifiable(_audit);
    return _audit.where((e) => e.actorId == user.id).toList();
  }

  @override
  Future<List<InstitutionRule>> getRules() async => List.unmodifiable(_rules);

  @override
  Future<void> updateRule({
    required Profile user,
    required String key,
    required String value,
  }) async {
    if (user.role != AppRole.director) {
      throw const RepositoryException('Seul le directeur peut modifier les règles.');
    }
    final index = _rules.indexWhere((r) => r.key == key);
    if (index == -1) throw const RepositoryException('Règle introuvable.');
    _rules[index] = InstitutionRule(
      key: key,
      value: value,
      description: _rules[index].description,
    );
    _log('institution_rules', key, 'UPDATE', user);
  }

  @override
  Future<AttendanceStats> getStats({required Profile user}) async {
    final records = switch (user.role) {
      AppRole.student => _records.where((r) => r.studentId == user.id).toList(),
      AppRole.teacher => _records.where((r) {
          final session = _sessions.firstWhere((s) => s.id == r.sessionId);
          return session.teacherId == user.id;
        }).toList(),
      AppRole.director => List<AttendanceRecord>.from(_records),
    };
    final claims = await getClaims(user: user);
    return AttendanceStats.fromMaps(
      records: records,
      claims: claims,
      studentCount: _profiles.where((p) => p.role == AppRole.student).length,
    );
  }
}
