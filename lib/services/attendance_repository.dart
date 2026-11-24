import 'package:absence_management/models/domain.dart';
import 'package:absence_management/models/enums.dart';

class RepositoryException implements Exception {
  final String message;

  const RepositoryException(this.message);

  @override
  String toString() => message;
}

abstract class AttendanceRepository {
  Future<List<SchoolClass>> getClasses();

  Future<List<SubjectInfo>> getSubjects();

  Future<List<Profile>> getProfiles();

  Future<List<ClassSession>> getSessions({required Profile user});

  Future<List<AttendanceRecord>> getRecordsForStudent(String studentId);

  Future<List<AttendanceRecord>> getAllRecords();

  Future<List<AttendanceRecord>> getRecordsForSession(String sessionId);

  Future<List<Claim>> getClaims({required Profile user, ClaimStatus? status});

  Future<AttendanceRecord> declareAttendance({
    required Profile user,
    required String sessionId,
    required String studentId,
    required AttendanceStatus status,
    int? lateMinutes,
  });

  Future<AttendanceRecord> validateAttendance({
    required Profile user,
    required String recordId,
    required ValidationStatus validation,
  });

  Future<Claim> submitClaim({
    required Profile user,
    required String recordId,
    required String reason,
  });

  Future<Claim> decideClaim({
    required Profile user,
    required String claimId,
    required ClaimStatus status,
    required String note,
  });

  Future<List<AuditEntry>> getAuditLog({required Profile user});

  Future<List<InstitutionRule>> getRules();

  Future<void> updateRule({required Profile user, required String key, required String value});

  Future<AttendanceStats> getStats({required Profile user});
}
