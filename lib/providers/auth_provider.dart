import 'package:absence_management/config.dart';
import 'package:absence_management/models/domain.dart';
import 'package:absence_management/models/enums.dart';
import 'package:absence_management/services/attendance_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required this.repository});

  final AttendanceRepository repository;

  Profile? _user;
  bool _busy = false;
  String? _error;

  Profile? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get busy => _busy;
  String? get error => _error;
  bool get isDemo => !AppConfig.hasBackend;

  Future<bool> restoreSession() async {
    if (isDemo) return false;
    final current = Supabase.instance.client.auth.currentUser;
    if (current == null) return false;
    _busy = true;
    notifyListeners();
    try {
      _user = await _profileFor(current.id, current.email ?? '', current.appMetadata['role']);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password, {AppRole? demoRole}) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      if (email.trim().isEmpty || password.trim().isEmpty) {
        throw const RepositoryException('Renseignez l’e-mail et le mot de passe.');
      }
      if (isDemo) {
        if (password.length < 6) {
          throw const RepositoryException('Mot de passe démo : 6 caractères minimum.');
        }
        final role = demoRole ?? _roleFromEmail(email);
        final profiles = await repository.getProfiles();
        final matches = profiles.where((p) => p.role == role).toList();
        if (matches.isEmpty) throw const RepositoryException('Profil introuvable.');
        _user = matches.first;
      } else {
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );
        final authUser = response.user;
        if (authUser == null) throw const RepositoryException('Connexion refusée.');
        _user = await _profileFor(authUser.id, authUser.email ?? '', authUser.appMetadata['role']);
      }
      return true;
    } on RepositoryException catch (e) {
      _error = e.message;
      return false;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Connexion impossible : $e';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<Profile> _profileFor(String id, String email, Object? roleClaim) async {
    final profiles = await repository.getProfiles();
    for (final profile in profiles) {
      if (profile.id == id) return profile;
    }
    return Profile(
      id: id,
      fullName: email.split('@').first,
      role: AppRole.from(roleClaim),
    );
  }

  AppRole _roleFromEmail(String email) {
    final value = email.toLowerCase();
    if (value.contains('teacher') || value.contains('prof')) return AppRole.teacher;
    if (value.contains('director') || value.contains('admin')) return AppRole.director;
    return AppRole.student;
  }

  Future<void> signOut() async {
    if (!isDemo) await Supabase.instance.client.auth.signOut();
    _user = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
