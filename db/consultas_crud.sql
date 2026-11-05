INSERT INTO suppliers (name, contact_name, phone, email, created_at, updated_at)
VALUES ('Block y Tabique SA', 'Marta Diaz', '555-222-3333', 'ventas@blocktab.com', NOW(), NOW());

INSERT INTO materials (sku, name, unit, unit_cost, min_stock, supplier_id, created_at, updated_at)
VALUES ('BLK-15', 'Block de concreto 15 cm', 'pieza', 18.50, 1000, (SELECT id FROM suppliers WHERE name = 'Block y Tabique SA'), NOW(), NOW());

SELECT m.sku, m.name AS material, w.name AS almacen, s.quantity, m.unit
FROM stocks s
JOIN materials m ON m.id = s.material_id
JOIN warehouses w ON w.id = s.warehouse_id
ORDER BY m.sku, w.name;

SELECT m.sku, m.name AS material, COALESCE(SUM(s.quantity), 0) AS total, m.min_stock
FROM materials m
LEFT JOIN stocks s ON s.material_id = m.id
GROUP BY m.id
HAVING COALESCE(SUM(s.quantity), 0) < m.min_stock
ORDER BY total;

SELECT w.name AS almacen, SUM(s.quantity * m.unit_cost) AS valor_inventario
FROM stocks s
JOIN materials m ON m.id = s.material_id
JOIN warehouses w ON w.id = s.warehouse_id
GROUP BY w.name
ORDER BY valor_inventario DESC;

SELECT mv.created_at, mv.movement_type, m.name AS material, w.name AS almacen, mv.quantity, u.name AS usuario
FROM movements mv
JOIN materials m ON m.id = mv.material_id
JOIN warehouses w ON w.id = mv.warehouse_id
JOIN users u ON u.id = mv.user_id
ORDER BY mv.created_at DESC
LIMIT 10;

UPDATE materials
SET unit_cost = 19.75, updated_at = NOW()
WHERE sku = 'BLK-15';

BEGIN;
INSERT INTO movements (material_id, warehouse_id, user_id, movement_type, quantity, notes, created_at, updated_at)
VALUES (
  (SELECT id FROM materials WHERE sku = 'CEM-50'),
  (SELECT id FROM warehouses WHERE name = 'Almacen Central'),
  (SELECT id FROM users WHERE email = 'almacen@constructify.com'),
  'salida', 50, 'Envio a obra', NOW(), NOW()
);
UPDATE stocks
SET quantity = quantity - 50, updated_at = NOW()
WHERE material_id = (SELECT id FROM materials WHERE sku = 'CEM-50')
  AND warehouse_id = (SELECT id FROM warehouses WHERE name = 'Almacen Central');
COMMIT;

DELETE FROM suppliers WHERE name = 'Cementos del Norte';

DELETE FROM materials WHERE sku = 'BLK-15';
DELETE FROM suppliers WHERE name = 'Block y Tabique SA';