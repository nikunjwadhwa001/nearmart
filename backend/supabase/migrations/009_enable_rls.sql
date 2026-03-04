-- Migration 009: Enable Row Level Security on all tables
-- RLS must be enabled per table, then policies define who can access what

-- =========================================
-- STEP 1: Enable RLS on every table
-- =========================================

alter table public.users enable row level security;
alter table public.addresses enable row level security;
alter table public.shops enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.brands enable row level security;
alter table public.product_variants enable row level security;
alter table public.shop_inventory enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.commission_ledger enable row level security;
alter table public.platform_config enable row level security;
alter table public.notifications enable row level security;

-- =========================================
-- STEP 2: USERS table policies
-- =========================================

-- Users can read their own profile only
create policy "users_select_own"
on public.users for select
using (auth.uid() = id);

-- Users can update their own profile only
create policy "users_update_own"
on public.users for update
using (auth.uid() = id);

-- New users can insert their own record (happens on signup)
create policy "users_insert_own"
on public.users for insert
with check (auth.uid() = id);

-- =========================================
-- STEP 3: ADDRESSES table policies
-- =========================================

-- Users can only see their own addresses
create policy "addresses_select_own"
on public.addresses for select
using (auth.uid() = user_id);

-- Users can add their own addresses
create policy "addresses_insert_own"
on public.addresses for insert
with check (auth.uid() = user_id);

-- Users can update their own addresses
create policy "addresses_update_own"
on public.addresses for update
using (auth.uid() = user_id);

-- Users can delete their own addresses
create policy "addresses_delete_own"
on public.addresses for delete
using (auth.uid() = user_id);

-- =========================================
-- STEP 4: SHOPS table policies
-- =========================================

-- Anyone logged in can view approved shops (customers browse shops)
create policy "shops_select_approved"
on public.shops for select
using (status = 'approved' or auth.uid() = owner_id);

-- Only owners can create a shop for themselves
create policy "shops_insert_own"
on public.shops for insert
with check (auth.uid() = owner_id);

-- Only the shop owner can update their shop
create policy "shops_update_own"
on public.shops for update
using (auth.uid() = owner_id);

-- =========================================
-- STEP 5: CATALOG tables policies
-- =========================================
-- Product catalog is PUBLIC — anyone can read it
-- Only admin can modify it (handled via service role in admin dashboard)

create policy "categories_select_public"
on public.categories for select
using (is_active = true);

create policy "products_select_public"
on public.products for select
using (is_active = true);

create policy "brands_select_public"
on public.brands for select
using (is_active = true);

create policy "variants_select_public"
on public.product_variants for select
using (is_active = true);

-- =========================================
-- STEP 6: SHOP INVENTORY policies
-- =========================================

-- Customers can see in-stock inventory of approved shops
create policy "inventory_select_public"
on public.shop_inventory for select
using (
  exists (
    select 1 from public.shops
    where shops.id = shop_inventory.shop_id
    and shops.status = 'approved'
  )
);

-- Shop owners can only manage their own shop's inventory
create policy "inventory_insert_own"
on public.shop_inventory for insert
with check (
  exists (
    select 1 from public.shops
    where shops.id = shop_inventory.shop_id
    and shops.owner_id = auth.uid()
  )
);

create policy "inventory_update_own"
on public.shop_inventory for update
using (
  exists (
    select 1 from public.shops
    where shops.id = shop_inventory.shop_id
    and shops.owner_id = auth.uid()
  )
);

create policy "inventory_delete_own"
on public.shop_inventory for delete
using (
  exists (
    select 1 from public.shops
    where shops.id = shop_inventory.shop_id
    and shops.owner_id = auth.uid()
  )
);

-- =========================================
-- STEP 7: ORDERS policies
-- =========================================

-- Customers see their own orders
-- Shop owners see orders placed at their shop
create policy "orders_select_own"
on public.orders for select
using (
  auth.uid() = customer_id
  or
  exists (
    select 1 from public.shops
    where shops.id = orders.shop_id
    and shops.owner_id = auth.uid()
  )
);

-- Only customers can place orders
create policy "orders_insert_customer"
on public.orders for insert
with check (auth.uid() = customer_id);

-- Only shop owners can update order status
create policy "orders_update_shop_owner"
on public.orders for update
using (
  exists (
    select 1 from public.shops
    where shops.id = orders.shop_id
    and shops.owner_id = auth.uid()
  )
);

-- =========================================
-- STEP 8: ORDER ITEMS policies
-- =========================================

-- Visible to the customer who placed the order
-- and the shop owner who received it
create policy "order_items_select_own"
on public.order_items for select
using (
  exists (
    select 1 from public.orders
    where orders.id = order_items.order_id
    and (
      orders.customer_id = auth.uid()
      or exists (
        select 1 from public.shops
        where shops.id = orders.shop_id
        and shops.owner_id = auth.uid()
      )
    )
  )
);

-- Items are inserted when order is created
create policy "order_items_insert_own"
on public.order_items for insert
with check (
  exists (
    select 1 from public.orders
    where orders.id = order_items.order_id
    and orders.customer_id = auth.uid()
  )
);

-- =========================================
-- STEP 9: NOTIFICATIONS policies
-- =========================================

-- Users only see their own notifications
create policy "notifications_select_own"
on public.notifications for select
using (auth.uid() = user_id);

-- Mark as read
create policy "notifications_update_own"
on public.notifications for update
using (auth.uid() = user_id);

-- =========================================
-- STEP 10: COMMISSION LEDGER policies
-- =========================================

-- Shop owners can see their own commission records
create policy "commission_select_own"
on public.commission_ledger for select
using (
  exists (
    select 1 from public.shops
    where shops.id = commission_ledger.shop_id
    and shops.owner_id = auth.uid()
  )
);

-- =========================================
-- STEP 11: PLATFORM CONFIG policies
-- =========================================

-- Anyone authenticated can read config (app needs commission_rate)
create policy "config_select_authenticated"
on public.platform_config for select
using (auth.role() = 'authenticated');