# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_04_174659) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "inventario", id: :serial, force: :cascade do |t|
    t.string "sku", limit: 20, null: false
    t.string "nombre", limit: 100, null: false
    t.string "unidad", limit: 20, null: false
    t.decimal "cantidad", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "actualizado_en", precision: nil, default: -> { "now()" }, null: false

    t.check_constraint "cantidad >= 0::numeric", name: "inventario_cantidad_check"
    t.unique_constraint ["sku"], name: "inventario_sku_key"
  end

  create_table "materials", force: :cascade do |t|
    t.string "sku", null: false
    t.string "name", null: false
    t.string "unit", null: false
    t.decimal "unit_cost", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "min_stock", precision: 12, scale: 2, default: "0.0", null: false
    t.bigint "supplier_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sku"], name: "index_materials_on_sku", unique: true
    t.index ["supplier_id"], name: "index_materials_on_supplier_id"
    t.check_constraint "min_stock >= 0::numeric", name: "materials_min_stock_check"
    t.check_constraint "unit_cost >= 0::numeric", name: "materials_unit_cost_check"
  end

  create_table "movements", force: :cascade do |t|
    t.bigint "material_id", null: false
    t.bigint "warehouse_id", null: false
    t.bigint "user_id", null: false
    t.string "movement_type", null: false
    t.decimal "quantity", precision: 12, scale: 2, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["material_id"], name: "index_movements_on_material_id"
    t.index ["user_id"], name: "index_movements_on_user_id"
    t.index ["warehouse_id"], name: "index_movements_on_warehouse_id"
    t.check_constraint "movement_type::text = ANY (ARRAY['entrada'::character varying, 'salida'::character varying, 'ajuste'::character varying]::text[])", name: "movements_type_check"
    t.check_constraint "quantity > 0::numeric OR movement_type::text = 'ajuste'::text AND quantity <> 0::numeric", name: "movements_quantity_check"
  end

  create_table "stocks", force: :cascade do |t|
    t.bigint "material_id", null: false
    t.bigint "warehouse_id", null: false
    t.decimal "quantity", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["material_id", "warehouse_id"], name: "index_stocks_on_material_id_and_warehouse_id", unique: true
    t.index ["material_id"], name: "index_stocks_on_material_id"
    t.index ["warehouse_id"], name: "index_stocks_on_warehouse_id"
    t.check_constraint "quantity >= 0::numeric", name: "stocks_quantity_check"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name", null: false
    t.string "contact_name"
    t.string "phone"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "almacenista", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.check_constraint "role::text = ANY (ARRAY['admin'::character varying, 'almacenista'::character varying, 'supervisor'::character varying]::text[])", name: "users_role_check"
  end

  create_table "warehouses", force: :cascade do |t|
    t.string "name", null: false
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "materials", "suppliers"
  add_foreign_key "movements", "materials"
  add_foreign_key "movements", "users"
  add_foreign_key "movements", "warehouses"
  add_foreign_key "stocks", "materials"
  add_foreign_key "stocks", "warehouses"
end
