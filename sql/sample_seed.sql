-- Conjunto mínimo de datos de ejemplo para validar la API
INSERT INTO suppliers (name, contact_name, phone, email, city, country)
VALUES
    ('Huerta Orgánica Andina', 'Lucía Torres', '+54 11 5555-1234', 'contacto@huertaandina.com', 'Buenos Aires', 'Argentina'),
    ('Mar de Sabores', 'Carlos Pinto', '+598 2 678-9000', 'ventas@mardesabores.uy', 'Montevideo', 'Uruguay');

INSERT INTO categories (name, description)
VALUES
    ('Frutas y Verduras', 'Productos frescos de estación'),
    ('Lácteos', 'Lácteos pasteurizados y madurados');

INSERT INTO products (name, sku, unit, unit_price, supplier_id, category_id)
VALUES
    ('Manzana Roja', 'FRU-001', 'kg', 3.25, 1, 1),
    ('Leche Entera 1L', 'LAC-010', 'unidad', 1.10, 2, 2);

INSERT INTO warehouses (name, address, city, manager_name)
VALUES
    ('Centro Logístico Norte', 'Av. Belgrano 1200', 'Buenos Aires', 'Soledad Díaz'),
    ('Deposito Atlántico', 'Ruta 8 km 35', 'Montevideo', 'Jorge Funes');

INSERT INTO inventories (product_id, warehouse_id, quantity_on_hand, safety_stock, last_restocked)
VALUES
    (1, 1, 320, 150, '2024-02-10'),
    (1, 2, 120, 80, '2024-02-08'),
    (2, 1, 480, 200, '2024-02-11');

INSERT INTO customers (name, contact_name, phone, email, city, country)
VALUES
    ('Mercado San Martín', 'Ana Rojas', '+54 11 4444-7890', 'compras@msanmartin.com', 'Buenos Aires', 'Argentina'),
    ('Tiendas La Rivera', 'Marco Ortiz', '+598 2 777-5600', 'contacto@larivera.uy', 'Punta del Este', 'Uruguay');

INSERT INTO orders (customer_id, order_date, required_date, status, total_amount)
VALUES
    (1, '2024-02-12', '2024-02-15', 'confirmado', 845.00),
    (2, '2024-02-14', '2024-02-18', 'pendiente', 210.00);

INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount)
VALUES
    (1, 1, 200, 3.25, 0.00),
    (1, 2, 150, 1.10, 0.00),
    (2, 2, 180, 1.10, 5.00);

INSERT INTO shipments (order_id, warehouse_id, shipped_at, estimated_delivery, delivery_status, tracking_number)
VALUES
    (1, 1, '2024-02-13 09:30:00', '2024-02-15', 'entregado', 'ARG-000123'),
    (2, 2, NULL, '2024-02-18', 'pendiente', 'UY-000987');
