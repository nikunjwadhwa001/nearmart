-- Seed 001: Categories
insert into public.categories (id, name, display_order) values
  (gen_random_uuid(), 'Dairy & Eggs', 1),
  (gen_random_uuid(), 'Fruits & Vegetables', 2),
  (gen_random_uuid(), 'Staples & Grains', 3),
  (gen_random_uuid(), 'Snacks & Beverages', 4),
  (gen_random_uuid(), 'Personal Care', 5),
  (gen_random_uuid(), 'Household', 6),
  (gen_random_uuid(), 'Bakery & Bread', 7),
  (gen_random_uuid(), 'Frozen Foods', 8);