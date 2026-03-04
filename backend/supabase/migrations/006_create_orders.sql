-- Migration 006: Orders and order items
-- order_items snapshots product details at time of purchase

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.users(id) on delete restrict,
  shop_id uuid not null references public.shops(id) on delete restrict,
  delivery_address_id uuid references public.addresses(id) on delete set null,
  status varchar(30) default 'placed' check (
    status in ('placed', 'confirmed', 'preparing', 'out_for_delivery', 'delivered', 'cancelled')
  ),
  subtotal decimal(10,2) not null,
  commission_rate decimal(5,2) not null,
  commission_amount decimal(10,2) not null,
  total_amount decimal(10,2) not null,
  notes text,
  placed_at timestamp with time zone default now(),
  confirmed_at timestamp with time zone,
  delivered_at timestamp with time zone,
  cancelled_at timestamp with time zone,
  cancellation_reason text
);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  inventory_id uuid references public.shop_inventory(id) on delete set null,
  product_name varchar(150) not null,
  brand_name varchar(100) not null,
  variant_name varchar(100),
  quantity int not null check (quantity > 0),
  unit_price decimal(10,2) not null,
  total_price decimal(10,2) not null
);

create index idx_orders_customer on public.orders(customer_id);
create index idx_orders_shop on public.orders(shop_id);
create index idx_orders_status on public.orders(status);
create index idx_order_items_order on public.order_items(order_id);