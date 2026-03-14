-- Migration 019: Ensure account deletion can cascade through financial rows.
-- commission_ledger currently blocks order/shop deletion with RESTRICT.

alter table public.commission_ledger
  drop constraint if exists commission_ledger_order_id_fkey;

alter table public.commission_ledger
  add constraint commission_ledger_order_id_fkey
  foreign key (order_id)
  references public.orders(id)
  on delete cascade;

alter table public.commission_ledger
  drop constraint if exists commission_ledger_shop_id_fkey;

alter table public.commission_ledger
  add constraint commission_ledger_shop_id_fkey
  foreign key (shop_id)
  references public.shops(id)
  on delete cascade;
