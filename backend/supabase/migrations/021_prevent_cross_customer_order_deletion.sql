-- Migration 021: Prevent cross-customer order deletion during account removal.
--
-- Problem:
-- - shops.owner_id CASCADE + orders.shop_id CASCADE allows deleting a shop-owner
--   user to delete the shop, which then deletes all orders at that shop (including
--   other customers' orders).
--
-- Desired behavior:
-- - Only orders belonging to the customer deleting their account should be removed
--   (via orders.customer_id ON DELETE CASCADE from migration 011).
-- - Deleting a shop owner must not cascade through shop -> orders.

-- Revert orders.shop_id to RESTRICT so shop deletion cannot wipe unrelated orders.
alter table public.orders
  drop constraint if exists orders_shop_id_fkey;

alter table public.orders
  add constraint orders_shop_id_fkey
  foreign key (shop_id)
  references public.shops(id)
  on delete restrict;

-- Revert shops.owner_id to RESTRICT so deleting a user doesn't auto-delete shops.
alter table public.shops
  drop constraint if exists shops_owner_id_fkey;

alter table public.shops
  add constraint shops_owner_id_fkey
  foreign key (owner_id)
  references public.users(id)
  on delete restrict;
