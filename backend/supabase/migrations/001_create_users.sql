-- Migration 001: Create users table
-- Single table for all user types. Role field controls app routing after login.

create table public.users (
  id uuid primary key default gen_random_uuid(),
  full_name varchar(100) not null,
  phone varchar(15) unique not null,
  email varchar(100) unique,
  role varchar(20) not null check (role in ('customer', 'owner', 'admin')),
  is_active boolean default true,
  created_at timestamp with time zone default now()
);

create index idx_users_phone on public.users(phone);
create index idx_users_role on public.users(role);