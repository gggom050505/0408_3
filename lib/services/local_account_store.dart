import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 자체(로컬) 계정 세션. [userId]는 `local-acc-` 로 시작합니다.
@immutable
class LocalAccountSession {
  const LocalAccountSession({
    required this.userId,
    required this.displayName,
    required this.loginKey,
  });

  final String userId;
  final String displayName;
  /// 내부 저장 맵의 키(아이디 소문자).
  final String loginKey;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'loginKey': loginKey,
      };

  static LocalAccountSession? fromJson(Map<String, dynamic>? j) {
    if (j == null) {
      return null;
    }
    final uid = j['userId'] as String?;
    final name = j['displayName'] as String?;
    final key = j['loginKey'] as String?;
    if (uid == null || name == null || key == null) {
      return null;
    }
    return LocalAccountSession(
      userId: uid,
      displayName: name,
      loginKey: key,
    );
  }
}

/// 기기 내 자체 계정(아이디·비밀번호). 서버 없이 [SharedPreferences]에만 저장합니다.
class LocalAccountStore {
  LocalAccountStore._();
  static final LocalAccountStore instance = LocalAccountStore._();

  static const _kAccounts = 'gggom_local_accounts_v1';
  static const _kSession = 'gggom_local_session_v1';

  static bool isLocalAppUserId(String userId) =>
      userId.startsWith('local-acc-');

  Map<String, dynamic> _readAccountsMap(SharedPreferences prefs) {
    final raw = prefs.getString(_kAccounts);
    if (raw == null || raw.isEmpty) {
      return {};
    }
    try {
      final dec = jsonDecode(raw);
      if (dec is Map) {
        return Map<String, dynamic>.from(
          dec.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
    } catch (_) {}
    return {};
  }

  String _hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt\$$password')).toString();

  String _randomSalt() => List.generate(
        16,
        (_) => Random.secure().nextInt(256),
      ).map((e) => e.toRadixString(16).padLeft(2, '0')).join();

  String _newUserId() {
    final b = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    return 'local-acc-${b.map((e) => e.toRadixString(16).padLeft(2, '0')).join()}';
  }

  String? normalizeUsername(String input) {
    final u = input.trim().toLowerCase();
    if (u.length < 3 || u.length > 24) {
      return null;
    }
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(u)) {
      return null;
    }
    return u;
  }

  Future<LocalAccountSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSession);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final j = jsonDecode(raw);
      if (j is Map) {
        return LocalAccountSession.fromJson(Map<String, dynamic>.from(j));
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveSession(LocalAccountSession s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSession, jsonEncode(s.toJson()));
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSession);
  }

  /// 가입만 (로그인은 별도). 비밀번호 6자 이상.
  Future<String?> register({
    required String username,
    required String password,
    required String displayName,
  }) async {
    final key = normalizeUsername(username);
    if (key == null) {
      return '아이디는 3~24자, 영문 소문자·숫자·밑줄(_)만 사용할 수 있어요.';
    }
    if (password.length < 6) {
      return '비밀번호는 6자 이상이어야 해요.';
    }
    final nick = displayName.trim();
    if (nick.isEmpty || nick.length > 24) {
      return '닉네임은 1~24자로 입력해 주세요.';
    }
    final prefs = await SharedPreferences.getInstance();
    final accounts = _readAccountsMap(prefs);
    if (accounts.containsKey(key)) {
      return '이미 사용 중인 아이디예요.';
    }
    final salt = _randomSalt();
    accounts[key] = {
      'userId': _newUserId(),
      'displayName': nick,
      'passwordHash': _hash(password, salt),
      'salt': salt,
    };
    await prefs.setString(_kAccounts, jsonEncode(accounts));
    return null;
  }

  Future<LocalAccountSession?> login(String username, String password) async {
    final key = normalizeUsername(username);
    if (key == null) {
      return null;
    }
    final prefs = await SharedPreferences.getInstance();
    final accounts = _readAccountsMap(prefs);
    final row = accounts[key];
    if (row is! Map) {
      return null;
    }
    final m = Map<String, dynamic>.from(row);
    final salt = m['salt'] as String?;
    final hash = m['passwordHash'] as String?;
    final userId = m['userId'] as String?;
    final name = m['displayName'] as String? ?? '사용자';
    if (salt == null || hash == null || userId == null) {
      return null;
    }
    if (_hash(password, salt) != hash) {
      return null;
    }
    return LocalAccountSession(
      userId: userId,
      displayName: name,
      loginKey: key,
    );
  }

  Future<String?> updateDisplayName({
    required String loginKey,
    required String newDisplayName,
  }) async {
    final nick = newDisplayName.trim();
    if (nick.isEmpty || nick.length > 24) {
      return '닉네임은 1~24자로 입력해 주세요.';
    }
    final prefs = await SharedPreferences.getInstance();
    final accounts = _readAccountsMap(prefs);
    final row = accounts[loginKey];
    if (row is! Map) {
      return '계정을 찾을 수 없어요.';
    }
    final m = Map<String, dynamic>.from(row);
    m['displayName'] = nick;
    accounts[loginKey] = m;
    await prefs.setString(_kAccounts, jsonEncode(accounts));

    final sess = await loadSession();
    if (sess != null && sess.loginKey == loginKey) {
      await saveSession(LocalAccountSession(
        userId: sess.userId,
        displayName: nick,
        loginKey: loginKey,
      ));
    }
    return null;
  }

  Future<String?> updatePassword({
    required String loginKey,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.length < 6) {
      return '새 비밀번호는 6자 이상이어야 해요.';
    }
    final prefs = await SharedPreferences.getInstance();
    final accounts = _readAccountsMap(prefs);
    final row = accounts[loginKey];
    if (row is! Map) {
      return '계정을 찾을 수 없어요.';
    }
    final m = Map<String, dynamic>.from(row);
    final salt = m['salt'] as String?;
    final hash = m['passwordHash'] as String?;
    if (salt == null || hash == null) {
      return '계정 데이터가 올바르지 않아요.';
    }
    if (_hash(currentPassword, salt) != hash) {
      return '현재 비밀번호가 일치하지 않아요.';
    }
    final newSalt = _randomSalt();
    m['salt'] = newSalt;
    m['passwordHash'] = _hash(newPassword, newSalt);
    accounts[loginKey] = m;
    await prefs.setString(_kAccounts, jsonEncode(accounts));
    return null;
  }

  Future<String?> deleteAccount({
    required String loginKey,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = _readAccountsMap(prefs);
    final row = accounts[loginKey];
    if (row is! Map) {
      return '계정을 찾을 수 없어요.';
    }
    final m = Map<String, dynamic>.from(row);
    final salt = m['salt'] as String?;
    final hash = m['passwordHash'] as String?;
    if (salt == null || hash == null) {
      return '계정 데이터가 올바르지 않아요.';
    }
    if (_hash(password, salt) != hash) {
      return '비밀번호가 일치하지 않아요.';
    }
    accounts.remove(loginKey);
    await prefs.setString(_kAccounts, jsonEncode(accounts));
    final sess = await loadSession();
    if (sess?.loginKey == loginKey) {
      await clearSession();
    }
    return null;
  }
}
