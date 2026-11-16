-- Khedar48 · Call Center : rôle « agent », journal des appels, leads (CRM)
alter table public.staff drop constraint if exists staff_role_check;
alter table public.staff add constraint staff_role_check check (role in ('admin','driver','agent'));

create or replace function public.is_staff() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.staff where user_id = auth.uid() and role in ('admin','driver','agent'));
$$;
create or replace function public.is_agent() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.staff where user_id = auth.uid() and role in ('admin','agent'));
$$;

create table if not exists public.calls (
  id      bigint generated always as identity primary key,
  at      timestamptz not null default now(),
  agent   uuid not null default auth.uid(),
  phone   text not null check (length(phone) between 6 and 20),
  name    text not null default '' check (length(name) <= 80),
  kind    text not null check (kind in ('confirm','new','follow','complaint','lead')),
  result  text not null check (result in ('confirmed','ordered','no_answer','callback','cancelled','info')),
  oid     text check (length(oid) <= 20),
  lead    bigint,
  dur     int not null default 0 check (dur between 0 and 36000),
  note    text not null default '' check (length(note) <= 300)
);
create index if not exists calls_at_idx on public.calls(at desc);
alter table public.calls enable row level security;
drop policy if exists calls_ins on public.calls;
drop policy if exists calls_sel on public.calls;
drop policy if exists calls_del on public.calls;
create policy calls_ins on public.calls for insert to authenticated with check (agent = auth.uid() and public.is_agent());
create policy calls_sel on public.calls for select to authenticated using (public.is_agent());
create policy calls_del on public.calls for delete to authenticated using (public.is_admin());

create table if not exists public.leads (
  id          bigint generated always as identity primary key,
  at          timestamptz not null default now(),
  name        text not null check (length(name) between 1 and 80),
  phone       text not null check (length(phone) between 6 and 20),
  src         text not null default '' check (length(src) <= 40),
  status      text not null default 'new' check (status in ('new','contacted','interested','won','lost')),
  note        text not null default '' check (length(note) <= 300),
  agent       uuid,
  next_at     timestamptz,
  updated_at  timestamptz not null default now()
);
alter table public.leads enable row level security;
drop policy if exists leads_all on public.leads;
create policy leads_all on public.leads for all to authenticated using (public.is_agent()) with check (public.is_agent());
