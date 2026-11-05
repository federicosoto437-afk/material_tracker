INSERT INTO categories (name) VALUES ('Cementos'), ('Aceros'), ('Agregados');
INSERT INTO units (code, name) VALUES ('BTO', 'Bulto'), ('PZA', 'Pieza'), ('M3', 'Metro cubico');
INSERT INTO suppliers (name, contact_name, phone) VALUES ('Cementos del Norte', 'Ana Torres', '555-123-4567'), ('Aceros Industriales', 'Jorge Lopez', '555-987-6543');
INSERT INTO users (name, email, password_digest, role) VALUES ('Carlos Ruiz', 'almacen@constructify.com', 'hash_de_prueba', 'almacenista');
INSERT INTO projects (name, client_name, status, start_date) VALUES ('Torre Norte', 'Grupo Habitat', 'activa', '2026-09-01');
INSERT INTO warehouses (name, location, project_id) VALUES ('Almacen Central', 'Austin, TX', NULL), ('Almacen Torre Norte', 'Round Rock, TX', 1);
INSERT INTO materials (sku, name, category_id, unit_id, supplier_id, unit_cost, min_stock) VALUES ('CEM-50', 'Cemento gris 50 kg', 1, 1, 1, 185.50, 100), ('VAR-38', 'Varilla corrugada 3/8', 2, 2, 2, 142.00, 200);
INSERT INTO stocks (material_id, warehouse_id, quantity) VALUES (1, 1, 380), (1, 2, 120), (2, 1, 150);
INSERT INTO movements (material_id, warehouse_id, user_id, movement_type, quantity, notes) VALUES (1, 2, 1, 'entrada', 120, 'Envio a obra');

SELECT p.name AS obra, w.name AS almacen, m.sku, m.name AS material, c.name AS categoria, s.quantity, u.code AS unidad
FROM stocks s
JOIN materials m ON m.id = s.material_id
JOIN categories c ON c.id = m.category_id
JOIN units u ON u.id = m.unit_id
JOIN warehouses w ON w.id = s.warehouse_id
LEFT JOIN projects p ON p.id = w.project_id
ORDER BY w.name, m.sku;

INSERT INTO materials (sku, name, category_id, unit_id, supplier_id) VALUES ('ERR-01', 'Proveedor inexistente', 1, 1, 99);
DELETE FROM categories WHERE name = 'Cementos';
INSERT INTO stocks (material_id, warehouse_id, quantity) VALUES (1, 1, 10);