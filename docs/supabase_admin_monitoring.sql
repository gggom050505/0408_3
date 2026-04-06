-- 관리자 화면「접속·활동」용 테이블·RLS·Realtime
-- Supabase SQL Editor에서 프로젝트에 맞게 실행한 뒤,
-- Table editor → 각 테이블 → Realtime → Turn on (또는 아래 publication 구문)

-- 관리자 이메일은 lib/config/shop_admin_gate.dart 의 kShopAdminGoogleEmail 과 동일해야 합니다.

create table if not exists public.gggom_user_presence (
  user_id uuid primary key references auth.users (id) on delete cascade,
  email text,
  display_name text,
  last_seen_at timestamptz not null default now()
);

create index if not exists gggom_user_presence_last_seen_idx
  on public.gggom_user_presence (last_seen_at desc);

create table if not exists public.gggom_user_app_events (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  email text,
  display_name text,
  action text not null,
  detail text,
  created_at timestamptz not null default now()
);

create index if not exists gggom_user_app_events_created_idx
  on public.gggom_user_app_events (created_at desc);

alter table public.gggom_user_presence enable row level security;
alter table public.gggom_user_app_events enable row level security;

create or replace function public.gggom_is_shop_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select lower(trim(coalesce(auth.jwt() ->> 'email', '')))
    = lower(trim('gggom0505@gmail.com'));
$$;

drop policy if exists "gggom_presence_select_own" on public.gggom_user_presence;
drop policy if exists "gggom_presence_select_admin" on public.gggom_user_presence;
drop policy if exists "gggom_presence_insert_own" on public.gggom_user_presence;
drop policy if exists "gggom_presence_update_own" on public.gggom_user_presence;

create policy "gggom_presence_select_own"
  on public.gggom_user_presence for select
  using (auth.uid() = user_id);

create policy "gggom_presence_select_admin"
  on public.gggom_user_presence for select
  using (public.gggom_is_shop_admin());

create policy "gggom_presence_insert_own"
  on public.gggom_user_presence for insert
  with check (auth.uid() = user_id);

create policy "gggom_presence_update_own"
  on public.gggom_user_presence for update
  using (auth.uid() = user_id);

drop policy if exists "gggom_events_insert_own" on public.gggom_user_app_events;
drop policy if exists "gggom_events_select_admin" on public.gggom_user_app_events;

create policy "gggom_events_insert_own"
  on public.gggom_user_app_events for insert
  with check (auth.uid() = user_id);

create policy "gggom_events_select_admin"
  on public.gggom_user_app_events for select
  using (public.gggom_is_shop_admin());

-- Realtime (이미 추가돼 있으면 무시해도 됨)
do $$
begin
  alter publication supabase_realtime add table public.gggom_user_presence;
exception
  when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.gggom_user_app_events;
exception
  when duplicate_object then null;
end $$;
