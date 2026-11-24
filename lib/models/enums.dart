enum AppRole {
  student,
  teacher,
  director;

  static AppRole from(Object? value) =>
      AppRole.values.firstWhere((e) => e.name == value, orElse: () => AppRole.student);

  String get label => switch (this) {
        AppRole.student => 'Étudiant',
        AppRole.teacher => 'Enseignant',
        AppRole.director => 'Directeur',
      };
}

enum AttendanceStatus {
  present,
  absent,
  late,
  excused;

  static AttendanceStatus from(Object? value) => AttendanceStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => AttendanceStatus.absent,
      );

  String get label => switch (this) {
        AttendanceStatus.present => 'Présent',
        AttendanceStatus.absent => 'Absent',
        AttendanceStatus.late => 'Retard',
        AttendanceStatus.excused => 'Excusé',
      };
}

enum ValidationStatus {
  pending,
  approved,
  rejected;

  static ValidationStatus from(Object? value) => ValidationStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ValidationStatus.pending,
      );

  String get label => switch (this) {
        ValidationStatus.pending => 'En attente',
        ValidationStatus.approved => 'Validé',
        ValidationStatus.rejected => 'Rejeté',
      };
}

enum ClaimStatus {
  pending,
  teacherApproved,
  teacherRejected,
  escalated,
  directorApproved,
  directorRejected;

  static ClaimStatus from(Object? value) {
    final raw = value?.toString() ?? '';
    final camel = raw.replaceAllMapped(
      RegExp(r'_([a-z])'),
      (m) => m.group(1)!.toUpperCase(),
    );
    return ClaimStatus.values.firstWhere((e) => e.name == camel, orElse: () => ClaimStatus.pending);
  }

  String get dbValue => name.replaceAllMapped(
        RegExp(r'([A-Z])'),
        (m) => '_${m.group(0)!.toLowerCase()}',
      );

  String get label => switch (this) {
        ClaimStatus.pending => 'En attente enseignant',
        ClaimStatus.teacherApproved => 'Accepté par l’enseignant',
        ClaimStatus.teacherRejected => 'Rejeté par l’enseignant',
        ClaimStatus.escalated => 'Transmis au directeur',
        ClaimStatus.directorApproved => 'Accepté par le directeur',
        ClaimStatus.directorRejected => 'Rejeté par le directeur',
      };
}

enum SessionStatus {
  scheduled,
  open,
  closed;

  static SessionStatus from(Object? value) =>
      SessionStatus.values.firstWhere((e) => e.name == value, orElse: () => SessionStatus.scheduled);

  String get label => switch (this) {
        SessionStatus.scheduled => 'Programmée',
        SessionStatus.open => 'Séance ouverte',
        SessionStatus.closed => 'Clôturée',
      };
}

DateTime parseDate(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);

String? nullableString(Object? value) => value?.toString();
