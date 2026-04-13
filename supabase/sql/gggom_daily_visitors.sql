-- Supabase SQL Editor 에서 한 번 실행하세요.
-- 앱은 RPC `gggom_register_daily_visitor_and_count` 만 호출합니다.

create table if not exists public.gggom_daily_visitors (
  visit_date date not null,
  client_id text not null,
  inserted_at timestamptz not null default now(),
  primary key (visit_date, client_id)
);

alter table public.gggom_daily_visitors enable row level security;

-- 직접 테이블 접근은 막고, 아래 SECURITY DEFINER 함수만 anon/authenticated 에게 허용합니다.

create or replace function public.gggom_register_daily_visitor_and_count(
  p_visit_date text,
  p_client_id text
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_date date;
  v_count int;
begin
  if p_visit_date is null or length(trim(p_visit_date)) = 0 then
    return 0;
  end if;
  if p_client_id is null or length(trim(p_client_id)) = 0 then
    return 0;
  end if;

  v_date := p_visit_date::date;

  insert into public.gggom_daily_visitors (visit_date, client_id)
  values (v_date, trim(p_client_id))
  on conflict (visit_date, client_id) do nothing;

  select count(*)::int into v_count
  from public.gggom_daily_visitors
  where visit_date = v_date;

  return v_count;
end;
$$;

grant execute on function public.gggom_register_daily_visitor_and_count(text, text)
  to anon, authenticated;
