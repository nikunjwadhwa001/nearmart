# Architecture Overview

## System Components

### 1. Mobile App (Flutter) — Customers ONLY
- Used exclusively by customers
- Browse nearby shops, cart, checkout, order tracking
- Communicates with Supabase via Flutter SDK

### 2. Web Dashboard (React) — Shop Owners + Admin
- Shop owners manage inventory and incoming orders
- Admin manages the entire platform
- Single React app with role-based views
- Owner role → sees only their shop data
- Admin role → sees everything
- Deployed on Vercel

### 3. Backend (Supabase)
- PostgreSQL database
- Built-in Auth (email OTP for dev, phone OTP for prod)
- Realtime subscriptions (live order notifications)
- Row Level Security (data access enforced at DB level)
- Auto-generated REST API from schema

## Data Flow

### Customer ordering:
Customer opens Flutter app → browses nearby shops →
adds to cart → places order → Supabase records it →
Realtime event fires → Shop owner's web dashboard
receives notification → Owner updates status →
Customer sees live update in app

### Shop owner managing:
Owner logs into React dashboard → manages inventory
from catalog → views incoming orders → updates
order status → commission recorded automatically

## Key Design Decisions
- Flutter app is customer-only — simpler, faster to build
- React dashboard shared by owners and admin — role-based routing
- No custom delivery logic — shop handles their own delivery
- Centralized product catalog — shop owners pick from existing products
- Commission calculated at 5% on order completion
- Commission rate stored in platform_config — changeable without redeployment