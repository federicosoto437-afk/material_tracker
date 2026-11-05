class CrearVistaInventarioMateriales < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE VIEW inventario_materiales AS
      SELECT
        m.id AS material_id,
        m.sku,
        m.name AS material,
        m.unit AS unidad,
        sp.name AS proveedor,
        w.id AS almacen_id,
        w.name AS almacen,
        w.location AS ubicacion,
        COALESCE(s.quantity, 0) AS cantidad,
        SUM(COALESCE(s.quantity, 0)) OVER (PARTITION BY m.id) AS stock_total,
        m.min_stock AS stock_minimo,
        CASE
          WHEN SUM(COALESCE(s.quantity, 0)) OVER (PARTITION BY m.id) = 0 THEN 'Sin stock'
          WHEN SUM(COALESCE(s.quantity, 0)) OVER (PARTITION BY m.id) < m.min_stock THEN 'Stock bajo'
          ELSE 'Disponible'
        END AS estado,
        ROUND(COALESCE(s.quantity, 0) * m.unit_cost, 2) AS valor,
        s.updated_at AS actualizado_en
      FROM materials m
      JOIN suppliers sp ON sp.id = m.supplier_id
      LEFT JOIN stocks s ON s.material_id = m.id
      LEFT JOIN warehouses w ON w.id = s.warehouse_id;
    SQL
  end

  def down
    execute "DROP VIEW IF EXISTS inventario_materiales;"
  end
end