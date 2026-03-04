CREATE TABLE "users" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "full_name" varchar(100) NOT NULL,
  "phone" varchar(15) UNIQUE NOT NULL,
  "email" varchar(100) UNIQUE,
  "role" varchar(20) NOT NULL,
  "is_active" boolean DEFAULT true,
  "created_at" timestamp DEFAULT (now())
);

CREATE TABLE "addresses" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "user_id" uuid NOT NULL,
  "label" varchar(50),
  "address_line" text NOT NULL,
  "city" varchar(100),
  "pincode" varchar(10),
  "latitude" decimal(10,8),
  "longitude" decimal(11,8),
  "is_default" boolean DEFAULT false
);

CREATE TABLE "shops" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "owner_id" uuid NOT NULL,
  "name" varchar(150) NOT NULL,
  "description" text,
  "phone" varchar(15),
  "address_id" uuid,
  "latitude" decimal(10,8) NOT NULL,
  "longitude" decimal(11,8) NOT NULL,
  "status" varchar(20) DEFAULT 'pending',
  "logo_url" text,
  "is_open" boolean DEFAULT true,
  "created_at" timestamp DEFAULT (now()),
  "approved_at" timestamp
);

CREATE TABLE "categories" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "name" varchar(100) NOT NULL,
  "icon_url" text,
  "display_order" int DEFAULT 0,
  "is_active" boolean DEFAULT true
);

CREATE TABLE "products" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "category_id" uuid NOT NULL,
  "name" varchar(150) NOT NULL,
  "description" text,
  "image_url" text,
  "unit" varchar(50),
  "is_active" boolean DEFAULT true
);

CREATE TABLE "brands" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "name" varchar(100) NOT NULL,
  "logo_url" text,
  "is_active" boolean DEFAULT true
);

CREATE TABLE "product_variants" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "product_id" uuid NOT NULL,
  "brand_id" uuid NOT NULL,
  "variant_name" varchar(100),
  "image_url" text,
  "is_active" boolean DEFAULT true
);

CREATE TABLE "shop_inventory" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "shop_id" uuid NOT NULL,
  "variant_id" uuid NOT NULL,
  "price" decimal(10,2) NOT NULL,
  "stock_status" varchar(20) DEFAULT 'in_stock',
  "updated_at" timestamp DEFAULT (now())
);

CREATE TABLE "orders" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "customer_id" uuid NOT NULL,
  "shop_id" uuid NOT NULL,
  "delivery_address_id" uuid,
  "status" varchar(30) DEFAULT 'placed',
  "subtotal" decimal(10,2) NOT NULL,
  "commission_rate" decimal(5,2) NOT NULL,
  "commission_amount" decimal(10,2) NOT NULL,
  "total_amount" decimal(10,2) NOT NULL,
  "notes" text,
  "placed_at" timestamp DEFAULT (now()),
  "confirmed_at" timestamp,
  "delivered_at" timestamp,
  "cancelled_at" timestamp,
  "cancellation_reason" text
);

CREATE TABLE "order_items" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "order_id" uuid NOT NULL,
  "inventory_id" uuid NOT NULL,
  "product_name" varchar(150) NOT NULL,
  "brand_name" varchar(100) NOT NULL,
  "variant_name" varchar(100),
  "quantity" int NOT NULL,
  "unit_price" decimal(10,2) NOT NULL,
  "total_price" decimal(10,2) NOT NULL
);

CREATE TABLE "commission_ledger" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "order_id" uuid NOT NULL,
  "shop_id" uuid NOT NULL,
  "amount" decimal(10,2) NOT NULL,
  "status" varchar(20) DEFAULT 'pending',
  "settled_at" timestamp
);

CREATE TABLE "platform_config" (
  "key" varchar(100) PRIMARY KEY,
  "value" text NOT NULL,
  "updated_at" timestamp DEFAULT (now())
);

CREATE TABLE "notifications" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "user_id" uuid NOT NULL,
  "title" varchar(200) NOT NULL,
  "body" text,
  "type" varchar(50),
  "is_read" boolean DEFAULT false,
  "created_at" timestamp DEFAULT (now())
);

CREATE UNIQUE INDEX ON "shop_inventory" ("shop_id", "variant_id");

COMMENT ON COLUMN "users"."role" IS 'customer | owner | admin';

COMMENT ON COLUMN "addresses"."label" IS 'Home | Work | Other';

COMMENT ON COLUMN "shops"."status" IS 'pending | approved | suspended';

COMMENT ON COLUMN "products"."unit" IS 'kg | litre | pack | piece';

COMMENT ON COLUMN "product_variants"."variant_name" IS '1kg | 500ml | 6 pack';

COMMENT ON COLUMN "shop_inventory"."stock_status" IS 'in_stock | out_of_stock';

COMMENT ON COLUMN "orders"."status" IS 'placed | confirmed | preparing | out_for_delivery | delivered | cancelled';

COMMENT ON COLUMN "commission_ledger"."status" IS 'pending | settled';

COMMENT ON COLUMN "notifications"."type" IS 'new_order | order_update | shop_approved';

ALTER TABLE "addresses" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "shops" ADD FOREIGN KEY ("owner_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "shops" ADD FOREIGN KEY ("address_id") REFERENCES "addresses" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "products" ADD FOREIGN KEY ("category_id") REFERENCES "categories" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "product_variants" ADD FOREIGN KEY ("product_id") REFERENCES "products" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "product_variants" ADD FOREIGN KEY ("brand_id") REFERENCES "brands" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "shop_inventory" ADD FOREIGN KEY ("shop_id") REFERENCES "shops" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "shop_inventory" ADD FOREIGN KEY ("variant_id") REFERENCES "product_variants" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "orders" ADD FOREIGN KEY ("customer_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "orders" ADD FOREIGN KEY ("shop_id") REFERENCES "shops" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "orders" ADD FOREIGN KEY ("delivery_address_id") REFERENCES "addresses" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "order_items" ADD FOREIGN KEY ("order_id") REFERENCES "orders" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "order_items" ADD FOREIGN KEY ("inventory_id") REFERENCES "shop_inventory" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "commission_ledger" ADD FOREIGN KEY ("order_id") REFERENCES "orders" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "commission_ledger" ADD FOREIGN KEY ("shop_id") REFERENCES "shops" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "notifications" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;
