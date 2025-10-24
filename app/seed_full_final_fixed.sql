\set ON_ERROR_STOP on
BEGIN;

-- ===============================================
-- SEED FULL FINAL – versión limpia, completa y funcional
-- ===============================================

DROP SCHEMA IF EXISTS distributor_raw CASCADE;
CREATE SCHEMA distributor_raw;
SET search_path TO distributor_raw;

-- 🔹 Helper VAT
CREATE OR REPLACE FUNCTION gen_vat(prefix TEXT, seq INT) RETURNS TEXT AS $$
BEGIN
  RETURN prefix || to_char(10000000 + (seq % 90000000), 'FM99999999');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 🔹 Tablas RAW
CREATE TABLE providers (
  id SERIAL PRIMARY KEY,
  company_name TEXT,
  vat_number VARCHAR(30) UNIQUE,
  address TEXT, city TEXT, country TEXT,
  phone TEXT, email TEXT, contact_person TEXT,
  provider_type TEXT, certifications TEXT,
  registration_date DATE, status TEXT
);

CREATE TABLE clients (
  id SERIAL PRIMARY KEY,
  company_name TEXT, vat_number VARCHAR(30) UNIQUE,
  billing_address TEXT, city TEXT, province TEXT,
  postal_code TEXT, country TEXT,
  phone TEXT, email TEXT, contact_person TEXT,
  client_type TEXT, annual_volume_estimate NUMERIC,
  signup_date DATE, status TEXT
);

CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  sku TEXT UNIQUE, name TEXT, brand TEXT, category TEXT,
  description TEXT, ingredients TEXT,
  net_weight TEXT, format_description TEXT,
  origin_country TEXT, provider_id INT,
  unit_cost NUMERIC(10,2), margin_percent NUMERIC(5,2),
  unit_price NUMERIC(10,2), vat_rate NUMERIC(5,2),
  created_at DATE, status TEXT
);

-- ==========================================================
-- SEED Providers (50)
-- ==========================================================
INSERT INTO providers (company_name, vat_number, address, city, country, phone, email, contact_person, provider_type, certifications, registration_date, status)
SELECT
  concat('Proveedor ', g),
  gen_vat('EU', g),
  concat('Calle ', g, ' Industrial'),
  (ARRAY['Barcelona','Madrid','Valencia','Bilbao','Sevilla'])[1 + (g % 5)],
  'España',
  concat('+34', (600000000 + g * 31)::text),
  concat('proveedor', g, '@example.com'),
  (ARRAY['Laura','Carlos','Ana','Pedro','Marta'])[1 + (g % 5)],
  (ARRAY['Food','Beverage','Logistics','Packaging'])[1 + (g % 4)],
  (ARRAY['ISO22000','BRC','IFS','HACCP'])[1 + (g % 4)],
  (current_date - (g % 365)),
  'Active'
FROM generate_series(1,50) AS g;

-- ==========================================================
-- SEED Clients (300)
-- ==========================================================
INSERT INTO clients (company_name, vat_number, billing_address, city, province, postal_code, country, phone, email, contact_person, client_type, annual_volume_estimate, signup_date, status)
SELECT
  concat('Cliente ', g),
  gen_vat('CL', g),
  concat('Calle ', g, ' Centro'),
  (ARRAY['Barcelona','Madrid','Valencia','Bilbao','Sevilla'])[1 + (g % 5)],
  'Spain',
  to_char(8000 + g, 'FM00000'),
  'Spain',
  concat('+34', (690000000 + g)::text),
  concat('cliente', g, '@example.com'),
  concat('Contacto ', g),
  (ARRAY['Restaurant','Bar','Supermarket','Hotel','Retail'])[1 + (g % 5)],
  round((50000 + random() * 200000)::numeric, 2),
  (current_date - (g % 365))::date,
  'Active'
FROM generate_series(1,300) AS g;

-- ==========================================================
-- SEED Products (800)
-- ==========================================================
INSERT INTO products (sku, name, brand, category, description, ingredients, net_weight, format_description, origin_country, provider_id, unit_cost, margin_percent, unit_price, vat_rate, created_at, status)
SELECT
  concat('SKU-', g),
  concat('Producto ', g),
  (ARRAY['GreenHarvest','Sunfield','Bella','OceanCatch','GoldenGrain'])[1 + (g % 5)],
  (ARRAY['Beverages','Dairy','Bakery','Snacks','Frozen'])[1 + (g % 5)],
  concat('Descripción ', g),
  'water, sugar, salt',
  concat((100 + (g % 900)), ' g'),
  'Caja 6 uds',
  'Spain',
  (1 + (g % 50)),
  round((1 + random() * 20)::numeric, 2),
  30,
  round((2 + random() * 50)::numeric, 2),
  10,
  current_date,
  'Active'
FROM generate_series(1,800) AS g;

-- ==========================================================
-- SYNC A PUBLIC (con claves primarias)
-- ==========================================================
SET search_path TO public;

DROP TABLE IF EXISTS public.providers CASCADE;
DROP TABLE IF EXISTS public.clients CASCADE;
DROP TABLE IF EXISTS public.products CASCADE;
DROP TABLE IF EXISTS public.orders CASCADE;
DROP TABLE IF EXISTS public.order_items CASCADE;

CREATE TABLE providers AS SELECT * FROM distributor_raw.providers;
ALTER TABLE providers ADD PRIMARY KEY (id);

CREATE TABLE clients AS SELECT * FROM distributor_raw.clients;
ALTER TABLE clients ADD PRIMARY KEY (id);

CREATE TABLE products AS SELECT * FROM distributor_raw.products;
ALTER TABLE products ADD PRIMARY KEY (id);

-- ==========================================================
-- Orders y Order Items
-- ==========================================================
CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  client_id INT REFERENCES clients(id),
  order_date TIMESTAMP DEFAULT now(),
  status TEXT,
  total_net NUMERIC,
  total_vat NUMERIC,
  total_gross NUMERIC
);

CREATE TABLE order_items (
  id SERIAL PRIMARY KEY,
  order_id INT REFERENCES orders(id) ON DELETE CASCADE,
  product_id INT REFERENCES products(id),
  quantity INT,
  unit_price_net NUMERIC,
  vat_rate NUMERIC DEFAULT 10
);

INSERT INTO orders (client_id, order_date, status, total_net, total_vat, total_gross)
SELECT (random() * 300)::INT + 1, now() - (interval '1 day' * (random() * 90)),
       (ARRAY['Pending','Completed','Delivered'])[1 + (g % 3)],
       round((random() * 1000)::numeric, 2),
       round((random() * 200)::numeric, 2),
       round((random() * 1200)::numeric, 2)
FROM generate_series(1,200) AS g;

INSERT INTO order_items (order_id, product_id, quantity, unit_price_net, vat_rate)
SELECT (random() * 200)::INT + 1, (random() * 800)::INT + 1, 1 + (random() * 10)::INT,
       round((1 + random() * 50)::numeric, 2), 10
FROM generate_series(1,400) AS g;

COMMIT;
