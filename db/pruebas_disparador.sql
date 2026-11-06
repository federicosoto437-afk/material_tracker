BEGIN;

INSERT INTO suppliers (name, created_at, updated_at) VALUES ('Proveedor de prueba', NOW(), NOW()) RETURNING id AS proveedor \gset
INSERT INTO materials (sku, name, unit, unit_cost, min_stock, supplier_id, created_at, updated_at) VALUES ('PRB-01', 'Material de prueba', 'pieza', 10, 5, :proveedor, NOW(), NOW()) RETURNING id AS material \gset
INSERT INTO warehouses (name, location, created_at, updated_at) VALUES ('Almacen de prueba', 'Docker', NOW(), NOW()) RETURNING id AS almacen \gset
INSERT INTO users (name, email, password_digest, role, created_at, updated_at) VALUES ('Usuario de prueba', 'prueba@constructify.com', 'x', 'almacenista', NOW(), NOW()) RETURNING id AS usuario \gset

\echo '1. INSERT: entrada de 100'
INSERT INTO movements (material_id, warehouse_id, user_id, movement_type, quantity, created_at, updated_at) VALUES (:material, :almacen, :usuario, 'entrada', 100, NOW(), NOW()) RETURNING id AS entrada \gset
SELECT quantity AS stock FROM stocks WHERE material_id = :material AND warehouse_id = :almacen;

\echo '2. INSERT: salida de 30'
INSERT INTO movements (material_id, warehouse_id, user_id, movement_type, quantity, created_at, updated_at) VALUES (:material, :almacen, :usuario, 'salida', 30, NOW(), NOW()) RETURNING id AS salida \gset
SELECT quantity AS stock FROM stocks WHERE material_id = :material AND warehouse_id = :almacen;

\echo '3. UPDATE: la salida cambia de 30 a 45'
UPDATE movements SET quantity = 45 WHERE id = :salida;
SELECT quantity AS stock FROM stocks WHERE material_id = :material AND warehouse_id = :almacen;

\echo '4. DELETE: se elimina la salida'
DELETE FROM movements WHERE id = :salida;
SELECT quantity AS stock FROM stocks WHERE material_id = :material AND warehouse_id = :almacen;

\echo '5. Salida de 500, mayor al stock'
SAVEPOINT antes_del_error;
INSERT INTO movements (material_id, warehouse_id, user_id, movement_type, quantity, created_at, updated_at) VALUES (:material, :almacen, :usuario, 'salida', 500, NOW(), NOW());
ROLLBACK TO SAVEPOINT antes_del_error;
SELECT quantity AS stock FROM stocks WHERE material_id = :material AND warehouse_id = :almacen;

\echo '6. Bitacora de auditoria'
SELECT operacion, movement_id, cantidad_anterior, cantidad_nueva, usuario_bd FROM inventario_auditoria WHERE material_id = :material ORDER BY id;

ROLLBACK;