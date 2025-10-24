\set ON_ERROR_STOP on

DROP SCHEMA IF EXISTS distributor_raw CASCADE;
CREATE SCHEMA distributor_raw;
SET search_path TO distributor_raw;

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

-- CLIENTS
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

-- PRODUCTS
CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  sku VARCHAR(40) UNIQUE NOT NULL,
  name TEXT NOT NULL,
  category VARCHAR(80),
  uom VARCHAR(20),
  unit_price NUMERIC(10,2),
  provider_id INT,
  status VARCHAR(20)
);

-- ORDERS
CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  client_id INT,
  order_date TIMESTAMP DEFAULT now(),
  status VARCHAR(30),
  total_gross NUMERIC(12,2)
);

-- ORDER_ITEMS
CREATE TABLE order_items (
  id SERIAL PRIMARY KEY,
  order_id INT,
  product_id INT,
  quantity INT,
  unit_price_net NUMERIC(10,2)
);

-- SEED DATA
INSERT INTO providers (company_name, vat_number, city, country, phone, email, contact_person, provider_type, status)
VALUES
('GreenHarvest Foods', 'EU12345678', 'Barcelona', 'Spain', '+34 600111222', 'info@greenharvest.com', 'Anna Lopez', 'Food', 'Active'),
('OceanCatch Seafood', 'EU23456789', 'Lisbon', 'Portugal', '+351 900222333', 'sales@oceancatch.com', 'Miguel Santos', 'Seafood', 'Active');

INSERT INTO clients (company_name, vat_number, billing_address, city, province, postal_code, country, phone, email, contact_person, client_type, annual_volume_estimate, signup_date, status)
VALUES
('BlueStone Restaurant', 'CL12345', 'Calle Marina 21', 'Barcelona', 'Barcelona', '08025', 'Spain', '+34 699888777', 'contact@bluestone.com', 'Jordi Serra', 'Restaurant', 125000, current_date - interval '180 days', 'Active'),
('CasaBella Catering', 'CL67890', 'Av. Diagonal 321', 'Madrid', 'Madrid', '28010', 'Spain', '+34 612345678', 'info@casabella.com', 'Laura Ruiz', 'Catering', 87000, current_date - interval '95 days', 'Active');

INSERT INTO products (sku, name, category, uom, unit_price, provider_id, status)
VALUES
('SKU-0001', 'Olive Oil Extra Virgin 1L', 'Oils', 'Litre', 8.50, 1, 'Active'),
('SKU-0002', 'Frozen Tuna Steak 200g', 'Seafood', 'Unit', 5.20, 2, 'Active');

INSERT INTO orders (client_id, order_date, status, total_gross)
VALUES
(1, current_timestamp - interval '3 days', 'Completed', 450.00),
(2, current_timestamp - interval '1 day', 'Pending', 275.00);

INSERT INTO order_items (order_id, product_id, quantity, unit_price_net)
VALUES
(1, 1, 10, 8.50),
(1, 2, 5, 5.20),
(2, 1, 8, 8.50);

COMMIT;
