-- Migration 008: Notifications

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  title varchar(200) not null,
  body text,
  type varchar(50) check (
    type in ('new_order', 'order_update', 'shop_approved', 'shop_suspended')
  ),
  is_read boolean default false,
  created_at timestamp with time zone default now()
);

create index idx_notifications_user on public.notifications(user_id);
create index idx_notifications_read on public.notifications(is_read);