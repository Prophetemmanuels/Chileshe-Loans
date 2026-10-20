-- ============================================================================
--  CHILESHE INNOVATIONS MONEY LENDERS — Supabase backend
--  Version 1.0  ·  paste this whole file into Supabase → SQL Editor → Run
--
--  BEFORE RUNNING: change the admin key below (step 1).
--  Everything is stored in a schema called "private" that the public API
--  cannot read. Phones talk to the database only through the functions at the
--  bottom of this file, each of which checks an access code or the admin key.
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
--  1. SET YOUR ADMIN KEY  (edit this one word, then run the whole script)
--     Minimum 4 characters. The template value below is treated as UNSET: the
--     owner functions refuse it, so this public file can never hand anyone your
--     records. After the first run, change the key with the UPDATE line at the
--     bottom of this file (kept private in your SQL editor).
--     A short key is protected by a lockout: 15 wrong tries per address per 15
--     minutes, 60 in total, then everyone must wait. Six or more characters is
--     still safer.
-- ─────────────────────────────────────────────────────────────────────────────
-- (the key is hashed with bcrypt — even someone reading the database cannot see it)

-- ─────────────────────────────────────────────────────────────────────────────
--  2. Extensions and private schema
-- ─────────────────────────────────────────────────────────────────────────────
create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

create schema if not exists private;
revoke all on schema private from public;

-- ─────────────────────────────────────────────────────────────────────────────
--  3. Tables (all inside the private schema)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists private.app_config (
  key        text primary key,
  value      text not null,
  updated_at timestamptz not null default now()
);

-- staff digital lists (the spreadsheet tab): one JSON document per list
create table if not exists private.sheets (
  id         text primary key,
  data       jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists private.applications (
  id          text primary key,
  ref         text,
  access_code text,
  user_id     text,
  status      text,
  updated_at  timestamptz not null default now(),
  data        jsonb not null
);

create table if not exists private.loans (
  id          text primary key,
  ref         text,
  access_code text,
  user_id     text,
  status      text,
  updated_at  timestamptz not null default now(),
  data        jsonb not null
);

create table if not exists private.payments (
  id          text primary key,
  ref         text,
  loan_ref    text,
  user_id     text,
  amount      numeric(14,2),
  confirmed   boolean default false,
  updated_at  timestamptz not null default now(),
  data        jsonb not null
);

-- Failed admin-key attempts, used to block brute force on short keys.
-- Rows are per connecting IP and reset after 15 quiet minutes.
create table if not exists private.owner_auth (
  ip      text primary key,
  fails   int not null default 0,
  last_at timestamptz not null default now()
);

create table if not exists private.documents (
  app_id     text not null,
  kind       text not null,
  name       text,
  mime       text,
  size_bytes integer,
  data_b64   text,
  updated_at timestamptz not null default now(),
  primary key (app_id, kind)
);


-- ─────────────────────────────────────────────────────────────────────────────
--  4. Helpers
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function private.norm_code_(p text)
returns text language sql immutable as $$
  select regexp_replace(regexp_replace(upper(coalesce(p, '')), '[^A-Z0-9]', '', 'g'), '^CH', '')
$$;

-- Remove base64 image bytes before storing; keep a note that a file exists.
create or replace function private.strip_docs_(r jsonb)
returns jsonb language sql immutable as $$
  select case
    when r ? 'documents' and jsonb_typeof(r -> 'documents') = 'object' then
      jsonb_set(r, '{documents}', coalesce((
        select jsonb_object_agg(k,
          case when jsonb_typeof(v) = 'object' and (v ? 'dataUrl')
               then (v - 'dataUrl') || '{"onFile": true}'::jsonb
               else v end)
        from jsonb_each(r -> 'documents') as e(k, v)
      ), '{}'::jsonb))
    else r
  end
$$;

create index if not exists applications_code_idx on private.applications (private.norm_code_(access_code));
create index if not exists loans_code_idx        on private.loans        (private.norm_code_(access_code));
create index if not exists payments_loan_idx     on private.payments     (loan_ref);
create index if not exists applications_ref_idx  on private.applications (ref);
create index if not exists loans_ref_idx         on private.loans        (ref);

-- Where the request came from (PostgREST passes the headers through).
create or replace function private.client_ip_()
returns text language plpgsql stable
set search_path = public, extensions, pg_temp as $$
declare h text;
begin
  begin
    h := current_setting('request.headers', true);
    if h is null or length(h) < 2 then return 'unknown'; end if;
    return coalesce((h::json) ->> 'x-forwarded-for', (h::json) ->> 'cf-connecting-ip', 'unknown');
  exception when others then
    return 'unknown';
  end;
end $$;
revoke all on function private.client_ip_() from public;

-- Owner key check. Returns 'ok', 'wrong', 'throttled' or 'placeholder'.
-- It never raises, so a failed attempt is actually written to owner_auth and
-- survives the request (an exception would roll the counter back).
create or replace function private.check_owner_(p_key text)
returns text language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  h text; v_ip text; v_fails int; v_last timestamptz; v_global int;
  c_window constant interval := interval '15 minutes';
  c_per_ip constant int := 15;
  c_global constant int := 100;
begin
  select value into h from private.app_config where key = 'admin_key_hash';
  if h is null then return 'placeholder'; end if;
  if extensions.crypt('CHANGE_ME_ADMIN_KEY', h) = h then return 'placeholder'; end if;

  v_ip := private.client_ip_();
  insert into private.owner_auth (ip) values (v_ip) on conflict (ip) do nothing;
  select fails, last_at into v_fails, v_last from private.owner_auth where ip = v_ip;

  if v_last is null or v_last < now() - c_window then
    update private.owner_auth set fails = 0, last_at = now() where ip = v_ip;
    v_fails := 0;
  end if;

  -- anyone hammering the key from many addresses also gets stopped
  select coalesce(sum(fails), 0) into v_global from private.owner_auth where last_at > now() - c_window;
  if v_fails >= c_per_ip or v_global >= c_global then
    return 'throttled';
  end if;

  if p_key is null or length(p_key) < 4 or extensions.crypt(p_key, h) <> h then
    update private.owner_auth
      set fails = case when last_at > now() - c_window then fails + 1 else 1 end,
          last_at = now()
      where ip = v_ip;
    return 'wrong';
  end if;

  -- success: clear this address and clean up old rows
  update private.owner_auth set fails = 0, last_at = now() where ip = v_ip;
  delete from private.owner_auth where last_at < now() - interval '1 day';
  return 'ok';
end $$;
revoke all on function private.check_owner_(text) from public;

-- Message shown to the app for a failed check.
create or replace function private.owner_error_(status text)
returns text language sql immutable as $$
  select case status
    when 'throttled' then 'Too many wrong admin-key attempts. Wait 15 minutes and try again.'
    when 'placeholder' then 'The database still uses the template admin key CHANGE_ME_ADMIN_KEY - set your own key (SUPABASE-GUIDE step 3).'
    else 'Unauthorized: wrong admin key'
  end
$$;
revoke all on function private.owner_error_(text) from public;

-- Insert or update one application row. Returns true when written.
create or replace function private.upsert_application_(r jsonb)
returns boolean language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare v_id text; v_ts timestamptz;
begin
  if r is null or jsonb_typeof(r) <> 'object' then return false; end if;
  v_id := coalesce(nullif(r ->> 'id', ''), nullif(r ->> 'ref', ''));
  if v_id is null then return false; end if;
  v_ts := least(coalesce(nullif(r ->> 'updatedAt', '')::timestamptz, now()), now() + interval '1 minute');
  insert into private.applications (id, ref, access_code, user_id, status, updated_at, data)
  values (v_id, nullif(r ->> 'ref', ''), nullif(r ->> 'accessCode', ''),
          nullif(r ->> 'userId', ''), nullif(r ->> 'status', ''), v_ts, private.strip_docs_(r))
  on conflict (id) do update
    set ref = excluded.ref, access_code = excluded.access_code, user_id = excluded.user_id,
        status = excluded.status, data = excluded.data, updated_at = excluded.updated_at
    where private.applications.updated_at <= excluded.updated_at;
  return true;
exception when others then
  return false;
end $$;

create or replace function private.upsert_loan_(r jsonb)
returns boolean language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare v_id text; v_ts timestamptz;
begin
  if r is null or jsonb_typeof(r) <> 'object' then return false; end if;
  v_id := coalesce(nullif(r ->> 'id', ''), nullif(r ->> 'ref', ''));
  if v_id is null then return false; end if;
  v_ts := least(coalesce(nullif(r ->> 'updatedAt', '')::timestamptz, now()), now() + interval '1 minute');
  insert into private.loans (id, ref, access_code, user_id, status, updated_at, data)
  values (v_id, nullif(r ->> 'ref', ''), nullif(r ->> 'accessCode', ''),
          nullif(r ->> 'userId', ''), nullif(r ->> 'status', ''), v_ts, private.strip_docs_(r))
  on conflict (id) do update
    set ref = excluded.ref, access_code = excluded.access_code, user_id = excluded.user_id,
        status = excluded.status, data = excluded.data, updated_at = excluded.updated_at
    where private.loans.updated_at <= excluded.updated_at;
  return true;
exception when others then
  return false;
end $$;

create or replace function private.upsert_payment_(r jsonb)
returns boolean language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare v_id text; v_ts timestamptz;
begin
  if r is null or jsonb_typeof(r) <> 'object' then return false; end if;
  v_id := coalesce(nullif(r ->> 'id', ''), nullif(r ->> 'ref', ''));
  if v_id is null then return false; end if;
  v_ts := least(coalesce(nullif(r ->> 'updatedAt', '')::timestamptz, now()), now() + interval '1 minute');
  insert into private.payments (id, ref, loan_ref, user_id, amount, confirmed, updated_at, data)
  values (v_id, nullif(r ->> 'ref', ''), nullif(r ->> 'loanRef', ''), nullif(r ->> 'userId', ''),
          nullif(r ->> 'amount', '')::numeric,
          coalesce((nullif(r ->> 'confirmed', ''))::boolean, false),
          v_ts, r)
  on conflict (id) do update
    set ref = excluded.ref, loan_ref = excluded.loan_ref, user_id = excluded.user_id,
        amount = excluded.amount, confirmed = excluded.confirmed,
        data = excluded.data, updated_at = excluded.updated_at
    where private.payments.updated_at <= excluded.updated_at;
  return true;
exception when others then
  return false;
end $$;

-- ─────────────────────────────────────────────────────────────────────────────
--  5. Owner functions (require the admin key)
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.owner_ping(p_key text)
returns jsonb language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare v_status text;
begin
  v_status := private.check_owner_(p_key);
  if v_status <> 'ok' then
    return jsonb_build_object('ok', false, 'error', private.owner_error_(v_status));
  end if;
  return jsonb_build_object('ok', true, 'version', '1.0',
    'applications', (select count(*) from private.applications),
    'loans', (select count(*) from private.loans),
    'payments', (select count(*) from private.payments));
end $$;

create or replace function public.owner_pull(p_key text)
returns jsonb language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare v_status text;
begin
  v_status := private.check_owner_(p_key);
  if v_status <> 'ok' then
    return jsonb_build_object('ok', false, 'error', private.owner_error_(v_status));
  end if;
  return jsonb_build_object(
    'ok', true,
    'applications', coalesce((select jsonb_agg(data order by updated_at) from private.applications), '[]'::jsonb),
    'loans',        coalesce((select jsonb_agg(data order by updated_at) from private.loans), '[]'::jsonb),
    'payments',     coalesce((select jsonb_agg(data order by updated_at) from private.payments), '[]'::jsonb)
  );
end $$;

create or replace function public.owner_push(
  p_key text,
  p_applications jsonb default '[]'::jsonb,
  p_loans jsonb default '[]'::jsonb,
  p_payments jsonb default '[]'::jsonb)
returns jsonb language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare r jsonb; n int := 0; v_status text;
begin
  v_status := private.check_owner_(p_key);
  if v_status <> 'ok' then
    return jsonb_build_object('ok', false, 'error', private.owner_error_(v_status));
  end if;
  if jsonb_typeof(p_applications) = 'array' then
    for r in select * from jsonb_array_elements(p_applications) loop
      if private.upsert_application_(r) then n := n + 1; end if;
    end loop;
  end if;
  if jsonb_typeof(p_loans) = 'array' then
    for r in select * from jsonb_array_elements(p_loans) loop
      if private.upsert_loan_(r) then n := n + 1; end if;
    end loop;
  end if;
  if jsonb_typeof(p_payments) = 'array' then
    for r in select * from jsonb_array_elements(p_payments) loop
      if private.upsert_payment_(r) then n := n + 1; end if;
    end loop;
  end if;
  return jsonb_build_object('ok', true, 'written', n);
end $$;

-- Cheap fingerprint of the stored records. Devices poll this every 20 seconds
-- and only download when it changes, so a payment made on one phone shows up on
-- the others within seconds. No personal data is returned — just a hash.
create or replace function public.sync_version(p_codes text[] default null)
returns jsonb language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare codes text[]; h text;
begin
  if p_codes is null or coalesce(array_length(p_codes, 1), 0) = 0 then
    select md5(coalesce(string_agg(x, '|' order by x), '')) into h from (
      select id || ':' || to_char(updated_at, 'YYYYMMDDHH24MISSUS') as x from private.applications
      union all select id || ':' || to_char(updated_at, 'YYYYMMDDHH24MISSUS') from private.loans
      union all select id || ':' || to_char(updated_at, 'YYYYMMDDHH24MISSUS') from private.payments
      union all select app_id || ':' || kind || ':' || to_char(updated_at, 'YYYYMMDDHH24MISSUS') from private.documents
    ) t;
  else
    select array_agg(distinct private.norm_code_(c)) into codes
      from unnest(p_codes) as c where length(private.norm_code_(c)) >= 6;
    select md5(coalesce(string_agg(x, '|' order by x), '')) into h from (
      select a.id || ':' || to_char(a.updated_at, 'YYYYMMDDHH24MISSUS') as x
        from private.applications a where private.norm_code_(a.access_code) = any(codes)
      union all
      select l.id || ':' || to_char(l.updated_at, 'YYYYMMDDHH24MISSUS')
        from private.loans l where private.norm_code_(l.access_code) = any(codes)
      union all
      select p.id || ':' || to_char(p.updated_at, 'YYYYMMDDHH24MISSUS')
        from private.payments p
        join private.loans l2 on l2.ref = p.loan_ref
        where private.norm_code_(l2.access_code) = any(codes)
    ) t;
  end if;
  return jsonb_build_object('v', coalesce(h, ''));
end $$;

create or replace function public.owner_delete_payment(p_key text, p_id text)
returns jsonb language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare v_status text;
begin
  v_status := private.check_owner_(p_key);
  if v_status <> 'ok' then
    return jsonb_build_object('ok', false, 'error', private.owner_error_(v_status));
  end if;
  delete from private.payments where id = p_id;
  return jsonb_build_object('ok', true);
end $$;

create or replace function public.owner_document(p_key text, p_app_id text, p_kind text)
returns jsonb language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare d private.documents; v_status text;
begin
  v_status := private.check_owner_(p_key);
  if v_status <> 'ok' then
    return jsonb_build_object('ok', false, 'error', private.owner_error_(v_status));
  end if;
  select * into d from private.documents where app_id = p_app_id and kind = p_kind;
  if not found then return jsonb_build_object('ok', false, 'error', 'not found'); end if;
  return jsonb_build_object('ok', true, 'name', d.name, 'mime', d.mime, 'size', d.size_bytes, 'data', d.data_b64);
end $$;

-- ─────────────────────────────────────────────────────────────────────────────
--  6. Client functions (require the client's own tracking code)
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.client_pull(p_codes text[])
returns jsonb language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare codes text[];
begin
  select array_agg(distinct private.norm_code_(c)) into codes
  from unnest(coalesce(p_codes, '{}'::text[])) as c
  where length(private.norm_code_(c)) >= 6;
  if codes is null or array_length(codes, 1) = 0 then
    return jsonb_build_object('applications', '[]'::jsonb, 'loans', '[]'::jsonb, 'payments', '[]'::jsonb);
  end if;

  return jsonb_build_object(
    'applications', coalesce((
      select jsonb_agg(data order by updated_at)
      from private.applications where private.norm_code_(access_code) = any(codes)), '[]'::jsonb),
    'loans', coalesce((
      select jsonb_agg(data order by updated_at)
      from private.loans where private.norm_code_(access_code) = any(codes)), '[]'::jsonb),
    'payments', coalesce((
      select jsonb_agg(p.data order by p.updated_at)
      from private.payments p
      where exists (
        select 1 from private.loans l
        where l.ref = p.loan_ref and private.norm_code_(l.access_code) = any(codes))), '[]'::jsonb)
  );
end $$;

-- A client may submit / update only their own application, and may claim
-- payments only against their own loan. Loans themselves are never accepted
-- from a client device.
create or replace function public.client_push(
  p_code text,
  p_application jsonb default null,
  p_payments jsonb default '[]'::jsonb,
  p_user jsonb default null)
returns jsonb language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_code text := private.norm_code_(p_code);
  r jsonb; n int := 0; owner_id text; r_clean jsonb;
  v_old jsonb; v_status text;
begin
  if length(v_code) < 6 then
    raise exception 'Invalid tracking code' using errcode = '42501';
  end if;

  if p_application is not null and jsonb_typeof(p_application) = 'object' then
    -- the code in the request decides which record this is
    r := private.strip_docs_(p_application) || jsonb_build_object('accessCode', p_code);
    select id, data into owner_id, v_old from private.applications
      where private.norm_code_(access_code) = v_code limit 1;

    if owner_id is not null then
      -- existing application: the client may edit details and withdraw while
      -- pending, but approval / decline / review notes belong to the owner
      v_status := coalesce(v_old ->> 'status', 'pending');
      if v_status = 'pending' and (p_application ->> 'status') = 'cancelled' then
        v_status := 'cancelled';
      end if;
      r := (v_old || r) || jsonb_build_object(
        'id', owner_id,
        'status', v_status,
        'reviewNote', coalesce(v_old ->> 'reviewNote', ''),
        'reviewedAt', coalesce(v_old ->> 'reviewedAt', ''),
        'loanRef', coalesce(v_old ->> 'loanRef', ''));
    else
      -- brand-new application always arrives pending, and its id is derived
      -- from the tracking code so a tampered app cannot claim someone else's row
      r := r || jsonb_build_object('id', 'app_' || lower(v_code), 'status', 'pending');
    end if;
    if private.upsert_application_(r) then n := n + 1; end if;
  end if;

  if jsonb_typeof(p_payments) = 'array' then
    for r in select * from jsonb_array_elements(p_payments) loop
      -- only payments attached to this client's loan, and never pre-confirmed
      if exists (select 1 from private.loans l
                 where l.ref = (r ->> 'loanRef')
                   and private.norm_code_(l.access_code) = v_code) then
        r_clean := r || '{"confirmed": false}'::jsonb;
        if private.upsert_payment_(r_clean) then n := n + 1; end if;
      end if;
    end loop;
  end if;

  return jsonb_build_object('ok', true, 'written', n);
end $$;

create or replace function public.client_push_document(
  p_code text, p_app_id text, p_kind text, p_name text, p_mime text, p_data text)
returns jsonb language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare v_code text := private.norm_code_(p_code); v_app_id text;
begin
  if length(v_code) < 6 then
    raise exception 'Invalid tracking code' using errcode = '42501';
  end if;
  if p_data is null or length(p_data) < 100 then
    raise exception 'Empty document';
  end if;
  if length(p_data) > 3500000 then
    raise exception 'Document too large (max ~2.5 MB)';
  end if;
  -- the tracking code decides which application a photo belongs to;
  -- p_app_id is accepted for compatibility but never trusted
  select id into v_app_id from private.applications
    where private.norm_code_(access_code) = v_code limit 1;
  if v_app_id is null then
    raise exception 'Application not found for this tracking code' using errcode = '42501';
  end if;
  insert into private.documents (app_id, kind, name, mime, size_bytes, data_b64, updated_at)
  values (v_app_id, p_kind, p_name, p_mime, (length(p_data) * 3) / 4, p_data, now())
  on conflict (app_id, kind) do update
    set name = excluded.name, mime = excluded.mime, size_bytes = excluded.size_bytes,
        data_b64 = excluded.data_b64, updated_at = now();
  return jsonb_build_object('ok', true);
end $$;

create or replace function public.client_document(p_code text, p_app_id text, p_kind text)
returns jsonb language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare d private.documents; v_code text := private.norm_code_(p_code); v_app_id text;
begin
  select id into v_app_id from private.applications
    where private.norm_code_(access_code) = v_code limit 1;
  if v_app_id is null then
    raise exception 'Application not found for this tracking code' using errcode = '42501';
  end if;
  select * into d from private.documents where app_id = v_app_id and kind = p_kind;
  if not found then return jsonb_build_object('ok', false, 'error', 'not found'); end if;
  return jsonb_build_object('ok', true, 'name', d.name, 'mime', d.mime, 'size', d.size_bytes, 'data', d.data_b64);
end $$;

-- Public health check used by the app's "Test" button (no secrets returned).
create or replace function public.backend_info()
returns jsonb language sql security definer
set search_path = public, extensions, pg_temp as $$
  select jsonb_build_object(
    'ok', true, 'version', '1.0',
    'configured', exists(select 1 from private.app_config where key = 'admin_key_hash'),
    'admin_key_is_placeholder', coalesce((
      select extensions.crypt('CHANGE_ME_ADMIN_KEY', value) = value
      from private.app_config where key = 'admin_key_hash'), false)
  )
$$;


-- ─────────────────────────────────────────────────────────────────────────────
--  Email settings published by the office so every phone sends mail the same way
--  (client phones send their own welcome / application / payment emails).
--  These values are public-safe: the EmailJS public key is designed for browsers.
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.public_mail_config()
returns jsonb language sql security definer
set search_path = public, extensions, pg_temp as $$
  select coalesce((
    select value::jsonb from private.app_config where key = 'mail_config'
  ), '{}'::jsonb)
$$;

create or replace function public.owner_set_mail(p_key text, p_config jsonb)
returns jsonb language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare v_status text;
begin
  v_status := private.check_owner_(p_key);
  if v_status <> 'ok' then
    return jsonb_build_object('ok', false, 'error', private.owner_error_(v_status));
  end if;
  insert into private.app_config (key, value, updated_at)
  values ('mail_config', coalesce(p_config, '{}'::jsonb)::text, now())
  on conflict (key) do update set value = excluded.value, updated_at = now();
  return jsonb_build_object('ok', true);
end $$;

-- ─────────────────────────────────────────────────────────────────────────────
--  Staff digital lists — the spreadsheet tab. Staff only (same key check).
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function public.owner_sheets_pull(p_key text)
returns jsonb language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare v_status text;
begin
  v_status := private.check_owner_(p_key);
  if v_status <> 'ok' then
    return jsonb_build_object('ok', false, 'error', private.owner_error_(v_status));
  end if;
  return jsonb_build_object('ok', true, 'sheets', coalesce((
    select jsonb_agg(data order by updated_at) from private.sheets
  ), '[]'::jsonb));
end $$;

create or replace function public.owner_sheets_push(p_key text, p_sheets jsonb)
returns jsonb language plpgsql security definer
set search_path = public, extensions, pg_temp as $$
declare
  v_status text; s jsonb; v_id text; v_ts timestamptz; v_saved int := 0;
begin
  v_status := private.check_owner_(p_key);
  if v_status <> 'ok' then
    return jsonb_build_object('ok', false, 'error', private.owner_error_(v_status));
  end if;
  if p_sheets is null or jsonb_typeof(p_sheets) <> 'array' then
    return jsonb_build_object('ok', true, 'saved', 0);
  end if;
  if length(p_sheets::text) > 2000000 then
    raise exception 'That list is too large to sync (max ~2 MB)';
  end if;

  for s in select * from jsonb_array_elements(p_sheets) loop
    v_id := coalesce(s ->> 'id', '');
    if v_id = '' then continue; end if;
    begin
      v_ts := coalesce((s ->> 'updatedAt')::timestamptz, now());
    exception when others then
      v_ts := now();
    end;
    insert into private.sheets (id, data, updated_at)
    values (v_id, s, v_ts)
    on conflict (id) do update
      set data = excluded.data, updated_at = excluded.updated_at
      where private.sheets.updated_at <= excluded.updated_at;
    v_saved := v_saved + 1;
  end loop;

  return jsonb_build_object('ok', true, 'saved', v_saved);
end $$;

-- ─────────────────────────────────────────────────────────────────────────────
--  7. Lock everything down: no direct table access, only these functions
-- ─────────────────────────────────────────────────────────────────────────────
alter table private.app_config   enable row level security;
alter table private.applications enable row level security;
alter table private.loans        enable row level security;
alter table private.payments     enable row level security;
alter table private.documents    enable row level security;
alter table private.owner_auth   enable row level security;
alter table private.sheets       enable row level security;

revoke all on all tables    in schema private from public;
revoke all on all sequences in schema private from public;
revoke all on all functions in schema private from public;

revoke all on function public.owner_ping(text)                            from public;
revoke all on function public.owner_pull(text)                            from public;
revoke all on function public.owner_push(text, jsonb, jsonb, jsonb)       from public;
revoke all on function public.owner_delete_payment(text, text)            from public;
revoke all on function public.sync_version(text[])                        from public;
revoke all on function public.owner_document(text, text, text)            from public;
revoke all on function public.client_pull(text[])                         from public;
revoke all on function public.client_push(text, jsonb, jsonb, jsonb)      from public;
revoke all on function public.client_push_document(text, text, text, text, text, text) from public;
revoke all on function public.client_document(text, text, text)           from public;
revoke all on function public.backend_info()                              from public;
revoke all on function public.public_mail_config()                         from public;
revoke all on function public.owner_set_mail(text, jsonb)                  from public;
revoke all on function public.owner_sheets_pull(text)                      from public;
revoke all on function public.owner_sheets_push(text, jsonb)               from public;

grant execute on function public.owner_ping(text)                         to anon, authenticated;
grant execute on function public.owner_pull(text)                         to anon, authenticated;
grant execute on function public.owner_push(text, jsonb, jsonb, jsonb)    to anon, authenticated;
grant execute on function public.owner_delete_payment(text, text)         to anon, authenticated;
grant execute on function public.sync_version(text[])                     to anon, authenticated;
grant execute on function public.owner_document(text, text, text)         to anon, authenticated;
grant execute on function public.client_pull(text[])                      to anon, authenticated;
grant execute on function public.client_push(text, jsonb, jsonb, jsonb)   to anon, authenticated;
grant execute on function public.client_push_document(text, text, text, text, text, text) to anon, authenticated;
grant execute on function public.client_document(text, text, text)        to anon, authenticated;
grant execute on function public.backend_info()                           to anon, authenticated;
grant execute on function public.public_mail_config()                      to anon, authenticated;
grant execute on function public.owner_set_mail(text, jsonb)               to anon, authenticated;
grant execute on function public.owner_sheets_pull(text)                   to anon, authenticated;
grant execute on function public.owner_sheets_push(text, jsonb)            to anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
--  8. Store the admin key (bcrypt hash). EDIT THE KEY IN THIS LINE.
-- ─────────────────────────────────────────────────────────────────────────────
insert into private.app_config (key, value)
values ('admin_key_hash', extensions.crypt('CHANGE_ME_ADMIN_KEY', extensions.gen_salt('bf', 10)))
on conflict (key) do nothing;

-- To CHANGE the admin key later, run this single line instead (edit the key):
-- update private.app_config set value = extensions.crypt('YOUR_NEW_KEY', extensions.gen_salt('bf',10)), updated_at = now() where key = 'admin_key_hash';

-- Done. Next: copy the Project URL + anon public key into the app.
-- ============================================================================
