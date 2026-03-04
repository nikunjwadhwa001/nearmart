# Architecture Overview

## System Components

### 1. Mobile App (Flutter)
- Used by both Customers and Shop Owners
- Role-based UI — same login, different interface based on account type
- Communicates with Supabase directly via Supabase Flutter SDK

### 2. Backend (Supabase)
- PostgreSQL database
- Built-in Auth (phone OTP)
- Realtime subscriptions (for live order notifications)
- Row Level Security (shop owners only see their own data)
- Auto-generated REST API from schema

### 3. Admin Dashboard (React)
- Web-only, not mobile
- Talks to Supabase via service role key (bypasses RLS)
- Deployed on Vercel

## Data Flow
Customer places order → Supabase records it → Realtime event fires → 
Shop owner app receives notification → Owner updates status → 
Customer sees live status update

## Key Design Decisions
- No custom delivery logic — shop handles their own delivery
- Centralized product catalog — shop owners pick from existing products
- Commission calculated server-side on order completion