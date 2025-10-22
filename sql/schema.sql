-- Esquema relacional para la distribuidora de alimentos
-- Ejecuta este script en una base de datos PostgreSQL vacía antes de importar los datos

CREATE TABLE suppliers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    contact_name VARCHAR(120),
    phone VARCHAR(40),
    email VARCHAR(150),
    address VARCHAR(200),
    city VARCHAR(120),
    country VARCHAR(120)
);

CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(120) NOT NULL UNIQUE,
    description VARCHAR(250)
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    sku VARCHAR(60) UNIQUE,
    unit VARCHAR(40) NOT NULL,
    unit_price NUMERIC(12,2) NOT NULL,
    supplier_id INTEGER REFERENCES suppliers(id),
    category_id INTEGER REFERENCES categories(id),
    is_active CHAR(1) DEFAULT 'Y'
);

CREATE TABLE warehouses (
    id SERIAL PRIMARY KEY,
    name VARCHAR(120) NOT NULL UNIQUE,
    address VARCHAR(200),
    city VARCHAR(120),
    manager_name VARCHAR(120)
);

CREATE TABLE inventories (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES products(id),
    warehouse_id INTEGER NOT NULL REFERENCES warehouses(id),
    quantity_on_hand INTEGER NOT NULL DEFAULT 0,
    safety_stock INTEGER DEFAULT 0,
    last_restocked DATE
);

CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    contact_name VARCHAR(120),
    phone VARCHAR(40),
    email VARCHAR(150),
    address VARCHAR(200),
    city VARCHAR(120),
    country VARCHAR(120)
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(id),
    order_date DATE NOT NULL,
    required_date DATE,
    status VARCHAR(40) DEFAULT 'pendiente',
    total_amount NUMERIC(12,2) NOT NULL
);

CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(12,2) NOT NULL,
    discount NUMERIC(5,2) DEFAULT 0
);

CREATE TABLE shipments (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id),
    warehouse_id INTEGER REFERENCES warehouses(id),
    shipped_at TIMESTAMP,
    estimated_delivery DATE,
    delivery_status VARCHAR(40) DEFAULT 'en tránsito',
    tracking_number VARCHAR(120)
);

-- Índices de apoyo
CREATE INDEX idx_products_supplier ON products(supplier_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_inventory_product ON inventories(product_id);
CREATE INDEX idx_inventory_warehouse ON inventories(warehouse_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_shipments_status ON shipments(delivery_status);
