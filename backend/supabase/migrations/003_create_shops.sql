-- Migration 003: Shops
-- Each shop belongs to one owner. Status controls visibility to customers.

create table public.shops (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.users(id) on delete restrict,
  name varchar(150) not null,
  description text,
  phone varchar(15),
  address_id uuid references public.addresses(id) on delete set null,
  latitude decimal(10,8) not null,
  longitude decimal(11,8) not null,
  status varchar(20) default 'pending' check (status in ('pending', 'approved', 'suspended')),
  logo_url text,
  is_open boolean default true,
  created_at timestamp with time zone default now(),
  approved_at timestamp with time zone
);

create index idx_shops_location on public.shops(latitude, longitude);
create index idx_shops_status on public.shops(status);
create index idx_shops_owner_id on public.shops(owner_id);