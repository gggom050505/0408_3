import 'package:supabase_flutter/supabase_flutter.dart';

import '../standalone/local_user_data_wipe.dart';

const _rpcDeleteMyAccount = 'delete_my_account';

/// Supabase 연동 계정 탈퇴 — 서버에 [docs/supabase_delete_my_account.sql] RPC가 있으면 우선 사용,
/// 없으면 클라이언트에서 RLS가 허용하는 범위로 **연관 데이터만** 순차 삭제합니다.
/// Auth의 `auth.users` 행까지 지우려면 Supabase Edge Function 등 별도 설정이 필요합니다.
class SupabaseAccountWithdrawal {
  SupabaseAccountWithdrawal._();

  static Future<String?> withdrawAndSignOut(SupabaseClient client) async {
    final session = client.auth.currentSession;
    if (session == null) {
      return '로그인된 세션이 없어요.';
    }
    final uid = session.user.id;

    try {
      await client.rpc(_rpcDeleteMyAccount);
    } catch (_) {
      await _bestEffortTableDeletes(client, uid);
    }

    try {
      await wipeOAuthUserLocalArtifacts(uid);
    } catch (_) {}
    try {
      await client.auth.signOut(scope: SignOutScope.global);
    } catch (_) {
      try {
        await client.auth.signOut();
      } catch (_) {
        // 이미 서버에서 세션 무효화된 경우 등 — 로컬만 정리되면 됨
      }
    }
    return null;
  }

  static Future<void> _bestEffortTableDeletes(
    SupabaseClient c,
    String uid,
  ) async {
    Future<void> run(Future<void> Function() fn) async {
      try {
        await fn();
      } catch (_) {}
    }

    await run(() => c.from('gggom_user_app_events').delete().eq('user_id', uid));
    await run(() => c.from('gggom_user_presence').delete().eq('user_id', uid));
    await run(() => c.from('post_likes').delete().eq('user_id', uid));
    await run(() => c.from('comments').delete().eq('user_id', uid));

    try {
      final myPosts =
          await c.from('posts').select('id').eq('user_id', uid) as List<dynamic>;
      for (final row in myPosts) {
        final m = row as Map<String, dynamic>;
        final pid = m['id'];
        if (pid == null) continue;
        await run(() => c.from('post_likes').delete().eq('post_id', pid));
        await run(() => c.from('comments').delete().eq('post_id', pid));
        await run(() => c.from('posts').delete().eq('id', pid));
      }
    } catch (_) {}

    await run(() => c.from('posts').delete().eq('user_id', uid));
    await run(() => c.from('chat_messages').delete().eq('user_id', uid));
    await run(() => c.from('peer_shop_listings').delete().eq('seller_id', uid));
    await run(() => c.from('user_check_ins').delete().eq('user_id', uid));
    await run(() => c.from('user_emoticons').delete().eq('user_id', uid));
    await run(() => c.from('user_items').delete().eq('user_id', uid));
    await run(() => c.from('user_profiles').delete().eq('id', uid));
  }
}
