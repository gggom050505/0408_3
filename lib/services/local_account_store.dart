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

@immutable
class LocalAccountIdentitySnapshot {
  const LocalAccountIdentitySnapshot({
    required this.loginKey,
    required this.displayName,
    required this.userId,
    required this.createdAt,
  });

  final String loginKey;
  final String displayName;
  final String userId;
  final DateTime? createdAt;
}

/// 기기 내 자체 계정(아이디·비밀번호). 서버 없이 [SharedPreferences]에만 저장합니다.
class LocalAccountStore {
  LocalAccountStore._();
  static final LocalAccountStore instance = LocalAccountStore._();

  static const _kAccounts = 'gggom_local_accounts_v1';
  static const _kSession = 'gggom_local_session_v1';
  static const _kContinueAsGuest = 'gggom_continue_as_guest_v1';

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

  /// 다음 실행 시 로그인 화면 대신 게스트 홈으로 이어가기(기기 로컬).
  Future<void> setContinueAsGuest(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool(_kContinueAsGuest, true);
    } else {
      await prefs.remove(_kContinueAsGuest);
    }
  }

  Future<bool> shouldContinueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kContinueAsGuest) ?? false;
  }

  /// **회원 가입** — 계정 행만 추가합니다. 성공 후 [login]·[saveSession]으로 로그인 상태를 맞춥니다.
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
      'createdAt': DateTime.now().toUtc().toIso8601String(),
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

  /// **회원 탈퇴 / 계정 삭제**: 성공 시 제거된 [removedUserId]로 기기 JSON 정리에 씁니다.
  Future<({String? error, String? removedUserId})> deleteAccountWithRemovedUserId({
    required String loginKey,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = _readAccountsMap(prefs);
    final row = accounts[loginKey];
    if (row is! Map) {
      return (error: '계정을 찾을 수 없어요.', removedUserId: null);
    }
    final m = Map<String, dynamic>.from(row);
    final salt = m['salt'] as String?;
    final hash = m['passwordHash'] as String?;
    final userId = m['userId'] as String?;
    if (salt == null || hash == null || userId == null) {
      return (error: '계정 데이터가 올바르지 않아요.', removedUserId: null);
    }
    if (_hash(password, salt) != hash) {
      return (error: '비밀번호가 일치하지 않아요.', removedUserId: null);
    }
    accounts.remove(loginKey);
    await prefs.setString(_kAccounts, jsonEncode(accounts));
    final sess = await loadSession();
    if (sess?.loginKey == loginKey) {
      await clearSession();
    }
    return (error: null, removedUserId: userId);
  }

  /// 비밀번호를 잊어 **같은 아이디로 다시 가입**할 때만 사용합니다.
  /// 검증 없이 이 기기의 계정 행만 지우므로, 호출 전에 사용자 확인이 필요합니다.
  Future<({String? error, String? removedUserId})>
      deleteAccountWithoutPasswordForReuse({
    required String loginKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = _readAccountsMap(prefs);
    final row = accounts[loginKey];
    if (row is! Map) {
      return (
        error: '이 기기에 해당 아이디가 없어요. 아이디를 확인하거나 새로 회원 가입해 보세요.',
        removedUserId: null,
      );
    }
    final m = Map<String, dynamic>.from(row);
    final userId = m['userId'] as String?;
    if (userId == null || userId.isEmpty) {
      return (error: '계정 데이터가 올바르지 않아요.', removedUserId: null);
    }
    accounts.remove(loginKey);
    await prefs.setString(_kAccounts, jsonEncode(accounts));
    final sess = await loadSession();
    if (sess?.loginKey == loginKey) {
      await clearSession();
    }
    return (error: null, removedUserId: userId);
  }

  /// **회원 탈퇴 / 계정 삭제** — [removedUserId]가 필요 없을 때(예: 이미 세션에서 알 때).
  Future<String?> deleteAccount({
    required String loginKey,
    required String password,
  }) async {
    final r = await deleteAccountWithRemovedUserId(
      loginKey: loginKey,
      password: password,
    );
    return r.error;
  }

  Future<List<LocalAccountIdentitySnapshot>> listAccountsByDisplayName(
    String displayName,
  ) async {
    final nick = displayName.trim();
    if (nick.isEmpty) {
      return const [];
    }
    final prefs = await SharedPreferences.getInstance();
    final accounts = _readAccountsMap(prefs);
    final out = <LocalAccountIdentitySnapshot>[];
    accounts.forEach((rawLoginKey, rawRow) {
      if (rawRow is! Map) return;
      final row = Map<String, dynamic>.from(rawRow);
      final rowNick = (row['displayName'] as String? ?? '').trim();
      if (rowNick != nick) return;
      final userId = (row['userId'] as String? ?? '').trim();
      if (userId.isEmpty) return;
      final createdAtRaw = row['createdAt'] as String?;
      out.add(
        LocalAccountIdentitySnapshot(
          loginKey: rawLoginKey.toString(),
          displayName: rowNick,
          userId: userId,
          createdAt: createdAtRaw == null
              ? null
              : DateTime.tryParse(createdAtRaw)?.toUtc(),
        ),
      );
    });
    out.sort((a, b) {
      final aT = a.createdAt?.millisecondsSinceEpoch;
      final bT = b.createdAt?.millisecondsSinceEpoch;
      if (aT == null && bT == null) return a.loginKey.compareTo(b.loginKey);
      if (aT == null) return 1;
      if (bT == null) return -1;
      final byTime = aT.compareTo(bT);
      if (byTime != 0) return byTime;
      return a.loginKey.compareTo(b.loginKey);
    });
    return out;
  }
}
