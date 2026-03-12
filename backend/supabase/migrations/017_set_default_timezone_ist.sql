-- Migration 017: Set default timezone to Asia/Kolkata for database and API roles
--
-- Why:
-- - timestamptz stores absolute time internally (UTC-based instant)
-- - timezone controls how values are rendered on read
-- - setting default timezone to Asia/Kolkata makes API reads come back in IST

alter database postgres set timezone to 'Asia/Kolkata';

-- Supabase API requests run through these roles.
-- Set role-level timezone so sessions inherit IST consistently.
do $$
begin
  if exists (select 1 from pg_roles where rolname = 'anon') then
    execute 'alter role anon set timezone to ''Asia/Kolkata''';
  end if;

  if exists (select 1 from pg_roles where rolname = 'authenticated') then
    execute 'alter role authenticated set timezone to ''Asia/Kolkata''';
  end if;

  if exists (select 1 from pg_roles where rolname = 'service_role') then
    execute 'alter role service_role set timezone to ''Asia/Kolkata''';
  end if;

  if exists (select 1 from pg_roles where rolname = 'authenticator') then
    execute 'alter role authenticator set timezone to ''Asia/Kolkata''';
  end if;
end
$$;