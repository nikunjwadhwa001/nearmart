-- Migration 018: Add a second approved test shop near Chandigarh
-- Used to test multi-shop cart flows and nearby shop discovery.

do $$
declare
  v_owner_id uuid := '91000000-0000-0000-0000-000000000001';
  v_address_id uuid := '91000000-0000-0000-0000-000000000002';
  v_shop_id uuid := '91000000-0000-0000-0000-000000000003';
begin
  if not exists (
    select 1 from public.users where id = v_owner_id
  ) then
    insert into public.users (
      id,
      full_name,
      phone,
      email,
      role,
      is_active
    ) values (
      v_owner_id,
      'Sector 22 Test Owner',
      '9876500018',
      'owner+sector22-test@nearmart.dev',
      'owner',
      true
    );
  end if;

  if not exists (
    select 1 from public.addresses where id = v_address_id
  ) then
    insert into public.addresses (
      id,
      user_id,
      label,
      address_line,
      city,
      pincode,
      latitude,
      longitude,
      is_default
    ) values (
      v_address_id,
      v_owner_id,
      'Shop',
      'Booth 14, Sector 22 Market',
      'Chandigarh',
      '160022',
      30.73420000,
      76.78110000,
      true
    );
  end if;

  if not exists (
    select 1 from public.shops where id = v_shop_id
  ) then
    insert into public.shops (
      id,
      owner_id,
      name,
      description,
      phone,
      address_id,
      latitude,
      longitude,
      status,
      is_open,
      approved_at
    ) values (
      v_shop_id,
      v_owner_id,
      'Sector 22 Fresh Mart',
      'Daily essentials, dairy, bakery, and staples for quick testing.',
      '9876500018',
      v_address_id,
      30.73420000,
      76.78110000,
      'approved',
      true,
      now()
    );
  end if;

  insert into public.shop_inventory (shop_id, variant_id, price, stock_status)
  values
    (v_shop_id, 'a0000001-0000-0000-0000-000000000000', 31.00, 'in_stock'),
    (v_shop_id, 'a0000003-0000-0000-0000-000000000000', 33.00, 'in_stock'),
    (v_shop_id, 'a0000005-0000-0000-0000-000000000000', 24.00, 'in_stock'),
    (v_shop_id, 'a0000007-0000-0000-0000-000000000000', 23.00, 'in_stock'),
    (v_shop_id, 'a0000044-0000-0000-0000-000000000000', 42.00, 'in_stock'),
    (v_shop_id, 'a0000026-0000-0000-0000-000000000000', 48.00, 'in_stock')
  on conflict (shop_id, variant_id) do update
  set
    price = excluded.price,
    stock_status = excluded.stock_status,
    updated_at = now();
end $$;