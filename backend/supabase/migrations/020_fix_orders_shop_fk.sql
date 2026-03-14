-- Migration 020: Allow shop deletion to cascade through orders.
-- orders.shop_id currently uses ON DELETE RESTRICT which blocks account deletion
-- for shop owners when other customers have placed orders at their shop.
-- Changing to CASCADE so that when a shop is deleted (e.g. owner deletes account),
-- all orders at that shop are also removed.

alter table public.orders
  drop constraint orders_shop_id_fkey;

alter table public.orders
  add constraint orders_shop_id_fkey
  foreign key (shop_id)
  references public.shops(id)
  on delete cascade;
