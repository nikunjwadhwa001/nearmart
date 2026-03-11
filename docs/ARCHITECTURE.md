# NearMart — Architecture Overview

## Vision
Hyperlocal grocery marketplace connecting local kirana shops with nearby 
customers in Tier 2-3 Indian cities. Built mobile-first because both 
customers and shop owners are primarily smartphone users.

## System Components

### 1. Mobile App (Flutter) — Customers + Shop Owners
Single Flutter app serving two roles with role-based UI routing.

**Customer screens:**
- Splash, Login, OTP verification
- Home — nearby shops discovery
- Shop detail — product catalog
- Cart — item management
- Order tracking — live status updates
- Profile — account management

**Shop Owner screens:**
- Owner home — today's orders and earnings summary
- Incoming orders — accept or reject new orders
- Order management — update order status (preparing, ready, delivered)
- Inventory management — add or remove products from catalog
- Earnings — monthly commission or subscription summary

**Role-based routing:**
- Customer logs in → /home (customer interface)
- Shop owner logs in → /owner/home (owner interface)
- Admin logs in → shown message to use web dashboard

### 2. React Web Dashboard — Super Admin ONLY
Admin manages the entire platform from a web browser.

**Admin capabilities:**
- Approve or reject new shop registrations
- Manage product catalog — add new products, variants, brands
- View all orders across platform
- Commission settlement — view pending commissions, mark as paid
- Subscription management — activate or deactivate shop subscriptions
- Platform configuration — commission rate, subscription fee

### 3. Backend (Supabase)
- PostgreSQL database — 12 tables with full relational schema
- Built-in Auth — email OTP for development, phone OTP for production
- Realtime subscriptions — live order status updates
- Row Level Security — data access enforced at database level
- Auto-generated REST API from schema
- Database functions — nearby shops, shop inventory, place order

## Database Schema

### Core Tables
| Table | Purpose |
|---|---|
| users | Single table for all roles — customer, owner, admin |
| addresses | Customer and shop delivery addresses |
| shops | Shop listings with GPS coordinates and billing model |
| categories | Product categories — Dairy, Snacks, Staples etc |
| products | Master product catalog |
| brands | Brand information |
| product_variants | Specific variants — Amul Butter 100g, 500g etc |
| shop_inventory | Products available at each shop with shop-specific pricing |
| orders | Customer orders |
| order_items | Individual items in each order with price snapshots |
| commission_ledger | Monthly commission tracking per shop |
| platform_config | Key-value settings — commission rate, subscription fee |
| notifications | Per-user notification feed |

## Billing Models

### Commission Model (default)
- Shop owner pays 5% of total monthly sales through NearMart
- Commission recorded per order in commission_ledger as 'pending'
- Settled on 1st of every month
- First month is pro-rated from join date to end of month
- Admin collects manually via UPI, marks as paid in dashboard

### Subscription Model
- Shop owner pays ₹499/month flat fee
- Billing cycle tied to join date — not calendar month
- Full month from join date regardless of when they joined
- No per-order commission — shop keeps 100% of every order
- Break-even vs commission model at ₹9,980/month in orders

### Customer Pricing
- Customer pays exactly what they see on the product — no hidden fees
- No platform fee charged to customer
- Commission is purely between NearMart and shop owner

## Data Flow

### Customer placing an order:
```
Customer adds items to cart (local Riverpod state)
        ↓
Taps Place Order
        ↓
Supabase function runs atomically:
  → Creates order row
  → Creates order_items rows with price snapshots
  → Creates commission_ledger entry (commission shops only)
        ↓
Cart cleared locally
        ↓
Realtime event fires → Shop owner's Flutter app gets push notification
        ↓
Shop owner accepts order → status updated
        ↓
Customer sees live status update via Supabase Realtime
```

### Shop owner managing inventory:
```
Owner logs into Flutter app (owner role)
        ↓
Browses master product catalog
        ↓
Adds products to their shop with their own prices
        ↓
Products appear in shop_inventory table
        ↓
Customers can now see and order those products
```

### Monthly commission settlement:
```
1st of every month
        ↓
Admin opens React dashboard
        ↓
Sees all commission shops with pending amounts
        ↓
Contacts shop owner via WhatsApp/call
        ↓
Shop owner pays via UPI
        ↓
Admin marks as paid in dashboard
        ↓
commission_ledger entries updated to 'paid'
```

## Key Design Decisions

### Why Flutter for shop owners (not a web dashboard)
Indian kirana shop owners are mobile-first. Most do not have laptops or 
desktops. A React web dashboard on a mobile browser is a poor experience — 
small buttons, no push notifications, needs browser to stay open. Flutter 
gives shop owners a native mobile experience identical to what they use 
for WhatsApp and PhonePe.

### Why a single Flutter app (not two separate apps)
One codebase is easier to maintain. Role-based routing inside one app means 
shared auth, shared Supabase connection, shared theme. Shop owners and 
customers never see each other's screens.

### Why Supabase over Firebase
NearMart has deeply relational data — categories, products, variants, shops, 
inventory, orders, commissions. PostgreSQL handles complex joins in one query. 
Firestore would require multiple round trips and client-side joins.

### Why centralized product catalog
Shop owners pick from a master catalog instead of creating their own listings. 
This ensures consistent product names and images across all shops. Customers 
can search "Amul Butter" and find it across multiple shops with different prices.

### Why price is in shop_inventory not products
Each shop sets their own price for the same product. A shop with a cheaper 
supplier can offer lower prices and attract more customers. This mirrors 
how real kirana shops work.

### Why order_items snapshots prices
Product prices can change. An order placed today must always show the price 
that was actually paid — not the current price. Snapshotting at order time 
preserves accurate order history forever.

## Tech Stack
| Layer | Technology |
|---|---|
| Customer + Owner Mobile App | Flutter (Dart) |
| State Management | Riverpod |
| Navigation | GoRouter |
| Admin Web Dashboard | React + Vite + Tailwind CSS |
| Backend | Supabase (PostgreSQL + Auth + Realtime) |
| Deployment | Vercel (dashboard) + Supabase (backend) |

## Development Setup
- Flutter SDK — mobile app development
- Node.js + npm — React dashboard
- Supabase CLI — local development and migrations
- VS Code — primary editor

## Folder Structure
```
nearmart/
├── mobile/          ← Flutter app (customers + shop owners)
│   └── lib/
│       ├── core/    ← Theme, router, Supabase client
│       ├── models/  ← Data models
│       └── features/
│           ├── auth/     ← Login, OTP
│           ├── home/     ← Customer home, shop discovery
│           ├── shop/     ← Shop detail, product catalog
│           ├── cart/     ← Cart management
│           ├── orders/   ← Order tracking
│           ├── profile/  ← Customer profile
│           └── owner/    ← All shop owner screens
├── admin-dashboard/ ← React admin dashboard
├── backend/         ← Supabase migrations and seed data
└── docs/            ← Architecture and schema documentation
```

## Roadmap
| Phase | What gets built |
|---|---|
| Phase 1 (current) | Customer app — browse, cart, order |
| Phase 2 | Shop owner app — orders, inventory, earnings |
| Phase 3 | React admin dashboard |
| Phase 4 | Payment automation — Razorpay integration |
| Phase 5 | Push notifications — FCM integration |
| Phase 6 | Production deployment |