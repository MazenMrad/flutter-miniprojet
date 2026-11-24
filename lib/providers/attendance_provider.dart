import 'package:absence_management/models/domain.dart';
import 'package:absence_management/models/enums.dart';
import 'package:absence_management/services/attendance_repository.dart';
import 'package:flutter/foundation.dart';

class AttendanceProvider extends ChangeNotifier {
  AttendanceProvider(this._repository);

  final AttendanceRepository _repository;

  Profile? _user;
  List<SchoolClass> _classes = const [];
  List<SubjectInfo> _subjects = const [];
  List<Profile> _profiles = const [];
  List<ClassSession> _sessions = const [];
  List<AttendanceRecord> _records = const [];
  List<Claim> _claims = const [];
  List<InstitutionRule> _rules = const [];
  List<AuditEntry> _audit = const [];
  AttendanceStats _stats = const AttendanceStats();
  bool _loading = false;
  String? _error;
  String? _notice;

  Profile? get user => _user;
  List<SchoolClass> get classes => _classes;
  List<SubjectInfo> get subjects => _subjects;
  List<Profile> get profiles => _profiles;
  List<ClassSession> get sessions => _sessions;
  List<AttendanceRecord> get records => _records;
  List<Claim> get claims => _claims;
  List<InstitutionRule> get rules => _rules;
  List<AuditEntry> get audit => _audit;
  AttendanceStats get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;
  String? get notice => _notice;

  Future<void> load(Profile user) async {
    _user = user;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _classes = await _repository.getClasses();
      _subjects = await _repository.getSubjects();
      _profiles = await _repository.getProfiles();
      _sessions = await _repository.getSessions(user: user);
      _records = user.role == AppRole.student
          ? await _repository.getRecordsForStudent(user.id)
          : await _repository.getAllRecords();
      _claims = await _repository.getClaims(user: user);
      _rules = await _repository.getRules();
      _audit = await _repository.getAuditLog(user: user);
      _stats = await _repository.getStats(user: user);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    final user = _user;
    if (user != null) await load(user);
  }

  Future<bool> _action(String successMessage, Future<void> Function() action) async {
    _error = null;
    _notice = null;
    notifyListeners();
    try {
      await action();
      _notice = successMessage;
      await refresh();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> declare({
    required Profile user,
    required String sessionId,
    required String studentId,
    required AttendanceStatus status,
    int? lateMinutes,
  }) =>
      _action('Déclaration enregistrée.', () => _repository.declareAttendance(
            user: user,
            sessionId: sessionId,
            studentId: studentId,
            status: status,
            lateMinutes: lateMinutes,
          ));

  Future<bool> validate({
    required Profile user,
    required String recordId,
    required ValidationStatus validation,
  }) =>
      _action('Déclaration validée.', () => _repository.validateAttendance(
            user: user,
            recordId: recordId,
            validation: validation,
          ));

  Future<bool> submitClaim({
    required Profile user,
    required String recordId,
    required String reason,
  }) =>
      _action('Réclamation transmise.', () async {
        final record = _records.firstWhere(
          (r) => r.id == recordId,
          orElse: () => throw const RepositoryException('Déclaration introuvable.'),
        );
        final session = _sessions.where((s) => s.id == record.sessionId).firstOrNull;
        if (session == null) {
          throw const RepositoryException('Séance introuvable pour cette déclaration.');
        }
        final delay = DateTime.now().difference(session.startsAt).inDays;
        if (delay > claimDelayDays) {
          throw RepositoryException(
            'Délai de réclamation dépassé ($claimDelayDays jours maximum).',
          );
        }
        await _repository.submitClaim(user: user, recordId: recordId, reason: reason);
      });

  Future<bool> decideClaim({
    required Profile user,
    required String claimId,
    required ClaimStatus status,
    required String note,
  }) =>
      _action('Décision enregistrée.', () => _repository.decideClaim(
            user: user,
            claimId: claimId,
            status: status,
            note: note,
          ));

  Future<bool> updateRule({
    required Profile user,
    required String key,
    required String value,
  }) =>
      _action('Règle mise à jour.', () => _repository.updateRule(
            user: user,
            key: key,
            value: value,
          ));

  void clear() {
    _user = null;
    _classes = const [];
    _subjects = const [];
    _profiles = const [];
    _sessions = const [];
    _records = const [];
    _claims = const [];
    _rules = const [];
    _audit = const [];
    _stats = const AttendanceStats();
    _error = null;
    _notice = null;
    notifyListeners();
  }

  void clearMessages() {
    _error = null;
    _notice = null;
    notifyListeners();
  }

  String ruleValue(String key) => _rules
      .firstWhere((r) => r.key == key, orElse: () => InstitutionRule(key: key, value: ''))
      .value;

  int get lateThresholdMinutes => int.tryParse(ruleValue('late_threshold_minutes')) ?? 15;
  int get maxAbsences => int.tryParse(ruleValue('max_absences')) ?? 4;
  int get claimDelayDays => int.tryParse(ruleValue('claim_delay_days')) ?? 7;

  bool isEffectiveAbsence(AttendanceRecord record) =>
      record.validation == ValidationStatus.approved &&
      (record.status == AttendanceStatus.absent ||
          (record.status == AttendanceStatus.late &&
              (record.lateMinutes ?? 0) > lateThresholdMinutes));

  List<({String id, String name, int count})> studentsOverAbsenceLimit() {
    final counts = <String, int>{};
    for (final record in _records) {
      if (isEffectiveAbsence(record)) {
        counts[record.studentId] = (counts[record.studentId] ?? 0) + 1;
      }
    }
    return _profiles
        .where((p) => p.role == AppRole.student && (counts[p.id] ?? 0) > maxAbsences)
        .map((p) => (id: p.id, name: p.fullName, count: counts[p.id]!))
        .toList();
  }

  String subjectName(String id) =>
      _subjects.firstWhere((s) => s.id == id, orElse: () => SubjectInfo(id: id, name: 'Matière', teacherId: '')).name;

  String className(String id) =>
      _classes.firstWhere((c) => c.id == id, orElse: () => SchoolClass(id: id, name: 'Classe')).name;

  String profileName(String id) =>
      _profiles.firstWhere((p) => p.id == id, orElse: () => Profile(id: id, fullName: 'Inconnu', role: AppRole.student)).fullName;

  List<AttendanceRecord> recordsForSession(String sessionId) =>
      _records.where((r) => r.sessionId == sessionId).toList();

  AttendanceRecord? recordFor(String sessionId, String studentId) {
    for (final record in _records) {
      if (record.sessionId == sessionId && record.studentId == studentId) return record;
    }
    return null;
  }

  List<Claim> claimsForRecord(String recordId) =>
      _claims.where((c) => c.recordId == recordId).toList();

  List<ClassSession> sessionsOn(DateTime date) => _sessions.where((s) =>
      s.startsAt.year == date.year &&
      s.startsAt.month == date.month &&
      s.startsAt.day == date.day).toList();

  List<AttendanceRecord> get pendingRecords {
    final user = _user;
    if (user == null) return const [];
    if (user.role == AppRole.director) {
      return _records.where((r) => r.validation == ValidationStatus.pending).toList();
    }
    final mySessions = _sessions.where((s) => s.teacherId == user.id).map((s) => s.id).toSet();
    return _records
        .where((r) => mySessions.contains(r.sessionId) && r.validation == ValidationStatus.pending)
        .toList();
  }

  List<Claim> get actionableClaims {
    final user = _user;
    if (user == null) return const [];
    if (user.role == AppRole.director) {
      return _claims.where((c) =>
          c.status == ClaimStatus.escalated || c.status == ClaimStatus.pending).toList();
    }
    if (user.role == AppRole.teacher) return _claims.where((c) => c.status == ClaimStatus.pending).toList();
    return _claims;
  }
}
