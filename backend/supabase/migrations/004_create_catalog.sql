-- Migration 004: Product catalog
-- Managed by admin. Shop owners select from this catalog.

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  name varchar(100) not null,
  icon_url text,
  display_order int default 0,
  is_active boolean default true
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.categories(id) on delete restrict,
  name varchar(150) not null,
  description text,
  image_url text,
  unit varchar(50),
  is_active boolean default true
);

create table public.brands (
  id uuid primary key default gen_random_uuid(),
  name varchar(100) not null,
  logo_url text,
  is_active boolean default true
);

create table public.product_variants (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  brand_id uuid not null references public.brands(id) on delete restrict,
  variant_name varchar(100),
  image_url text,
  is_active boolean default true
);

create index idx_products_category on public.products(category_id);
create index idx_variants_product on public.product_variants(product_id);
create index idx_variants_brand on public.product_variants(brand_id);