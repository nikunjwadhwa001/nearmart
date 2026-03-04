# NearMart — Supabase Backend

## Structure
migrations/   SQL files that define the database schema, run in order
seed/         Initial data inserted after migrations (categories, products, brands)

## How to apply
1. Go to Supabase Dashboard → SQL Editor
2. Run each migration file in numerical order
3. Then run seed files

## Naming convention
001_create_users.sql
002_create_addresses.sql
003_create_shops.sql
...and so on