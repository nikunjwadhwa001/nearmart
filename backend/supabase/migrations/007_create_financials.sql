-- Migration 007: Commission ledger and platform config

create table public.commission_ledger (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete restrict,
  shop_id uuid not null references public.shops(id) on delete restrict,
  amount decimal(10,2) not null,
  status varchar(20) default 'pending' check (status in ('pending', 'settled')),
  settled_at timestamp with time zone
);

create table public.platform_config (
  key varchar(100) primary key,
  value text not null,
  updated_at timestamp with time zone default now()
);

-- Default commission rate of 10%
insert into public.platform_config (key, value)
values ('commission_rate', '5.00');

create index idx_commission_shop on public.commission_ledger(shop_id);
create index idx_commission_status on public.commission_ledger(status);