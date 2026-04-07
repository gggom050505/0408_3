-- 계정별 별조각·보유품·이모 — 서버가 권위. RLS로 다른 사용자 행 접근·수정 차단.
-- Supabase SQL Editor에서 적용 전, 스테이징에서 정책 충돌·앱 동작을 검증하세요.
-- (이미 유사 정책이 있으면 이름·조건을 맞춰 조정합니다.)

-- ---------------------------------------------------------------------------
-- user_profiles
-- ---------------------------------------------------------------------------
alter table public.user_profiles enable row level security;

drop policy if exists "user_profiles_select_own" on public.user_profiles;
create policy "user_profiles_select_own"
  on public.user_profiles for select
  to authenticated
  using (id = auth.uid());

drop policy if exists "user_profiles_insert_own" on public.user_profiles;
create policy "user_profiles_insert_own"
  on public.user_profiles for insert
  to authenticated
  with check (id = auth.uid());

drop policy if exists "user_profiles_update_own" on public.user_profiles;
create policy "user_profiles_update_own"
  on public.user_profiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- ---------------------------------------------------------------------------
-- user_items (타로·오라클 등 보유 품목)
-- ---------------------------------------------------------------------------
alter table public.user_items enable row level security;

drop policy if exists "user_items_select_own" on public.user_items;
create policy "user_items_select_own"
  on public.user_items for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "user_items_insert_own" on public.user_items;
create policy "user_items_insert_own"
  on public.user_items for insert
  to authenticated
  with check (user_id = auth.uid());

drop policy if exists "user_items_delete_own" on public.user_items;
create policy "user_items_delete_own"
  on public.user_items for delete
  to authenticated
  using (user_id = auth.uid());

-- update 가 없으면 생략. 있을 경우:
drop policy if exists "user_items_update_own" on public.user_items;
create policy "user_items_update_own"
  on public.user_items for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- user_emoticons
-- ---------------------------------------------------------------------------
alter table public.user_emoticons enable row level security;

drop policy if exists "user_emoticons_select_own" on public.user_emoticons;
create policy "user_emoticons_select_own"
  on public.user_emoticons for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "user_emoticons_insert_own" on public.user_emoticons;
create policy "user_emoticons_insert_own"
  on public.user_emoticons for insert
  to authenticated
  with check (user_id = auth.uid());

drop policy if exists "user_emoticons_delete_own" on public.user_emoticons;
create policy "user_emoticons_delete_own"
  on public.user_emoticons for delete
  to authenticated
  using (user_id = auth.uid());

-- 주의: 클라이언트가 star_fragments·품목을 임의로 늘리는 것을 **완전히** 막으려면
-- 민감한 갱신을 Postgres RPC(SECURITY DEFINER)로만 허용하고, 프로필/상품 테이블은
-- update 정책을 제한하는 식의 2단계 설계가 필요합니다. 위 정책은 anon 키로
-- 타 계정 UUID를 넣어 쓰기하는 것을 RLS 수준에서 차단합니다.
