-- Migration 011: Fix delete account constraints
-- Changes ON DELETE RESTRICT to CASCADE for user deletion
-- This allows users to delete their accounts even if they have orders or own shops

-- =========================================
-- Drop existing constraints and recreate with CASCADE
-- =========================================

-- Fix orders.customer_id constraint
alter table public.orders 
  drop constraint orders_customer_id_fkey;

alter table public.orders
  add constraint orders_customer_id_fkey 
  foreign key (customer_id) 
  references public.users(id) 
  on delete cascade;

-- Fix shops.owner_id constraint  
alter table public.shops
  drop constraint shops_owner_id_fkey;

alter table public.shops
  add constraint shops_owner_id_fkey
  foreign key (owner_id)
  references public.users(id)
  on delete cascade;

-- Note: When a user is deleted:
-- → All their orders will be deleted (business decision: order history removed)
-- → All shops they own will be deleted (along with inventory via existing cascade)
-- → Addresses already cascade (already correct in migration 002)
-- → Notifications already cascade (already correct in migration 008)
