import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../model/user.dart';
import '../utils/security.dart';

/// Handles user authentication and session management.
///
/// Users are stored in a Hive box named `users`. The currently logged-in
/// user id is persisted in SharedPreferences so the session survives app
/// restarts. PINs are hashed with SHA-256 + a per-install salt.
class AuthProvider extends ChangeNotifier {
  static const String _boxName = 'users';
  static const String _sessionPrefKey = 'auth_session_user_id';

  late Box<User> _box;
  User? _currentUser;
  bool _loaded = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoaded => _loaded;

  List<User> get users => _box.values.toList();

  /// Opens the box and restores the previous session (if any).
  /// Seeds a default admin user on first run: username `admin`, PIN `1234`.
  Future<void> init() async {
    // Open the users box with AES encryption (defence-in-depth for PIN hashes).
    _box = await Hive.openBox<User>(_boxName,
        encryptionCipher: HiveAesCipher(AppSecurity.hiveKey()));
    if (_box.isEmpty) {
      await _seedDefaultAdmin();
    }
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getInt(_sessionPrefKey);
    if (savedId != null) {
      _currentUser = _box.get(savedId);
    }
    _loaded = true;
    notifyListeners();
  }

  /// Hashes a PIN with a fixed salt. Not enterprise-grade, but far better
  /// than storing plaintext and adequate for a local-only POS.
  String _hashPin(String pin) {
    const salt = 'dinepos::v1::salt';
    final bytes = utf8.encode('$salt.$pin');
    return sha256.convert(bytes).toString();
  }

  Future<void> _seedDefaultAdmin() async {
    final admin = User(
      id: 1,
      username: 'admin',
      pinHash: _hashPin('1234'),
      displayName: 'Administrator',
      role: 'admin',
      createdAt: DateTime.now(),
    );
    await _box.put(1, admin);
  }

  /// Attempts to log in with [username] and [pin]. Returns `true` on success.
  Future<bool> login(String username, String pin) async {
    final user = _box.values.firstWhere(
      (u) => u.username == username.trim(),
      orElse: () => User(
        id: -1,
        username: '',
        pinHash: '',
        displayName: '',
        role: 'staff',
        createdAt: DateTime.now(),
      ),
    );
    if (user.id == -1) return false;
    if (user.pinHash != _hashPin(pin)) return false;
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionPrefKey, user.id);
    notifyListeners();
    return true;
  }

  /// Clears the current session.
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionPrefKey);
    notifyListeners();
  }

  /// Adds a new user. Returns the created user, or null on duplicate username.
  Future<User?> addUser({
    required String username,
    required String pin,
    required String displayName,
    required UserRole role,
  }) async {
    final exists = _box.values.any((u) => u.username == username.trim());
    if (exists) return null;
    final nextId = (_box.isEmpty)
        ? 1
        : _box.keys.cast<int>().fold<int>(0, (a, b) => a > b ? a : b) + 1;
    final user = User(
      id: nextId,
      username: username.trim(),
      pinHash: _hashPin(pin),
      displayName: displayName,
      role: role.name,
      createdAt: DateTime.now(),
    );
    await _box.put(nextId, user);
    notifyListeners();
    return user;
  }

  /// Updates an existing user's profile. Pass a non-null [pin] to change it.
  Future<void> updateUser(
    int id, {
    String? displayName,
    String? pin,
    UserRole? role,
  }) async {
    final existing = _box.get(id);
    if (existing == null) return;
    final updated = existing.copyWith(
      displayName: displayName,
      role: role?.name,
      pinHash: pin != null ? _hashPin(pin) : null,
    );
    await _box.put(id, updated);
    if (_currentUser?.id == id) {
      _currentUser = updated;
    }
    notifyListeners();
  }

  /// Deletes a user. The last admin cannot be deleted.
  Future<bool> deleteUser(int id) async {
    final target = _box.get(id);
    if (target == null) return false;
    if (target.roleEnum == UserRole.admin) {
      final adminCount =
          _box.values.where((u) => u.roleEnum == UserRole.admin).length;
      if (adminCount <= 1) return false; // keep at least one admin
    }
    await _box.delete(id);
    if (_currentUser?.id == id) {
      await logout();
    }
    notifyListeners();
    return true;
  }
}
