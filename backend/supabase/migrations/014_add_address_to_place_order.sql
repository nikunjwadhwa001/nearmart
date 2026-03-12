-- Migration 014: Add delivery_address_id to place_order function
-- The original function (013) omitted delivery_address_id.

create or replace function public.place_order(
  p_shop_id uuid,
  p_items jsonb,
  p_delivery_address_id uuid default null,
  p_notes text default null
)
returns uuid
language plpgsql
security definer set search_path = public
as $$
declare
  v_order_id uuid;
  v_customer_id uuid;
  v_subtotal decimal(10,2);
  v_commission_rate decimal(5,2);
  v_commission_amount decimal(10,2);
  v_total_amount decimal(10,2);
  v_item jsonb;
begin
  -- Get the authenticated user
  v_customer_id := auth.uid();
  if v_customer_id is null then
    raise exception 'Not authenticated';
  end if;

  -- Validate shop exists and is approved
  if not exists (
    select 1 from public.shops
    where id = p_shop_id and status = 'approved'
  ) then
    raise exception 'Shop not found or not approved';
  end if;

  -- Validate items array is not empty
  if jsonb_array_length(p_items) = 0 then
    raise exception 'Order must have at least one item';
  end if;

  -- Validate delivery address belongs to the customer (if provided)
  if p_delivery_address_id is not null then
    if not exists (
      select 1 from public.addresses
      where id = p_delivery_address_id and user_id = v_customer_id
    ) then
      raise exception 'Invalid delivery address';
    end if;
  end if;

  -- Calculate subtotal from items
  v_subtotal := 0;
  for v_item in select * from jsonb_array_elements(p_items)
  loop
    v_subtotal := v_subtotal + (
      (v_item->>'unit_price')::decimal * (v_item->>'quantity')::int
    );
  end loop;

  -- Get commission rate from platform config
  select value::decimal into v_commission_rate
  from public.platform_config
  where key = 'commission_rate';

  if v_commission_rate is null then
    v_commission_rate := 5.00;
  end if;

  v_commission_amount := round(v_subtotal * v_commission_rate / 100, 2);
  v_total_amount := v_subtotal;

  -- Create the order
  insert into public.orders (
    customer_id, shop_id, delivery_address_id, subtotal, commission_rate,
    commission_amount, total_amount, notes, status
  ) values (
    v_customer_id, p_shop_id, p_delivery_address_id, v_subtotal, v_commission_rate,
    v_commission_amount, v_total_amount, p_notes, 'placed'
  )
  returning id into v_order_id;

  -- Create order items — look up shop_inventory.id from (shop_id, variant_id)
  insert into public.order_items (
    order_id, inventory_id, product_name, brand_name,
    variant_name, quantity, unit_price, total_price
  )
  select
    v_order_id,
    si.id,
    item->>'product_name',
    item->>'brand_name',
    item->>'variant_name',
    (item->>'quantity')::int,
    (item->>'unit_price')::decimal,
    (item->>'unit_price')::decimal * (item->>'quantity')::int
  from jsonb_array_elements(p_items) as item
  left join public.shop_inventory si
    on si.shop_id = p_shop_id
    and si.variant_id = (item->>'variant_id')::uuid;

  -- Create commission ledger entry
  insert into public.commission_ledger (
    order_id, shop_id, amount, status
  ) values (
    v_order_id, p_shop_id, v_commission_amount, 'pending'
  );

  return v_order_id;
end;
$$;
