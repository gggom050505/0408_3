-- 계정 탈퇴: public 스키마 연관 데이터 일괄 삭제 (RLS 우회를 위해 SECURITY DEFINER)
-- Supabase SQL Editor에서 한 번 실행한 뒤, 앱의 `delete_my_account` RPC가 동작합니다.
-- auth.users 행 삭제는 이 스크립트에 포함하지 않습니다(서비스 롤·Edge Function 권장).

create or replace function public.delete_my_account()
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    return json_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  delete from public.gggom_user_app_events where user_id = uid;
  delete from public.gggom_user_presence where user_id = uid;

  delete from public.post_likes where user_id = uid;
  delete from public.comments where user_id = uid;

  delete from public.post_likes
    where post_id in (select id from public.posts where user_id = uid);
  delete from public.comments
    where post_id in (select id from public.posts where user_id = uid);
  delete from public.posts where user_id = uid;

  delete from public.chat_messages where user_id = uid;
  delete from public.peer_shop_listings where seller_id = uid or buyer_id = uid;
  delete from public.user_check_ins where user_id = uid;
  delete from public.user_emoticons where user_id = uid;
  delete from public.user_items where user_id = uid;
  delete from public.user_profiles where id = uid;

  return json_build_object('ok', true);
end;
$$;

revoke all on function public.delete_my_account() from public;
grant execute on function public.delete_my_account() to authenticated;
