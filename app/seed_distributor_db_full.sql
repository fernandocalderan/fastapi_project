\set ON_ERROR_STOP on
BEGIN;

-- ============================================================
-- seed_distributor_db_regen.sql (UTF-8) – versión corregida
-- ============================================================

-- ---------- Crear esquema ----------
DROP SCHEMA IF EXISTS distributor_raw CASCADE;
CREATE SCHEMA distributor_raw;
SET search_path TO distributor_raw;

-- ---------- Helper ----------
CREATE OR REPLACE FUNCTION gen_vat(prefix TEXT, seq INT) RETURNS TEXT AS $$
BEGIN
  RETURN prefix || to_char(10000000 + (seq % 90000000), 'FM99999999');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ---------- Tablas RAW ----------
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

CREATE TABLE allergens (
  id SERIAL PRIMARY KEY,
  code VARCHAR(30) UNIQUE NOT NULL,
  name VARCHAR(100) NOT NULL,
  description TEXT
);

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
  vat_rate NUMERIC(5,2) DEFAULT 10.00,
  uom VARCHAR(20),
  created_at DATE,
  status VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE product_allergens (
  product_id INT REFERENCES products(id) ON DELETE CASCADE,
  allergen_id INT REFERENCES allergens(id) ON DELETE CASCADE,
  PRIMARY KEY (product_id, allergen_id)
);

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
  vat_rate NUMERIC(5,2) NOT NULL
);

-- ---------- Datos base ----------
INSERT INTO allergens (code, name, description) VALUES
('GLUTEN','Gluten','Wheat rye barley'),
('CRUSTACEANS','Crustaceans','Shrimp crab lobster'),
('EGGS','Eggs','Eggs and products thereof'),
('FISH','Fish','All fishes'),
('PEANUTS','Peanuts','Peanut and products thereof'),
('SOY','Soy','Soy and products thereof'),
('MILK','Milk','Milk and dairy products'),
('NUTS','TreeNuts','Almonds hazelnuts etc'),
('CELERY','Celery','Celery and products'),
('MUSTARD','Mustard','Mustard and products'),
('SESAME','Sesame','Sesame seeds and products'),
('SULPHITES','Sulphites','SO2 and sulphites');

-- ---------- Proveedores (fix de columnas) ----------
INSERT INTO providers (
  company_name, vat_number, address, city, country, phone,
  email, contact_person, provider_type, certifications,
  registration_date, status
)
SELECT
  concat('Proveedor ', g),
  gen_vat('EU', g),
  concat((g % 200)+1, ' Supplier Ave'),
  (ARRAY['Barcelona','Madrid','Valencia','Seville','Bilbao','Lisbon','Porto','Paris','Milan','Berlin'])[1 + (g % 10)],
  (ARRAY['Spain','Spain','Spain','Spain','Spain','Portugal','Portugal','France','Italy','Germany'])[1 + (g % 10)],
  concat('+34', (600000000 + (g * 31))::text),
  lower(concat('proveedor', g, '@supplier.example.com')),
  (ARRAY['Juan','Laura','Carlos','Ana','Pedro','Marta','Luis','Sofia','Jorge','Elena'])[1 + (g % 10)],
  (ARRAY['Food','Beverage','Packaging','Logistics','Ingredients'])[1 + (g % 5)],
  (ARRAY['ISO22000','BRC','IFS','Organic','HACCP'])[1 + (g % 5)],
  (current_date - (g % 365))::date,
  'Active'
FROM generate_series(1,50) AS g;

-- ---------- Clientes (más de 500) ----------
INSERT INTO clients (
  company_name, vat_number, billing_address, city, province, postal_code, country,
  phone, email, contact_person, client_type, annual_volume_estimate, signup_date, status
)
SELECT
  concat('Cliente ', g),
  gen_vat('CL', g),
  concat('Calle ', g, ' Centro'),
  (ARRAY['Barcelona','Madrid','Valencia','Seville','Bilbao','Lisbon'])[1 + (g % 6)],
  'Spain',
  to_char(8000 + g, 'FM00000'),
  'Spain',
  concat('+34', (690000000 + g)::text),
  concat('cliente', g, '@example.com'),
  concat('Contacto ', g),
  (ARRAY['Restaurant','Bar','Supermarket','Hotel','Retail'])[1 + (g % 5)],
  round(50000 + random() * 200000, 2),
  (current_date - (g % 365))::date,
  'Active'
FROM generate_series(1,500) AS g;

-- ---------- Productos (1000) ----------
INSERT INTO products (
  sku, name, brand, category, description, ingredients, net_weight, format_description,
  origin_country, provider_id, lot_code, production_date, best_before,
  registration_number, unit_cost, margin_percent, unit_price, vat_rate, uom, created_at, status
)
SELECT
  concat('SKU-', g),
  concat('Producto ', g),
  (ARRAY['GreenHarvest','Sunfield','Bella','OceanCatch','GoldenGrain'])[1 + (g % 5)],
  (ARRAY['Beverages','Dairy','Bakery','Snacks','Frozen'])[1 + (g % 5)],
  concat('Descripción producto ', g),
  'water, sugar, salt',
  concat((100 + (g % 900)), ' g'),
  'Pack 6 x 330 ml',
  'Spain',
  (1 + (g % 50)),
  concat('LOT', g),
  (current_date - (g % 400))::date,
  (current_date + (g % 200))::date,
  concat('REG-', g),
  round(1 + random() * 20, 2),
  30,
  round(1 + random() * 50, 2),
  10,
  'unit',
  current_date,
  'Active'
FROM generate_series(1,1000) AS g;

COMMIT;
