-- Migration 012: Remove auth trigger — user creation now handled by app
--
-- PROBLEM: The old trigger created a public.users row on every signInWithOtp
-- call — even before email verification. Typos created ghost users.
--
-- FIX: Drop the trigger entirely. The app creates the public.users row
-- in _ensureUserInDatabase() only AFTER successful OTP verification.
-- This is cleaner — keeps user creation logic in the application layer
-- and uses the database purely for storage.

-- Step 1: Drop the triggers
drop trigger if exists on_auth_user_created on auth.users;
drop trigger if exists on_auth_user_verified on auth.users;

-- Step 2: Drop the trigger function
drop function if exists public.handle_new_user();

-- Step 3: Clean up existing ghost users
-- Ghost users = exist in public.users but their auth.users email was never confirmed
delete from public.users
where id in (
  select p.id
  from public.users p
  join auth.users a on a.id = p.id
  where a.email_confirmed_at is null
);
