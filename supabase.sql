-- =====================================================================
-- Khedar48 — Supabase setup. Paste ALL of this in Supabase → SQL Editor → Run.
-- Safe to run again (it skips what already exists).
-- =====================================================================

-- ---------- tables ----------
create table if not exists public.catalog (
  id          text primary key,              -- 'products' | 'promos' | 'drivers' | 'settings'
  data        jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);

create table if not exists public.staff (
  user_id  uuid primary key references auth.users(id) on delete cascade,
  role     text not null check (role in ('admin','driver')),
  name     text not null default '',
  phone    text not null default '',
  email    text not null default ''
);

create table if not exists public.orders (
  id          text primary key,
  uid         uuid not null default auth.uid(),
  at          bigint not null,
  status      text not null default 'new' check (status in ('new','prep','road','done','cancel')),
  driver      text not null default '',
  stk         boolean not null default false,  -- stock already taken out for this order
  data        jsonb not null,                  -- customer, address, items, totals…
  created_at  timestamptz not null default now()
);
create index if not exists orders_uid_idx on public.orders(uid);
create index if not exists orders_at_idx  on public.orders(at desc);

-- ---------- role helpers ----------
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.staff where user_id = auth.uid() and role = 'admin');
$$;
create or replace function public.is_staff() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.staff where user_id = auth.uid() and role in ('admin','driver'));
$$;

-- ---------- security (Row Level Security) ----------
alter table public.catalog enable row level security;
alter table public.staff   enable row level security;
alter table public.orders  enable row level security;

-- catalog: everybody reads, only admin writes
drop policy if exists catalog_read  on public.catalog;
drop policy if exists catalog_write on public.catalog;
create policy catalog_read  on public.catalog for select using (true);
create policy catalog_write on public.catalog for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- staff: you see your own row, admin sees and edits all
drop policy if exists staff_read  on public.staff;
drop policy if exists staff_write on public.staff;
create policy staff_read  on public.staff for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy staff_write on public.staff for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- orders: a customer creates and reads only their own; the team reads all
drop policy if exists orders_read   on public.orders;
drop policy if exists orders_insert on public.orders;
drop policy if exists orders_update on public.orders;
drop policy if exists orders_delete on public.orders;
create policy orders_read on public.orders for select to authenticated
  using (uid = auth.uid() or public.is_staff());
create policy orders_insert on public.orders for insert to authenticated
  with check (
    uid = auth.uid() and status = 'new' and driver = '' and stk = false
    and jsonb_typeof(data->'items') = 'array'
    and jsonb_array_length(data->'items') between 1 and 80
    and pg_column_size(data) < 20000
  );
create policy orders_update on public.orders for update to authenticated
  using (public.is_staff()) with check (public.is_staff());
create policy orders_delete on public.orders for delete to authenticated using (public.is_admin());

-- the team may only change status / driver / stk, never the order contents or price
revoke update on public.orders from anon, authenticated;
grant  update (status, driver, stk) on public.orders to authenticated;

-- ---------- stock: take a delivered order out of stock, exactly once ----------
create or replace function public.apply_stock(oid text) returns void
language plpgsql security definer set search_path = public as $$
declare
  o     record;
  prod  jsonb;
  items jsonb;
  it    jsonb;
  i     int;
begin
  if not public.is_admin() then raise exception 'forbidden'; end if;
  select * into o from public.orders where id = oid for update;
  if not found or o.stk then return; end if;

  select data into prod from public.catalog where id = 'products' for update;
  if prod is not null and jsonb_typeof(prod->'items') = 'array' then
    items := prod->'items';
    for it in select * from jsonb_array_elements(coalesce(o.data->'items', '[]'::jsonb)) loop
      for i in 0 .. jsonb_array_length(items) - 1 loop
        if items->i->>'id' = it->>'id' and jsonb_typeof(items->i->'stock') = 'number' then
          items := jsonb_set(items, array[i::text, 'stock'],
            to_jsonb(greatest(0, round(((items->i->>'stock')::numeric - coalesce((it->>'q')::numeric, 0)) * 100) / 100)));
        end if;
      end loop;
    end loop;
    update public.catalog set data = jsonb_set(prod, '{items}', items), updated_at = now() where id = 'products';
  end if;

  update public.orders set stk = true where id = oid;
end $$;
revoke all on function public.apply_stock(text) from public, anon;
grant execute on function public.apply_stock(text) to authenticated;

-- ---------- live updates (admin sees new orders instantly) ----------
do $$ begin
  begin alter publication supabase_realtime add table public.orders;  exception when others then null; end;
  begin alter publication supabase_realtime add table public.catalog; exception when others then null; end;
end $$;

-- ---------- product photos (public bucket, admin uploads) ----------
insert into storage.buckets (id, name, public) values ('products', 'products', true)
  on conflict (id) do nothing;
drop policy if exists "k48 photos read"   on storage.objects;
drop policy if exists "k48 photos upload" on storage.objects;
create policy "k48 photos read"   on storage.objects for select using (bucket_id = 'products');
create policy "k48 photos upload" on storage.objects for insert to authenticated
  with check (bucket_id = 'products' and public.is_admin());

-- =====================================================================
-- AFTER you created your admin user (Authentication → Users → Add user),
-- run ONLY this line, with your email instead of TON_EMAIL:
--
--   insert into public.staff (user_id, role, name, email)
--   select id, 'admin', 'Admin', email from auth.users where email = 'TON_EMAIL'
--   on conflict (user_id) do update set role = 'admin';
-- =====================================================================
