class CrearFuncionesNivelInventario < ActiveRecord::Migration[8.1]
  def up
    add_index :movements, [:material_id, :warehouse_id, :created_at], name: "idx_movements_material_almacen_fecha"

    execute <<~SQL
      CREATE OR REPLACE FUNCTION nivel_inventario(
        p_material_id bigint,
        p_warehouse_id bigint DEFAULT NULL,
        p_hasta timestamp DEFAULT NULL
      )
      RETURNS numeric
      LANGUAGE plpgsql
      STABLE
      AS $$
      DECLARE
        v_nivel numeric;
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM materials WHERE id = p_material_id) THEN
          RAISE EXCEPTION 'El material % no existe', p_material_id USING ERRCODE = 'no_data_found';
        END IF;

        SELECT COALESCE(SUM(CASE mv.movement_type WHEN 'salida' THEN -mv.quantity ELSE mv.quantity END), 0)
        INTO v_nivel
        FROM movements mv
        WHERE mv.material_id = p_material_id
          AND (p_warehouse_id IS NULL OR mv.warehouse_id = p_warehouse_id)
          AND (p_hasta IS NULL OR mv.created_at <= p_hasta);

        RETURN v_nivel;
      END;
      $$;
    SQL

    execute <<~SQL
      CREATE OR REPLACE FUNCTION niveles_inventario(p_warehouse_id bigint DEFAULT NULL)
      RETURNS TABLE (
        material_id bigint,
        sku text,
        material text,
        almacen_id bigint,
        almacen text,
        entradas numeric,
        salidas numeric,
        ajustes numeric,
        nivel numeric,
        stock_registrado numeric,
        diferencia numeric
      )
      LANGUAGE sql
      STABLE
      AS $$
        SELECT
          mt.id,
          mt.sku::text,
          mt.name::text,
          w.id,
          w.name::text,
          COALESCE(SUM(mv.quantity) FILTER (WHERE mv.movement_type = 'entrada'), 0),
          COALESCE(SUM(mv.quantity) FILTER (WHERE mv.movement_type = 'salida'), 0),
          COALESCE(SUM(mv.quantity) FILTER (WHERE mv.movement_type = 'ajuste'), 0),
          SUM(CASE mv.movement_type WHEN 'salida' THEN -mv.quantity ELSE mv.quantity END),
          COALESCE(s.quantity, 0),
          SUM(CASE mv.movement_type WHEN 'salida' THEN -mv.quantity ELSE mv.quantity END) - COALESCE(s.quantity, 0)
        FROM movements mv
        JOIN materials mt ON mt.id = mv.material_id
        JOIN warehouses w ON w.id = mv.warehouse_id
        LEFT JOIN stocks s ON s.material_id = mv.material_id AND s.warehouse_id = mv.warehouse_id
        WHERE p_warehouse_id IS NULL OR mv.warehouse_id = p_warehouse_id
        GROUP BY mt.id, mt.sku, mt.name, w.id, w.name, s.quantity
        ORDER BY mt.sku, w.name;
      $$;
    SQL
  end

  def down
    execute "DROP FUNCTION IF EXISTS niveles_inventario(bigint);"
    execute "DROP FUNCTION IF EXISTS nivel_inventario(bigint, bigint, timestamp);"
    remove_index :movements, name: "idx_movements_material_almacen_fecha"
  end
end