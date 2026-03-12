-- Migration 016: Search products across nearby shops
-- Returns matching variants with shop info, using ILIKE for case-insensitive search

create or replace function public.search_products(
  query_text text,
  lat decimal,
  lng decimal,
  radius_km decimal default 5.0
)
returns table (
  shop_id uuid,
  shop_name varchar,
  product_id uuid,
  product_name varchar,
  category_name varchar,
  brand_name varchar,
  variant_id uuid,
  variant_name varchar,
  price decimal,
  unit varchar,
  stock_status varchar,
  image_url text,
  distance_km decimal
)
language sql
stable
as $$
  select
    s.id as shop_id,
    s.name as shop_name,
    p.id as product_id,
    p.name as product_name,
    c.name as category_name,
    b.name as brand_name,
    pv.id as variant_id,
    pv.variant_name,
    si.price,
    p.unit,
    si.stock_status,
    coalesce(pv.image_url, p.image_url) as image_url,
    round(
      (6371 * acos(
        cos(radians(lat)) * cos(radians(s.latitude))
        * cos(radians(s.longitude) - radians(lng))
        + sin(radians(lat)) * sin(radians(s.latitude))
      ))::decimal, 1
    ) as distance_km
  from public.shop_inventory si
  join public.product_variants pv on pv.id = si.variant_id
  join public.products p on p.id = pv.product_id
  join public.brands b on b.id = pv.brand_id
  join public.categories c on c.id = p.category_id
  join public.shops s on s.id = si.shop_id
  where s.status = 'approved'
    and s.is_open = true
    and si.stock_status = 'in_stock'
    and (
      p.name ilike '%' || query_text || '%'
      or pv.variant_name ilike '%' || query_text || '%'
      or b.name ilike '%' || query_text || '%'
      or c.name ilike '%' || query_text || '%'
    )
    and (6371 * acos(
      cos(radians(lat)) * cos(radians(s.latitude))
      * cos(radians(s.longitude) - radians(lng))
      + sin(radians(lat)) * sin(radians(s.latitude))
    )) <= radius_km
  order by distance_km, p.name, si.price;
$$;
