import 'enums.dart';

class Profile {
  final String id;
  final String fullName;
  final AppRole role;
  final String? classId;

  const Profile({
    required this.id,
    required this.fullName,
    required this.role,
    this.classId,
  });

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        id: map['id'] as String,
        fullName: map['full_name'] as String? ?? 'Sans nom',
        role: AppRole.from(map['role']),
        classId: nullableString(map['class_id']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'full_name': fullName,
        'role': role.name,
        'class_id': classId,
      };
}

class SchoolClass {
  final String id;
  final String name;
  final String? level;

  const SchoolClass({required this.id, required this.name, this.level});

  factory SchoolClass.fromMap(Map<String, dynamic> map) => SchoolClass(
        id: map['id'] as String,
        name: map['name'] as String? ?? '',
        level: nullableString(map['level']),
      );

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'level': level};
}

class SubjectInfo {
  final String id;
  final String name;
  final String? code;
  final String teacherId;

  const SubjectInfo({
    required this.id,
    required this.name,
    required this.teacherId,
    this.code,
  });

  factory SubjectInfo.fromMap(Map<String, dynamic> map) => SubjectInfo(
        id: map['id'] as String,
        name: map['name'] as String? ?? '',
        code: nullableString(map['code']),
        teacherId: map['teacher_id'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'code': code,
        'teacher_id': teacherId,
      };
}

class ClassSession {
  final String id;
  final String subjectId;
  final String classId;
  final String teacherId;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? room;
  final SessionStatus status;

  const ClassSession({
    required this.id,
    required this.subjectId,
    required this.classId,
    required this.teacherId,
    required this.startsAt,
    required this.endsAt,
    this.room,
    this.status = SessionStatus.scheduled,
  });

  String get timeLabel =>
      '${startsAt.hour.toString().padLeft(2, '0')}:${startsAt.minute.toString().padLeft(2, '0')}'
      ' – ${endsAt.hour.toString().padLeft(2, '0')}:${endsAt.minute.toString().padLeft(2, '0')}';

  factory ClassSession.fromMap(Map<String, dynamic> map) => ClassSession(
        id: map['id'] as String,
        subjectId: map['subject_id'] as String? ?? '',
        classId: map['class_id'] as String? ?? '',
        teacherId: map['teacher_id'] as String? ?? '',
        startsAt: parseDate(map['starts_at']),
        endsAt: parseDate(map['ends_at']),
        room: nullableString(map['room']),
        status: SessionStatus.from(map['status']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'subject_id': subjectId,
        'class_id': classId,
        'teacher_id': teacherId,
        'starts_at': startsAt.toIso8601String(),
        'ends_at': endsAt.toIso8601String(),
        'room': room,
        'status': status.name,
      };
}

class AttendanceRecord {
  final String id;
  final String sessionId;
  final String studentId;
  final AttendanceStatus status;
  final String source;
  final String? declaredBy;
  final DateTime declaredAt;
  final ValidationStatus validation;
  final String? validatedBy;
  final DateTime? validatedAt;
  final String? note;

  const AttendanceRecord({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.status,
    this.source = 'student',
    this.declaredBy,
    required this.declaredAt,
    this.validation = ValidationStatus.pending,
    this.validatedBy,
    this.validatedAt,
    this.note,
  });

  AttendanceRecord copyWith({
    AttendanceStatus? status,
    ValidationStatus? validation,
    String? validatedBy,
    DateTime? validatedAt,
    String? note,
  }) =>
      AttendanceRecord(
        id: id,
        sessionId: sessionId,
        studentId: studentId,
        status: status ?? this.status,
        source: source,
        declaredBy: declaredBy,
        declaredAt: declaredAt,
        validation: validation ?? this.validation,
        validatedBy: validatedBy ?? this.validatedBy,
        validatedAt: validatedAt ?? this.validatedAt,
        note: note ?? this.note,
      );

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) => AttendanceRecord(
        id: map['id'] as String,
        sessionId: map['session_id'] as String? ?? '',
        studentId: map['student_id'] as String? ?? '',
        status: AttendanceStatus.from(map['status']),
        source: map['source'] as String? ?? 'student',
        declaredBy: nullableString(map['declared_by']),
        declaredAt: parseDate(map['declared_at']),
        validation: ValidationStatus.from(map['validation']),
        validatedBy: nullableString(map['validated_by']),
        validatedAt: map['validated_at'] == null ? null : parseDate(map['validated_at']),
        note: nullableString(map['note']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'student_id': studentId,
        'status': status.name,
        'source': source,
        'declared_by': declaredBy,
        'declared_at': declaredAt.toIso8601String(),
        'validation': validation.name,
        'validated_by': validatedBy,
        'validated_at': validatedAt?.toIso8601String(),
        'note': note,
      };
}

class Claim {
  final String id;
  final String recordId;
  final String studentId;
  final String reason;
  final ClaimStatus status;
  final DateTime createdAt;
  final String? decidedBy;
  final DateTime? decidedAt;
  final String? decisionNote;

  const Claim({
    required this.id,
    required this.recordId,
    required this.studentId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.decidedBy,
    this.decidedAt,
    this.decisionNote,
  });

  Claim copyWith({ClaimStatus? status, String? decidedBy, DateTime? decidedAt, String? decisionNote}) =>
      Claim(
        id: id,
        recordId: recordId,
        studentId: studentId,
        reason: reason,
        status: status ?? this.status,
        createdAt: createdAt,
        decidedBy: decidedBy ?? this.decidedBy,
        decidedAt: decidedAt ?? this.decidedAt,
        decisionNote: decisionNote ?? this.decisionNote,
      );

  factory Claim.fromMap(Map<String, dynamic> map) => Claim(
        id: map['id'] as String,
        recordId: map['record_id'] as String? ?? '',
        studentId: map['student_id'] as String? ?? '',
        reason: map['reason'] as String? ?? '',
        status: ClaimStatus.from(map['status']),
        createdAt: parseDate(map['created_at']),
        decidedBy: nullableString(map['decided_by']),
        decidedAt: map['decided_at'] == null ? null : parseDate(map['decided_at']),
        decisionNote: nullableString(map['decision_note']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'record_id': recordId,
        'student_id': studentId,
        'reason': reason,
        'status': status.dbValue,
        'created_at': createdAt.toIso8601String(),
        'decided_by': decidedBy,
        'decided_at': decidedAt?.toIso8601String(),
        'decision_note': decisionNote,
      };
}

class AuditEntry {
  final String id;
  final String entityType;
  final String entityId;
  final String action;
  final String? actorId;
  final Map<String, dynamic> details;
  final DateTime createdAt;

  const AuditEntry({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    this.actorId,
    this.details = const {},
    required this.createdAt,
  });

  factory AuditEntry.fromMap(Map<String, dynamic> map) => AuditEntry(
        id: map['id'].toString(),
        entityType: map['entity_type'] as String? ?? '',
        entityId: map['entity_id'] as String? ?? '',
        action: map['action'] as String? ?? '',
        actorId: nullableString(map['actor_id']),
        details: (map['details'] as Map?)?.cast<String, dynamic>() ?? const {},
        createdAt: parseDate(map['created_at']),
      );
}

class InstitutionRule {
  final String key;
  final String value;
  final String? description;

  const InstitutionRule({required this.key, required this.value, this.description});

  factory InstitutionRule.fromMap(Map<String, dynamic> map) => InstitutionRule(
        key: map['key'] as String,
        value: map['value'] as String? ?? '',
        description: nullableString(map['description']),
      );

  Map<String, dynamic> toMap() => {
        'key': key,
        'value': value,
        'description': description,
      };
}

class AttendanceStats {
  final int totalRecords;
  final int present;
  final int absent;
  final int late;
  final int excused;
  final int pendingValidation;
  final int pendingClaims;
  final int escalatedClaims;
  final int studentCount;

  const AttendanceStats({
    this.totalRecords = 0,
    this.present = 0,
    this.absent = 0,
    this.late = 0,
    this.excused = 0,
    this.pendingValidation = 0,
    this.pendingClaims = 0,
    this.escalatedClaims = 0,
    this.studentCount = 0,
  });

  double get rate => totalRecords == 0 ? 0 : present / totalRecords;

  factory AttendanceStats.fromMaps({
    required List<AttendanceRecord> records,
    required List<Claim> claims,
    int studentCount = 0,
  }) {
    int count(AttendanceStatus status) =>
        records.where((r) => r.status == status).length;
    return AttendanceStats(
      totalRecords: records.length,
      present: count(AttendanceStatus.present),
      absent: count(AttendanceStatus.absent),
      late: count(AttendanceStatus.late),
      excused: count(AttendanceStatus.excused),
      pendingValidation:
          records.where((r) => r.validation == ValidationStatus.pending).length,
      pendingClaims: claims.where((c) => c.status == ClaimStatus.pending).length,
      escalatedClaims: claims.where((c) => c.status == ClaimStatus.escalated).length,
      studentCount: studentCount,
    );
  }
}
