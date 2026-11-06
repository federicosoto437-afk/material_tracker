class CrearDisparadorInventario < ActiveRecord::Migration[8.1]
  def up
    create_table :inventario_auditoria do |t|
      t.bigint :movement_id
      t.references :material, null: false, foreign_key: true
      t.references :warehouse, null: false, foreign_key: true
      t.string :operacion, null: false
      t.decimal :cantidad_anterior, precision: 12, scale: 2, null: false
      t.decimal :cantidad_nueva, precision: 12, scale: 2, null: false
      t.string :usuario_bd, null: false, default: -> { "CURRENT_USER" }
      t.datetime :registrado_en, null: false, default: -> { "CURRENT_TIMESTAMP" }
    end
    add_check_constraint :inventario_auditoria, "operacion IN ('INSERT', 'UPDATE', 'DELETE')", name: "inventario_auditoria_operacion_check"
    add_index :inventario_auditoria, [:material_id, :registrado_en]

    execute <<~SQL
      CREATE OR REPLACE FUNCTION efecto_movimiento(p_tipo text, p_cantidad numeric)
      RETURNS numeric
      LANGUAGE sql
      IMMUTABLE
      AS $$
        SELECT CASE p_tipo WHEN 'salida' THEN -p_cantidad ELSE p_cantidad END;
      $$;
    SQL

    execute <<~SQL
      CREATE OR REPLACE FUNCTION ajustar_stock(
        p_material_id bigint,
        p_warehouse_id bigint,
        p_delta numeric,
        p_operacion text,
        p_movement_id bigint
      )
      RETURNS void
      LANGUAGE plpgsql
      AS $$
      DECLARE
        v_anterior numeric;
        v_nueva numeric;
      BEGIN
        IF p_delta = 0 THEN
          RETURN;
        END IF;

        INSERT INTO stocks (material_id, warehouse_id, quantity, created_at, updated_at)
        VALUES (p_material_id, p_warehouse_id, 0, NOW(), NOW())
        ON CONFLICT (material_id, warehouse_id) DO NOTHING;

        SELECT quantity INTO v_anterior
        FROM stocks
        WHERE material_id = p_material_id AND warehouse_id = p_warehouse_id
        FOR UPDATE;

        v_nueva := v_anterior + p_delta;

        IF v_nueva < 0 THEN
          RAISE EXCEPTION 'Stock insuficiente: hay % y se requieren %', v_anterior, -p_delta
            USING ERRCODE = 'check_violation';
        END IF;

        UPDATE stocks
        SET quantity = v_nueva, updated_at = NOW()
        WHERE material_id = p_material_id AND warehouse_id = p_warehouse_id;

        INSERT INTO inventario_auditoria (movement_id, material_id, warehouse_id, operacion, cantidad_anterior, cantidad_nueva)
        VALUES (p_movement_id, p_material_id, p_warehouse_id, p_operacion, v_anterior, v_nueva);
      END;
      $$;
    SQL

    execute <<~SQL
      CREATE OR REPLACE FUNCTION aplicar_movimiento_a_stock()
      RETURNS trigger
      LANGUAGE plpgsql
      AS $$
      BEGIN
        IF TG_OP = 'INSERT' THEN
          PERFORM ajustar_stock(NEW.material_id, NEW.warehouse_id, efecto_movimiento(NEW.movement_type, NEW.quantity), TG_OP, NEW.id);
        ELSIF TG_OP = 'DELETE' THEN
          PERFORM ajustar_stock(OLD.material_id, OLD.warehouse_id, -efecto_movimiento(OLD.movement_type, OLD.quantity), TG_OP, OLD.id);
        ELSIF OLD.material_id = NEW.material_id AND OLD.warehouse_id = NEW.warehouse_id THEN
          PERFORM ajustar_stock(NEW.material_id, NEW.warehouse_id, efecto_movimiento(NEW.movement_type, NEW.quantity) - efecto_movimiento(OLD.movement_type, OLD.quantity), TG_OP, NEW.id);
        ELSE
          PERFORM ajustar_stock(OLD.material_id, OLD.warehouse_id, -efecto_movimiento(OLD.movement_type, OLD.quantity), TG_OP, OLD.id);
          PERFORM ajustar_stock(NEW.material_id, NEW.warehouse_id, efecto_movimiento(NEW.movement_type, NEW.quantity), TG_OP, NEW.id);
        END IF;
        RETURN NULL;
      END;
      $$;
    SQL

    execute <<~SQL
      CREATE TRIGGER trg_movimientos_actualizan_stock
      AFTER INSERT OR DELETE OR UPDATE OF material_id, warehouse_id, movement_type, quantity
      ON movements
      FOR EACH ROW
      EXECUTE FUNCTION aplicar_movimiento_a_stock();
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS trg_movimientos_actualizan_stock ON movements;"
    execute "DROP FUNCTION IF EXISTS aplicar_movimiento_a_stock();"
    execute "DROP FUNCTION IF EXISTS ajustar_stock(bigint, bigint, numeric, text, bigint);"
    execute "DROP FUNCTION IF EXISTS efecto_movimiento(text, numeric);"
    drop_table :inventario_auditoria
  end
end