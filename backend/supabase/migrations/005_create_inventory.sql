-- Migration 005: Shop inventory
-- Bridge between shops and catalog. One row = one shop selling one variant.

create table public.shop_inventory (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  variant_id uuid not null references public.product_variants(id) on delete restrict,
  price decimal(10,2) not null check (price > 0),
  stock_status varchar(20) default 'in_stock' check (stock_status in ('in_stock', 'out_of_stock')),
  updated_at timestamp with time zone default now(),
  unique(shop_id, variant_id)
);

create index idx_inventory_shop on public.shop_inventory(shop_id);
create index idx_inventory_variant on public.shop_inventory(variant_id);
create index idx_inventory_stock on public.shop_inventory(stock_status);