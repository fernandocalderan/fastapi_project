\set ON_ERROR_STOP on
BEGIN;
SET search_path TO public;

-- ============================================================
-- Sincronización de datos desde distributor_raw → public
-- ============================================================

-- 🔹 Elimina si existían versiones anteriores
DROP TABLE IF EXISTS public.order_items CASCADE;
DROP TABLE IF EXISTS public.orders CASCADE;
DROP TABLE IF EXISTS public.products CASCADE;
DROP TABLE IF EXISTS public.clients CASCADE;
DROP TABLE IF EXISTS public.providers CASCADE;
DROP TABLE IF EXISTS public.workers CASCADE;
DROP TABLE IF EXISTS public.allergens CASCADE;

-- 🔹 Recrea estructura simplificada
CREATE TABLE providers AS SELECT * FROM distributor_raw.providers;
CREATE TABLE clients   AS SELECT * FROM distributor_raw.clients;
CREATE TABLE products  AS SELECT * FROM distributor_raw.products;
CREATE TABLE workers   AS SELECT * FROM distributor_raw.workers;
CREATE TABLE allergens AS SELECT * FROM distributor_raw.allergens;

-- 🔹 Índices básicos
CREATE INDEX idx_products_id   ON products(id);
CREATE INDEX idx_clients_id    ON clients(id);
CREATE INDEX idx_providers_id  ON providers(id);

-- 🔹 Crear tablas vacías para pedidos y sus items
CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  client_id INT REFERENCES clients(id) ON DELETE SET NULL,
  order_date TIMESTAMP DEFAULT now(),
  status VARCHAR(30) DEFAULT 'Pending',
  total_net NUMERIC(14,2) DEFAULT 0,
  total_vat NUMERIC(14,2) DEFAULT 0,
  total_gross NUMERIC(14,2) DEFAULT 0
);

CREATE TABLE order_items (
  id SERIAL PRIMARY KEY,
  order_id INT REFERENCES orders(id) ON DELETE CASCADE,
  product_id INT REFERENCES products(id) ON DELETE SET NULL,
  quantity INT NOT NULL,
  unit_price_net NUMERIC(10,2) NOT NULL,
  vat_rate NUMERIC(5,2) DEFAULT 10
);

-- 🔹 Generar 200 pedidos ficticios con items
INSERT INTO orders (client_id, order_date, status, total_net, total_vat, total_gross)
SELECT
  (RANDOM() * 500)::INT + 1,
  now() - (INTERVAL '1 day' * (RANDOM() * 90)),
  (ARRAY['Pending','Shipped','Completed'])[1 + (g % 3)],
  round(100 + random() * 1000, 2),
  round(20 + random() * 200, 2),
  round(120 + random() * 1200, 2)
FROM generate_series(1,200) AS g;

INSERT INTO order_items (order_id, product_id, quantity, unit_price_net, vat_rate)
SELECT
  (RANDOM() * 200)::INT + 1,
  (RANDOM() * 1000)::INT + 1,
  1 + (RANDOM() * 20)::INT,
  round(1 + random() * 50, 2),
  10
FROM generate_series(1,500) AS g;

COMMIT;
