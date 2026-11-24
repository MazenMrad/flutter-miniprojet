import 'package:absence_management/models/domain.dart';
import 'package:absence_management/models/enums.dart';
import 'package:absence_management/services/attendance_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAttendanceRepository implements AttendanceRepository {
  SupabaseAttendanceRepository(this._client);

  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message);
    }
  }

  List<Map<String, dynamic>> _rows(Object? data) =>
      (data as List? ?? const []).cast<Map<String, dynamic>>();

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const RepositoryException('Session expirée, veuillez vous reconnecter.');
    return id;
  }

  @override
  Future<List<SchoolClass>> getClasses() => _guard(() async {
        final rows = _rows(await _client.from('school_classes').select().order('name'));
        return rows.map(SchoolClass.fromMap).toList();
      });

  @override
  Future<List<SubjectInfo>> getSubjects() => _guard(() async {
        final rows = _rows(await _client.from('subjects').select().order('name'));
        return rows.map(SubjectInfo.fromMap).toList();
      });

  @override
  Future<List<Profile>> getProfiles() => _guard(() async {
        final rows = _rows(await _client.from('profiles').select().order('full_name'));
        return rows.map(Profile.fromMap).toList();
      });

  Future<List<String>> _enrolledClassIds() async {
    final rows = _rows(
      await _client.from('enrollments').select('class_id').eq('student_id', _userId),
    );
    return rows.map((r) => r['class_id'] as String).toList();
  }

  @override
  Future<List<ClassSession>> getSessions({required Profile user}) => _guard(() async {
        var query = _client.from('sessions').select();
        if (user.role == AppRole.student) {
          final ids = await _enrolledClassIds();
          if (ids.isEmpty) return const <ClassSession>[];
          query = query.inFilter('class_id', ids);
        } else if (user.role == AppRole.teacher) {
          query = query.eq('teacher_id', _userId);
        }
        final rows = _rows(await query.order('starts_at'));
        return rows.map(ClassSession.fromMap).toList();
      });

  @override
  Future<List<AttendanceRecord>> getRecordsForStudent(String studentId) => _guard(() async {
        final rows = _rows(
          await _client
              .from('attendance_records')
              .select()
              .eq('student_id', studentId)
              .order('declared_at', ascending: false),
        );
        return rows.map(AttendanceRecord.fromMap).toList();
      });

  @override
  Future<List<AttendanceRecord>> getAllRecords() => _guard(() async {
        final rows = _rows(await _client.from('attendance_records').select());
        return rows.map(AttendanceRecord.fromMap).toList();
      });

  @override
  Future<List<AttendanceRecord>> getRecordsForSession(String sessionId) => _guard(() async {
        final rows = _rows(
          await _client.from('attendance_records').select().eq('session_id', sessionId),
        );
        return rows.map(AttendanceRecord.fromMap).toList();
      });

  @override
  Future<List<Claim>> getClaims({required Profile user, ClaimStatus? status}) => _guard(() async {
        var query = _client.from('claims').select();
        if (status != null) query = query.eq('status', status.dbValue);
        final rows = _rows(await query.order('created_at', ascending: false));
        return rows.map(Claim.fromMap).toList();
      });

  @override
  Future<AttendanceRecord> declareAttendance({
    required Profile user,
    required String sessionId,
    required String studentId,
    required AttendanceStatus status,
  }) =>
      _guard(() async {
        final existing = _rows(
          await _client
              .from('attendance_records')
              .select()
              .eq('session_id', sessionId)
              .eq('student_id', studentId)
              .limit(1),
        );
        if (existing.isNotEmpty) {
          final current = AttendanceRecord.fromMap(existing.first);
          if (current.validation != ValidationStatus.pending) {
            throw const RepositoryException(
              'Cette déclaration est déjà validée et ne peut plus être modifiée.',
            );
          }
          final updated = await _client
              .from('attendance_records')
              .update({'status': status.name})
              .eq('id', current.id)
              .select()
              .single();
          return AttendanceRecord.fromMap(Map<String, dynamic>.from(updated));
        }
        final created = await _client.from('attendance_records').insert({
          'session_id': sessionId,
          'student_id': studentId,
          'status': status.name,
          'source': user.role == AppRole.student ? 'student' : 'teacher',
          'declared_by': _userId,
        }).select().single();
        return AttendanceRecord.fromMap(Map<String, dynamic>.from(created));
      });

  @override
  Future<AttendanceRecord> validateAttendance({
    required Profile user,
    required String recordId,
    required ValidationStatus validation,
  }) =>
      _guard(() async {
        final updated = await _client
            .from('attendance_records')
            .update({
              'validation': validation.name,
              'validated_by': _userId,
              'validated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', recordId)
            .select()
            .single();
        return AttendanceRecord.fromMap(Map<String, dynamic>.from(updated));
      });

  @override
  Future<Claim> submitClaim({
    required Profile user,
    required String recordId,
    required String reason,
  }) =>
      _guard(() async {
        if (reason.trim().length < 5) {
          throw const RepositoryException('Motif trop court (5 caractères minimum).');
        }
        final created = await _client.from('claims').insert({
          'record_id': recordId,
          'student_id': _userId,
          'reason': reason.trim(),
        }).select().single();
        return Claim.fromMap(Map<String, dynamic>.from(created));
      });

  @override
  Future<Claim> decideClaim({
    required Profile user,
    required String claimId,
    required ClaimStatus status,
    required String note,
  }) =>
      _guard(() async {
        final updated = await _client
            .from('claims')
            .update({
              'status': status.dbValue,
              'decided_by': _userId,
              'decided_at': DateTime.now().toUtc().toIso8601String(),
              'decision_note': note.trim().isEmpty ? null : note.trim(),
            })
            .eq('id', claimId)
            .select()
            .single();
        return Claim.fromMap(Map<String, dynamic>.from(updated));
      });

  @override
  Future<List<AuditEntry>> getAuditLog({required Profile user}) => _guard(() async {
        final rows = _rows(
          await _client
              .from('audit_log')
              .select()
              .order('created_at', ascending: false)
              .limit(200),
        );
        return rows.map(AuditEntry.fromMap).toList();
      });

  @override
  Future<List<InstitutionRule>> getRules() => _guard(() async {
        final rows = _rows(await _client.from('institution_rules').select().order('key'));
        return rows.map(InstitutionRule.fromMap).toList();
      });

  @override
  Future<void> updateRule({
    required Profile user,
    required String key,
    required String value,
  }) =>
      _guard(() async {
        await _client.from('institution_rules').update({
          'value': value,
          'updated_by': _userId,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('key', key);
      });

  @override
  Future<AttendanceStats> getStats({required Profile user}) async {
    final records = user.role == AppRole.student
        ? await getRecordsForStudent(user.id)
        : _rows(await _client.from('attendance_records').select())
            .map(AttendanceRecord.fromMap)
            .toList();
    final claims = await getClaims(user: user);
    final profiles = await getProfiles();
    return AttendanceStats.fromMaps(
      records: records,
      claims: claims,
      studentCount: profiles.where((p) => p.role == AppRole.student).length,
    );
  }
}
