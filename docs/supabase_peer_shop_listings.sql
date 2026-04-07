-- 개인 상점(유저 간 별조각 거래) — Supabase SQL 에디터에서 한 번 실행.
-- 앱: [PeerShopRepository] + RPC `purchase_peer_shop_listing`.

create table if not exists public.peer_shop_listings (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references auth.users (id) on delete cascade,
  item_id text not null,
  item_type text not null,
  price_stars int not null check (price_stars >= 1 and price_stars <= 999999),
  seller_display_name text,
  status text not null default 'active' check (status in ('active', 'cancelled', 'sold')),
  buyer_id uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  sold_at timestamptz
);

create index if not exists peer_shop_listings_active_seller_idx
  on public.peer_shop_listings (seller_id)
  where status = 'active';

create index if not exists peer_shop_listings_marketplace_idx
  on public.peer_shop_listings (status, created_at desc);

alter table public.peer_shop_listings enable row level security;

-- 활성 진열은 로그인 사용자 누구나 조회. 취소·판매된 내역은 판매자·구매자만(선택).
drop policy if exists "peer_shop_select" on public.peer_shop_listings;
create policy "peer_shop_select"
  on public.peer_shop_listings for select
  to authenticated
  using (
    status = 'active'
    or seller_id = auth.uid()
    or buyer_id = auth.uid()
  );

drop policy if exists "peer_shop_insert_own" on public.peer_shop_listings;
create policy "peer_shop_insert_own"
  on public.peer_shop_listings for insert
  to authenticated
  with check (seller_id = auth.uid());

-- 판매자만 활성 진열을 취소할 수 있음.
drop policy if exists "peer_shop_seller_cancel" on public.peer_shop_listings;
create policy "peer_shop_seller_cancel"
  on public.peer_shop_listings for update
  to authenticated
  using (seller_id = auth.uid() and status = 'active')
  with check (seller_id = auth.uid() and status in ('active', 'cancelled'));

-- 구매는 아래 RPC만 사용(일반 클라이언트는 판매자 장비/별조각을 직접 수정할 수 없음).

create or replace function public.purchase_peer_shop_listing(p_listing_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_buyer uuid := auth.uid();
  v_row public.peer_shop_listings%rowtype;
  v_buyer_stars int;
begin
  if v_buyer is null then
    return jsonb_build_object('ok', false, 'error', 'auth');
  end if;

  select * into v_row
  from public.peer_shop_listings
  where id = p_listing_id
  for update;

  if not found then
    return jsonb_build_object('ok', false, 'error', 'not_found');
  end if;

  if v_row.status <> 'active' then
    return jsonb_build_object('ok', false, 'error', 'gone');
  end if;

  if v_row.seller_id = v_buyer then
    return jsonb_build_object('ok', false, 'error', 'own');
  end if;

  select star_fragments into v_buyer_stars
  from public.user_profiles
  where id = v_buyer;

  if v_buyer_stars is null then
    return jsonb_build_object('ok', false, 'error', 'error');
  end if;

  if v_buyer_stars < v_row.price_stars then
    return jsonb_build_object('ok', false, 'error', 'stars');
  end if;

  if exists (
    select 1 from public.user_items
    where user_id = v_buyer
      and item_id = v_row.item_id
      and item_type = v_row.item_type
  ) then
    return jsonb_build_object('ok', false, 'error', 'duplicate');
  end if;

  if not exists (
    select 1 from public.user_items
    where user_id = v_row.seller_id
      and item_id = v_row.item_id
      and item_type = v_row.item_type
  ) then
    update public.peer_shop_listings
      set status = 'cancelled'
      where id = p_listing_id;
    return jsonb_build_object('ok', false, 'error', 'seller_item');
  end if;

  update public.user_profiles
    set star_fragments = star_fragments - v_row.price_stars
    where id = v_buyer;

  update public.user_profiles
    set star_fragments = star_fragments + v_row.price_stars
    where id = v_row.seller_id;

  insert into public.user_items (user_id, item_id, item_type)
  values (v_buyer, v_row.item_id, v_row.item_type);

  delete from public.user_items
  where user_id = v_row.seller_id
    and item_id = v_row.item_id
    and item_type = v_row.item_type;

  update public.peer_shop_listings
    set status = 'sold', buyer_id = v_buyer, sold_at = now()
    where id = p_listing_id;

  return jsonb_build_object('ok', true);
end;
$$;

revoke all on function public.purchase_peer_shop_listing(uuid) from public;
grant execute on function public.purchase_peer_shop_listing(uuid) to authenticated;
