-- Migration 002: Addresses
-- Used for customer delivery addresses and shop locations

create table public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  label varchar(50) default 'Home',
  address_line text not null,
  city varchar(100),
  pincode varchar(10),
  latitude decimal(10,8),
  longitude decimal(11,8),
  is_default boolean default false
);

create index idx_addresses_user_id on public.addresses(user_id);