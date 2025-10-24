\set ON_ERROR_STOP on

-- seed_distributor_db_full.sql
-- PostgreSQL 13+ | Educational seed DB for a food & beverage distributor
-- English data content simulated. Prices in EUR (net). VAT applied via vat_rate.
BEGIN;

-- Work inside a dedicated schema so we can later transform the data into the
-- tables expected by the FastAPI application without clobbering them.
DROP SCHEMA IF EXISTS distributor_raw CASCADE;
CREATE SCHEMA distributor_raw;
CREATE SCHEMA IF NOT EXISTS distributor_raw;
SET search_path TO distributor_raw;

-- Drop previous
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS product_allergens CASCADE;
DROP TABLE IF EXISTS allergens CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS clients CASCADE;
DROP TABLE IF EXISTS providers CASCADE;
DROP TABLE IF EXISTS workers CASCADE;

-- PROVIDERS
CREATE TABLE providers (
  id SERIAL PRIMARY KEY,
  company_name TEXT NOT NULL,
  vat_number VARCHAR(30) NOT NULL UNIQUE,
  address TEXT,
  city VARCHAR(100),
  country VARCHAR(100),
  phone VARCHAR(30),
  email VARCHAR(150),
  contact_person VARCHAR(120),
  provider_type VARCHAR(50),
  certifications TEXT,
  registration_date DATE,
  status VARCHAR(20) DEFAULT 'Active'
);

-- WORKERS
CREATE TABLE workers (
  id SERIAL PRIMARY KEY,
  full_name VARCHAR(120) NOT NULL,
  national_id VARCHAR(30) UNIQUE NOT NULL,
  role VARCHAR(80),
  department VARCHAR(80),
  birth_date DATE,
  hire_date DATE,
  gross_annual_salary NUMERIC(12,2),
  contract_type VARCHAR(30),
  phone VARCHAR(30),
  email VARCHAR(150),
  address TEXT,
  city VARCHAR(80),
  postal_code VARCHAR(12),
  country VARCHAR(80),
  status VARCHAR(20) DEFAULT 'Active'
);

-- CLIENTS (legal entities)
CREATE TABLE clients (
  id SERIAL PRIMARY KEY,
  company_name TEXT NOT NULL,
  vat_number VARCHAR(30) UNIQUE NOT NULL,
  billing_address TEXT,
  city VARCHAR(80),
  province VARCHAR(80),
  postal_code VARCHAR(12),
  country VARCHAR(80),
  phone VARCHAR(30),
  email VARCHAR(150),
  contact_person VARCHAR(120),
  client_type VARCHAR(40),
  annual_volume_estimate NUMERIC(14,2),
  signup_date DATE,
  status VARCHAR(20) DEFAULT 'Active'
);

-- ALLERGENS (normalized)
CREATE TABLE allergens (
  id SERIAL PRIMARY KEY,
  code VARCHAR(30) UNIQUE NOT NULL,
  name VARCHAR(100) NOT NULL,
  description TEXT
);

-- PRODUCTS (catalog) — includes traceability fields and VAT
CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  sku VARCHAR(40) UNIQUE NOT NULL,
  name TEXT NOT NULL,
  brand VARCHAR(120),
  category VARCHAR(80),
  description TEXT,
  ingredients TEXT,
  net_weight VARCHAR(40),
  format_description VARCHAR(80),
  origin_country VARCHAR(80),
  provider_id INTEGER REFERENCES providers(id) ON DELETE SET NULL,
  lot_code VARCHAR(60),
  production_date DATE,
  best_before DATE,
  registration_number VARCHAR(60),
  unit_cost NUMERIC(10,2),
  margin_percent NUMERIC(5,2),
  unit_price NUMERIC(10,2),
  vat_rate NUMERIC(5,2) DEFAULT 10.00, -- default VAT (percent). Use 10 or 21 as needed.
  unit_price_inc_vat NUMERIC(12,2) GENERATED ALWAYS AS (round(unit_price * (1 + vat_rate/100),2)) STORED,
  uom VARCHAR(20),
  created_at DATE,
  status VARCHAR(20) DEFAULT 'Active'
);

-- Junction table: product_allergens
CREATE TABLE product_allergens (
  product_id INT REFERENCES products(id) ON DELETE CASCADE,
  allergen_id INT REFERENCES allergens(id) ON DELETE CASCADE,
  PRIMARY KEY (product_id, allergen_id)
);

-- ORDERS + ITEMS (sample sales data)
CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  client_id INT REFERENCES clients(id) ON DELETE SET NULL,
  order_date TIMESTAMP NOT NULL DEFAULT now(),
  status VARCHAR(30) DEFAULT 'Pending',
  total_net NUMERIC(14,2) DEFAULT 0,
  total_vat NUMERIC(14,2) DEFAULT 0,
  total_gross NUMERIC(14,2) DEFAULT 0
);

CREATE TABLE order_items (
  id SERIAL PRIMARY KEY,
  order_id INT REFERENCES orders(id) ON DELETE CASCADE,
  product_id INT REFERENCES products(id) ON DELETE SET NULL,
  quantity INT NOT NULL CHECK (quantity > 0),
  unit_price_net NUMERIC(10,2) NOT NULL,
  vat_rate NUMERIC(5,2) NOT NULL,
  line_total_net NUMERIC(14,2) GENERATED ALWAYS AS (round(unit_price_net * quantity, 2)) STORED,
  line_total_vat NUMERIC(14,2) GENERATED ALWAYS AS (round(unit_price_net * quantity * (vat_rate/100), 2)) STORED,
  line_total_gross NUMERIC(14,2) GENERATED ALWAYS AS (round(unit_price_net * quantity * (1 + vat_rate/100), 2)) STORED
);

-- Indexes for performance
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_brand ON products(brand);
CREATE INDEX idx_clients_vat ON clients(vat_number);
CREATE INDEX idx_providers_vat ON providers(vat_number);
CREATE INDEX idx_orders_client ON orders(client_id);

-- Helper function to generate fake VAT-like identifiers (educational only)
CREATE OR REPLACE FUNCTION gen_vat(prefix TEXT, seq INT) RETURNS TEXT AS $$
BEGIN
  RETURN prefix || to_char(10000000 + (seq % 90000000), 'FM99999999');
END; $$ LANGUAGE plpgsql IMMUTABLE;

-- Seed minimal allergens table (standard EU allergens)
INSERT INTO allergens (code, name, description) VALUES
('GLUTEN','Gluten','Protein found in wheat, rye, barley'),
('CRUSTACEANS','Crustaceans','Shrimp, crab, lobster'),
('EGGS','Eggs','Eggs and products thereof'),
('FISH','Fish','All fishes'),
('PEANUTS','Peanuts','Peanut and products thereof'),
('SOY','Soy','Soy and products thereof'),
('MILK','Milk','Milk and dairy products'),
('NUTS','TreeNuts','Tree nuts: almonds, hazelnuts...'),
('CELERY','Celery','Celery and products'),
('MUSTARD','Mustard','Mustard and products'),
('SESAME','Sesame','Sesame seeds and products'),
('SULPHITES','Sulphites','Sulphites and sulphur dioxide');

-- Seed providers (50) - simplified realistic-simulated
WITH brands AS (
  SELECT unnest(ARRAY[
    'GreenHarvest Foods','AquaPure Beverages','Sunfield Organics','Bella Snacks',
    'GoldenGrain Mills','VitalJuice Co','OceanCatch Seafood','MountainDairy','VivaCoffee Roasters','PureSip Waters',
    'UrbanBread Co','CampoOlive Oils','CrispBite Snacks','Meadow Eggs','RedVine Wines',
    'HerbGarden Spices','PrimeMeats Ltd.','EcoPack Solutions','BrewHouse Ales','FreshCatch'
  ]) AS brand
)
INSERT INTO providers (company_name, vat_number, address, city, country, phone, email, contact_person, provider_type, certifications, registration_date, status)
SELECT
  concat(brand, ' Ltd.') as company_name,
  gen_vat('EU', g) as vat_number,
  concat((g % 200)+1, ' Supplier Ave') as address,
  (ARRAY['Barcelona','Madrid','Valencia','Seville','Bilbao','Lisbon','Porto','Paris','Milan','Berlin'])[1 + (g % 10)],
  (ARRAY['Spain','Spain','Spain','Spain','Portugal','Portugal','France','Italy','Germany','Netherlands'])[1 + (g % 10)],
  concat('+34', (600000000 + (g * 31))::text),
  lower(replace(brand,' ','') || '@supplier.example.com'),
  concat( (ARRAY['Alice Green','Mark Stone','Sofia Rossi','Luis Garcia','Emma Moreira'])[1 + (g % 5)] ),
  (ARRAY['Food','Beverage','Packaging','Logistics','Ingredients'])[1 + (g % 5)],
  (ARRAY['ISO 22000','BRC','IFS','Organic Cert','HACCP'])[1 + (g % 5)],
  (current_date - (g % 365))::date,
  'Active'
FROM generate_series(1,50) AS g;

-- Seed workers (20)
INSERT INTO workers (full_name, national_id, role, department, birth_date, hire_date, gross_annual_salary, contract_type, phone, email, address, city, postal_code, country, status)
SELECT
  (ARRAY['Fernando Aringhieri','Lilian Aguiar','Carlos Mendes','Sara Lopez','Miguel Santos','Anna Keller','John Smith','Emily Clark','Oliver Brown','Sofia Martins','Luis Rodriguez','Marta Diaz','Pablo Ruiz','Clara Iglesias','David Perez','Nora Silva','Hugo Fernandes','Laura Gomez','Iker Martinez','Elena Torres'])[g] as full_name,
  concat('ID', to_char(10000000 + g, 'FM9999999')) as national_id,
  (ARRAY['Logistics Manager','Warehouse Operative','Sales Executive','Accountant','Procurement Specialist','Driver','Quality Technician','Customer Success','IT Specialist','HR Manager'])[1 + (g % 10)] as role,
  (ARRAY['Logistics','Operations','Sales','Finance','Procurement','Transport','Quality','Customer','IT','HR'])[1 + (g % 10)] as department,
  (date '1980-01-01' + (g * 1000) * interval '1 day')::date as birth_date,
  (current_date - (g * 30))::date as hire_date,
  (22000 + (g % 10) * 1400)::numeric(12,2) as gross_annual_salary,
  (ARRAY['Indefinido','Temporal','Indefinido','Prácticas'])[1 + (g % 4)] as contract_type,
  concat('+34', (610000000 + g)::text) as phone,
  lower(replace((ARRAY['fernando','lilian','carlos','sara','miguel','anna','john','emily','oliver','sofia','luis','marta','pablo','clara','david','nora','hugo','laura','iker','elena'])[g], ' ', '')) || '@distributor.example.com' as email,
  concat((10 + g % 90), ' Industrial Park') as address,
  (ARRAY['Barcelona','Madrid','Valencia','Seville','Bilbao'])[1 + (g % 5)] as city,
  to_char(8000 + g, 'FM00000') as postal_code,
  'Spain' as country,
  'Active'
FROM generate_series(1,20) AS g;

-- Seed clients (500)
INSERT INTO clients (company_name, vat_number, billing_address, city, province, postal_code, country, phone, email, contact_person, client_type, annual_volume_estimate, signup_date, status)
SELECT
  concat((ARRAY['BlueStone','LaVida','CasaBella','MetroFoods','GreenFork','Sol & Mar','TerraCotta','UrbanEats','PrimeGrocer','NightOwl'])[1 + (g % 10)], ' ', (ARRAY['Restaurant','Bar','Hotel','Supermarket','Catering'])[1 + (g % 5)]) as company_name,
  gen_vat('CL', g) as vat_number,
  concat((g % 200)+1, ' Market Street') as billing_address,
  (ARRAY['Barcelona','Madrid','Valencia','Seville','Bilbao','Alicante','Malaga','Zaragoza','Palma','Santander'])[1 + (g % 10)] as city,
  (ARRAY['Barcelona','Madrid','Valencia','Seville','Bilbao'])[1 + (g % 5)] as province,
  to_char(10000 + (g % 90000), 'FM00000') as postal_code,
  (ARRAY['Spain','Portugal','France','Italy','Germany'])[1 + (g % 5)] as country,
  concat('+34', (690000000 + g)::text),
  lower( replace( concat('contact', g, '@client.example.com'), ' ', '') ),
  concat( (ARRAY['Miguel','Laura','Carlos','Ana','Jorge','Sofia','Diego','Elena','Pablo','Irene'])[1 + (g % 10)], ' ', (ARRAY['Gomez','Lopez','Silva','Fernandez','Martins'])[1 + (g % 5)] ),
  (ARRAY['Restaurant','Bar','Supermarket','Hotel','Catering','Retail'])[1 + (g % 6)],
  round( (50000 + random() * 200000)::numeric,2),
  (current_date - (g % 365))::date,
  'Active'
FROM generate_series(1,500) AS g;

-- Seed products (1000) with VAT rates (10% or 21% typical)
DO $$
DECLARE
  categories TEXT[] := ARRAY[
    'Beverages','Dairy','Bakery','Canned Goods','Snacks','Frozen','Condiments','Meat','Seafood',
    'Pasta & Grains','Confectionery','Oils & Vinegars','Spices','Ready Meals','Produce','Breakfast Cereals'
  ];
  brands TEXT[] := ARRAY[
    'GreenHarvest','AquaPure','Sunfield','Bella','GoldenGrain','VitalJuice','OceanCatch','MountainDairy','VivaCoffee','PureSip',
    'UrbanBread','CampoOlive','CrispBite','MeadowFresh','RedVine','HerbGarden','PrimeMeats','EcoPack','BrewHouse','FreshCatch'
  ];
  formats TEXT[] := ARRAY[
    'Bottle 1 L','Bottle 500 ml','Can 330 ml','Pack 6 x 330 ml','Jar 350 g','Bag 250 g','Box 12 pcs','Tray 1 kg','Pouch 400 g','Carton 1 L'
  ];
  origins TEXT[] := ARRAY['Spain','Portugal','Italy','France','Germany','Netherlands','Poland','Greece','Belgium','Ireland'];
  provider_count INT;
  i INT;
  prov_id INT;
  base_cost NUMERIC;
  margin NUMERIC;
  price NUMERIC;
  ing_count INT;
  ingr TEXT;
  allergens_selected INT;
  regnum TEXT;
  lotcode TEXT;
  prod_date DATE;
  bb_date DATE;
  vat_choice NUMERIC;
BEGIN
  SELECT count(*) INTO provider_count FROM providers;

  FOR i IN 1..1000 LOOP
    prov_id := ( (i * 37) % provider_count ) + 1;
    base_cost := round( ( (0.5 + random() * 25) )::numeric, 2); -- base cost between 0.5 and 25 EUR
    margin := round( (10 + random() * 120)::numeric, 2); -- margin between 10% and 130%
    price := round( base_cost * (1 + margin/100)::numeric, 2);
    ingr := '';
    ing_count := 2 + (random() * 4)::int;
    FOR reg IN 1..ing_count LOOP
      ingr := ingr || (ARRAY['water','sugar','salt','wheat flour','milk','cocoa','olive oil','sunflower oil','eggs','yeast','tomato','beef','chicken','fish','lemon','orange','apple','garlic','onion','herbs','pepper','rice','potato','corn','soy'])[1 + (floor(random() * 24)::int)];
      IF reg < ing_count THEN ingr := ingr || ', '; END IF;
    END LOOP;
    allergens_selected := 1 + floor(random() * 11);
    regnum := concat('REG-', to_char(i, 'FM0000000'), '-', substring(md5(now()::text || i::text) from 1 for 6));
    lotcode := concat('LOT', to_char((random()*1000000)::int,'FM000000'));
    prod_date := (current_date - (1 + (random()*400)::int))::date;
    bb_date := prod_date + ((30 + (random()*720)::int) || ' days')::interval;
    vat_choice := CASE WHEN random() < 0.6 THEN 10.00 ELSE 21.00 END;
    INSERT INTO products (sku, name, brand, category, description, ingredients, net_weight, format_description, origin_country, provider_id, lot_code, production_date, best_before, registration_number, unit_cost, margin_percent, unit_price, vat_rate, uom, created_at, status)
    VALUES (
      concat('SKU-', to_char(i,'FM0000000')),
      concat( (brands[1 + (floor(random()*array_length(brands,1))::int)]), ' ', (categories[1 + (floor(random()*array_length(categories,1))::int)]) , ' ', (1 + (random()*999))::int ),
      brands[1 + (floor(random()*array_length(brands,1))::int)],
      categories[1 + (floor(random()*array_length(categories,1))::int)],
      concat('High quality ', lower( (categories[1 + (floor(random()*array_length(categories,1))::int)]) ), ' product from trusted supplier.'),
      ingr,
      CASE WHEN random() < 0.4 THEN concat((100 + (random()*900)::int), ' g') ELSE concat((250 + (random()*1750)::int), ' g') END,
      formats[1 + (floor(random()*array_length(formats,1))::int)],
      origins[1 + (floor(random()*array_length(origins,1))::int)],
      prov_id,
      lotcode,
      prod_date,
      bb_date::date,
      regnum,
      base_cost,
      margin,
      price,
      vat_choice,
      'unit',
      current_date - ((random()*365)::int),
      'Active'
    );
    -- link a random allergen (for demo)
    IF (random() < 0.45) THEN
      INSERT INTO product_allergens (product_id, allergen_id)
      VALUES (currval('products_id_seq'), 1 + floor(random() * (SELECT count(*) FROM allergens)));
    END IF;
  END LOOP;
END $$;

-- Seed example orders (10 orders with items)
DO $$
DECLARE
  c INT;
  product_id INT;
  qty INT;
  order_id INT;
  price NUMERIC;
  vat_rate NUMERIC;
  total_net NUMERIC := 0;
  total_vat NUMERIC := 0;
  total_gross NUMERIC := 0;
BEGIN
  FOR c IN 1..10 LOOP
    INSERT INTO orders (client_id, order_date, status)
    VALUES ((1 + (c % 500)), now() - (c * interval '2 days'), 'Completed')
    RETURNING id INTO order_id;

    total_net := 0;
    total_vat := 0;
    total_gross := 0;

    FOR i IN 1..(3 + (random()*3)::int) LOOP
      -- pick random product and keep its price + VAT for totals
      SELECT id, unit_price, vat_rate
      INTO STRICT product_id, price, vat_rate
      FROM (
        SELECT id, unit_price, vat_rate
        FROM products
        ORDER BY random()
        LIMIT 1
      ) t;

      qty := 1 + (random()*10)::int;

      INSERT INTO order_items (order_id, product_id, quantity, unit_price_net, vat_rate)
      VALUES (order_id, product_id, qty, price, vat_rate);

      total_net := total_net + round(price * qty, 2);
      total_vat := total_vat + round(price * qty * (vat_rate/100), 2);
      total_gross := total_gross + round(price * qty * (1 + vat_rate/100), 2);
    END LOOP;

    UPDATE orders
    SET total_net = round(total_net, 2),
        total_vat = round(total_vat, 2),
        total_gross = round(total_gross, 2)
    WHERE id = order_id;
  END LOOP;
END $$;

-- Switch back to the public schema and synchronize the canonical tables used
-- by the FastAPI application with the freshly generated raw data.
SET search_path TO public;

-- Ensure base tables exist (aligned with sql/schema.sql)
CREATE TABLE IF NOT EXISTS suppliers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    contact_name VARCHAR(120),
    phone VARCHAR(40),
    email VARCHAR(150),
    address VARCHAR(200),
    city VARCHAR(120),
    country VARCHAR(120)
);

CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(120) NOT NULL UNIQUE,
    description VARCHAR(250)
);

CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    sku VARCHAR(60) UNIQUE,
    unit VARCHAR(40) NOT NULL,
    unit_price NUMERIC(12,2) NOT NULL,
    supplier_id INTEGER REFERENCES suppliers(id),
    category_id INTEGER REFERENCES categories(id),
    is_active CHAR(1) DEFAULT 'Y'
);

CREATE TABLE IF NOT EXISTS warehouses (
    id SERIAL PRIMARY KEY,
    name VARCHAR(120) NOT NULL UNIQUE,
    address VARCHAR(200),
    city VARCHAR(120),
    manager_name VARCHAR(120)
);

CREATE TABLE IF NOT EXISTS inventories (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES products(id),
    warehouse_id INTEGER NOT NULL REFERENCES warehouses(id),
    quantity_on_hand INTEGER NOT NULL DEFAULT 0,
    safety_stock INTEGER DEFAULT 0,
    last_restocked DATE
);

CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    contact_name VARCHAR(120),
    phone VARCHAR(40),
    email VARCHAR(150),
    address VARCHAR(200),
    city VARCHAR(120),
    country VARCHAR(120)
);

CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(id),
    order_date DATE NOT NULL,
    required_date DATE,
    status VARCHAR(40) DEFAULT 'pendiente',
    total_amount NUMERIC(12,2) NOT NULL
);

CREATE TABLE IF NOT EXISTS order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(12,2) NOT NULL,
    discount NUMERIC(5,2) DEFAULT 0
);

CREATE TABLE IF NOT EXISTS shipments (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id),
    warehouse_id INTEGER REFERENCES warehouses(id),
    shipped_at TIMESTAMP,
    estimated_delivery DATE,
    delivery_status VARCHAR(40) DEFAULT 'en tránsito',
    tracking_number VARCHAR(120)
);

-- Clear previous canonical data so we can re-populate it from the raw tables
TRUNCATE
    public.order_items,
    public.orders,
    public.inventories,
    public.shipments,
    public.products,
    public.categories,
    public.warehouses,
    public.customers,
    public.suppliers
    RESTART IDENTITY CASCADE;

-- Suppliers
INSERT INTO public.suppliers (id, name, contact_name, phone, email, address, city, country)
SELECT
    id,
    company_name,
    contact_person,
    phone,
    email,
    address,
    city,
    country
FROM distributor_raw.providers
ORDER BY id;

-- Customers
INSERT INTO public.customers (id, name, contact_name, phone, email, address, city, country)
SELECT
    id,
    company_name,
    contact_person,
    phone,
    email,
    billing_address,
    city,
    country
FROM distributor_raw.clients
ORDER BY id;

-- Logistics footprint derived for the canonical schema so that the API
-- immediately exposes warehouses, inventory levels and shipment tracking.
INSERT INTO public.warehouses (name, address, city, manager_name)
SELECT name, address, city, manager_name
FROM (
    VALUES
        ('Central Madrid Norte', 'Calle Logística 12', 'Madrid', 'Ana Prieto'),
        ('Hub Barcelona Zona Franca', 'Av. del Puerto 455', 'Barcelona', 'Nil Forés'),
        ('Nodo Valencia Mediterráneo', 'Polígono Safor 77', 'Valencia', 'Clara Llopis'),
        ('Centro Sevilla Atlántico', 'Carretera Cádiz km 9', 'Sevilla', 'Rafael Moya'),
        ('Depósito Bilbao Norte', 'Parque Industrial Ibaizabal 5', 'Bilbao', 'Uxue Aguirre'),
        ('Plataforma Lisboa Tejo', 'Rua do Porto 210', 'Lisboa', 'Margarida Sousa')
) AS w(name, address, city, manager_name)
ORDER BY name;

-- Warehouses and inventories remain empty because the raw dataset does not
-- provide equivalent structures. Their sequences are adjusted in the post-load
-- reset block below.
-- Categories derived from the raw products catalog
INSERT INTO public.categories (name, description)
SELECT DISTINCT
    COALESCE(NULLIF(category, ''), 'Sin categoría') AS name,
    'Categoría generada a partir del dataset completo'
FROM distributor_raw.products
ORDER BY name;

-- Products mapped to the canonical schema
INSERT INTO public.products (id, name, sku, unit, unit_price, supplier_id, category_id, is_active)
SELECT
    p.id,
    p.name,
    p.sku,
    COALESCE(NULLIF(p.uom, ''), 'unidad') AS unit,
    p.unit_price,
    p.provider_id,
    c.id AS category_id,
    CASE WHEN COALESCE(p.status, 'Active') ILIKE 'Active%' THEN 'Y' ELSE 'N' END AS is_active
FROM distributor_raw.products p
LEFT JOIN public.categories c
    ON c.name = COALESCE(NULLIF(p.category, ''), 'Sin categoría')
ORDER BY p.id;

WITH wh AS (
    SELECT id, row_number() OVER (ORDER BY id) AS pos
    FROM public.warehouses
),
top_products AS (
    SELECT id, row_number() OVER (ORDER BY id) AS rn
    FROM public.products
    LIMIT 200
),
combinations AS (
    SELECT
        p.id AS product_id,
        w.id AS warehouse_id,
        (120 + ((p.rn * w.pos * 11) % 600))::int AS qty,
        (current_date - ((p.rn + w.pos * 3) % 45))::date AS restocked
    FROM top_products p
    JOIN wh w
        ON ((p.rn + w.pos) % 2 = 0)
)
INSERT INTO public.inventories (product_id, warehouse_id, quantity_on_hand, safety_stock, last_restocked)
SELECT
    product_id,
    warehouse_id,
    qty,
    GREATEST(30, (qty / 4))::int AS safety_stock,
    restocked
FROM combinations
ORDER BY product_id, warehouse_id;

-- Orders with their totals (cast timestamp to date)
INSERT INTO public.orders (id, customer_id, order_date, required_date, status, total_amount)
SELECT
    o.id,
    o.client_id,
    o.order_date::date,
    NULL,
    o.status,
    o.total_gross
FROM distributor_raw.orders o
ORDER BY o.id;

-- Order items referencing canonical products
INSERT INTO public.order_items (id, order_id, product_id, quantity, unit_price, discount)
SELECT
    oi.id,
    oi.order_id,
    oi.product_id,
    oi.quantity,
    oi.unit_price_net,
    0
FROM distributor_raw.order_items oi
ORDER BY oi.id;

WITH warehouse_count AS (
    SELECT count(*) AS total FROM public.warehouses
),
order_schedule AS (
    SELECT
        o.id,
        ((o.id - 1) % warehouse_count.total) + 1 AS warehouse_id,
        (o.order_date + ((o.id % 3) + 1) * interval '1 day') AS shipped_at,
        (o.order_date::date + ((o.id % 6) + 2)) AS estimated_delivery,
        CASE
            WHEN (o.id % 5) = 0 THEN 'retrasado'
            WHEN (o.id % 3) = 0 THEN 'en tránsito'
            ELSE 'entregado'
        END AS delivery_status
    FROM public.orders o, warehouse_count
)
INSERT INTO public.shipments (order_id, warehouse_id, shipped_at, estimated_delivery, delivery_status, tracking_number)
SELECT
    id,
    warehouse_id,
    shipped_at,
    estimated_delivery,
    delivery_status,
    concat('TRK-', lpad(id::text, 7, '0')) AS tracking_number
FROM order_schedule
ORDER BY id;

COMMIT;

-- Reset sequences dynamically so they stay aligned even if names differ from
-- the default pattern (<table>_<column>_seq) on the target database.
DO $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN
        SELECT
            tbl_name,
            pg_get_serial_sequence(tbl_name, 'id') AS seq_name
        FROM (
            VALUES
                ('public.suppliers'),
                ('public.customers'),
                ('public.warehouses'),
                ('public.inventories'),
                ('public.products'),
                ('public.orders'),
                ('public.order_items'),
                ('public.shipments')
        ) AS t(tbl_name)
    LOOP
        IF rec.seq_name IS NOT NULL THEN
            EXECUTE format(
                'SELECT setval(%L, COALESCE((SELECT MAX(id) FROM %s), 0), true);',
                rec.seq_name,
                rec.tbl_name
            );
        END IF;
    END LOOP;
END $$;

-- Quick verification notice so the operator can immediately confirm that the
-- canonical tables now contain data available to FastAPI and Metabase.
DO $$
DECLARE
    customers_count BIGINT;
    orders_count BIGINT;
    order_items_count BIGINT;
    products_count BIGINT;
    suppliers_count BIGINT;
    warehouses_count BIGINT;
    inventories_count BIGINT;
    shipments_count BIGINT;
BEGIN
    SELECT count(*) INTO customers_count FROM public.customers;
    SELECT count(*) INTO orders_count FROM public.orders;
    SELECT count(*) INTO order_items_count FROM public.order_items;
    SELECT count(*) INTO products_count FROM public.products;
    SELECT count(*) INTO suppliers_count FROM public.suppliers;
    SELECT count(*) INTO warehouses_count FROM public.warehouses;
    SELECT count(*) INTO inventories_count FROM public.inventories;
    SELECT count(*) INTO shipments_count FROM public.shipments;

    IF customers_count = 0 OR orders_count = 0 OR products_count = 0 OR suppliers_count = 0 THEN
        RAISE EXCEPTION 'Las tablas principales quedaron vacías (customers/orders/products/suppliers). Revisa los mensajes anteriores.';
    END IF;

    IF order_items_count = 0 THEN
        RAISE EXCEPTION 'La tabla order_items no recibió datos. Revisa la generación de pedidos.';
    END IF;

    IF warehouses_count = 0 OR inventories_count = 0 OR shipments_count = 0 THEN
        RAISE EXCEPTION 'Los datos logísticos no se poblaron (warehouses/inventories/shipments).';
    END IF;

    RAISE NOTICE 'Canonical totals — customers: %, orders: %, order_items: %, products: %, suppliers: %, warehouses: %, inventories: %, shipments: %',
        customers_count,
        orders_count,
        order_items_count,
        products_count,
        suppliers_count,
        warehouses_count,
        inventories_count,
        shipments_count;
END $$;

-- Quick verification queries (run after import)
-- SELECT count(*) FROM distributor_raw.providers; -- expect 50
-- SELECT count(*) FROM distributor_raw.workers; -- expect 20
-- SELECT count(*) FROM distributor_raw.clients; -- expect 500
-- SELECT count(*) FROM distributor_raw.products; -- expect 1000
-- SELECT * FROM distributor_raw.products LIMIT 5;
-- SELECT * FROM distributor_raw.orders ORDER BY order_date DESC LIMIT 10;
