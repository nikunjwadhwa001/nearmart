# NearMart 🛒

> Hyperlocal grocery marketplace connecting local kirana shops with nearby customers.

![Status](https://img.shields.io/badge/Status-In%20Development-orange)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-green)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

---

## What is NearMart?

NearMart helps customers discover and order from grocery shops within 5km of
their location. Shop owners get a mobile app to manage orders and inventory.
No big logistics company in the middle — just your local kirana shop, online.

**The problem it solves:**
Local kirana shops lose customers to Blinkit and Zepto not because they're
worse — but because they're invisible online. NearMart gives them a digital
storefront without any technical knowledge required.

---

## How it works

**For customers:**
1. Open app → see nearby approved shops
2. Browse shop's product catalog
3. Add items to cart
4. Place order → shop gets notified instantly
5. Track order status in real time

**For shop owners:**
1. Register shop → admin approves
2. Add products from master catalog with their own prices
3. Receive incoming orders on their phone
4. Accept → prepare → mark as delivered
5. Pay 5% commission monthly or ₹499 flat subscription

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile App | Flutter (Dart) |
| State Management | Riverpod |
| Navigation | GoRouter |
| Backend | Supabase (PostgreSQL + Auth + Realtime) |
| Admin Dashboard | React + Vite + Tailwind CSS |
| Deployment | Vercel + Supabase |

---

## Architecture
```
Single Flutter app — role-based UI
├── Customer  → browse shops, cart, orders, profile
└── Shop Owner → incoming orders, inventory, earnings

React Web Dashboard — super admin only
└── Admin → approvals, catalog, settlements, config

Backend — Supabase
├── PostgreSQL — 12 tables, full relational schema
├── Auth — email OTP (dev), phone OTP (prod)
├── Realtime — live order status updates
└── RLS — row level security on all tables
```

---

## Billing Models

NearMart offers shop owners two choices:

**Commission Model** — Pay per performance
- 5% of total monthly sales through NearMart
- Settled on 1st of every month
- No upfront cost — ideal for new shops

**Subscription Model** — Flat monthly fee
- ₹499/month regardless of order volume
- Keep 100% of every order
- Break-even at ₹9,980/month in NearMart orders
- Ideal for established high-volume shops

Customers always pay exactly what they see — no hidden platform fees.

---

## Database Schema

| Table | Purpose |
|---|---|
| users | All roles — customer, owner, admin |
| addresses | Customer and shop addresses |
| shops | Shop listings with GPS + billing model |
| categories | Product categories |
| products | Master product catalog |
| brands | Brand information |
| product_variants | Specific variants with size/weight |
| shop_inventory | Products per shop with shop-specific pricing |
| orders | Customer orders |
| order_items | Order items with price snapshots |
| commission_ledger | Monthly commission tracking |
| platform_config | Platform settings |
| notifications | Per-user notification feed |

---

## Project Structure
```
nearmart/
├── mobile/                 ← Flutter app
│   └── lib/
│       ├── core/           ← Theme, router, Supabase client
│       ├── models/         ← Data models
│       └── features/
│           ├── auth/       ← Login, OTP
│           ├── home/       ← Customer home, shop discovery
│           ├── shop/       ← Shop detail, product catalog
│           ├── cart/       ← Cart management
│           ├── orders/     ← Order tracking
│           ├── profile/    ← Customer profile
│           └── owner/      ← All shop owner screens
├── admin-dashboard/        ← React admin dashboard
├── backend/
│   └── supabase/
│       ├── migrations/     ← Database migrations
│       └── seed/           ← Seed data
└── docs/
    ├── ARCHITECTURE.md     ← Full architecture overview
    └── schema.sql          ← Database schema
```

---

## Build Progress

### Customer App
| Feature | Status |
|---|---|
| Splash screen | ✅ Done |
| Email OTP login | ✅ Done |
| Nearby shops discovery | ✅ Done |
| Shop detail + product catalog | ✅ Done |
| Add to cart with variant selection | ✅ Done |
| Cart management | ✅ Done |
| Place order | 🔄 In progress |
| Order tracking | ⏳ Pending |
| Profile + logout + delete account | ✅ Done |

### Shop Owner App
| Feature | Status |
|---|---|
| Owner home — today's orders | ⏳ Pending |
| Incoming order notifications | ⏳ Pending |
| Order management | ⏳ Pending |
| Inventory management | ⏳ Pending |
| Earnings dashboard | ⏳ Pending |

### Admin Dashboard
| Feature | Status |
|---|---|
| Shop approvals | ⏳ Pending |
| Catalog management | ⏳ Pending |
| Commission settlements | ⏳ Pending |
| Platform configuration | ⏳ Pending |

---

## Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Supabase account
- Node.js 18+ (for admin dashboard)

### Mobile App Setup
```bash
# Clone the repo
git clone https://github.com/nikunjwadhwa001/nearmart.git
cd nearmart/mobile

# Install dependencies
flutter pub get

# Create environment file
cp .env.example .env
# Add your Supabase URL and anon key to .env

# Run the app
flutter run
```

### Environment Variables
```bash
# mobile/.env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### Database Setup
```bash
# Run migrations in order in Supabase SQL Editor
backend/supabase/migrations/001_create_users.sql
backend/supabase/migrations/002_create_addresses.sql
backend/supabase/migrations/003_create_shops.sql
backend/supabase/migrations/004_create_catalog.sql
backend/supabase/migrations/005_create_inventory.sql
backend/supabase/migrations/006_create_orders.sql
backend/supabase/migrations/007_create_financials.sql
backend/supabase/migrations/008_create_notifications.sql
backend/supabase/migrations/009_enable_rls.sql
backend/supabase/migrations/010_auth_trigger.sql

# Run seed data
backend/supabase/seed/001_seed_catalog.sql
backend/supabase/seed/002_seed_brands.sql
backend/supabase/seed/003_seed_products.sql
backend/supabase/seed/004_seed_variants.sql
```

---

## About the Developer

**Nikunj Wadhwa**
Final year B.E. Electronics and Communication Engineering
Thapar Institute of Engineering and Technology, Patiala

Currently interning at SprintVisa as a Software Development Intern,
architecting a B2B visa agent portal.

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0077B5?style=flat&logo=linkedin)](https://linkedin.com/in/nikunjwadhwa)
[![GitHub](https://img.shields.io/badge/GitHub-nikunjwadhwa001-181717?style=flat&logo=github)](https://github.com/nikunjwadhwa001)
[![Email](https://img.shields.io/badge/Email-nikunjwadhwa002@gmail.com-D14836?style=flat&logo=gmail)](mailto:nikunjwadhwa002@gmail.com)

---

*Built with Flutter + Supabase. Designed for Bharat. 🇮🇳*