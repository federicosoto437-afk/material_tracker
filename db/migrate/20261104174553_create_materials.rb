class CreateMaterials < ActiveRecord::Migration[8.1]
  def change
    create_table :materials do |t|
      t.string :sku, null: false
      t.string :name, null: false
      t.string :unit, null: false
      t.decimal :unit_cost, precision: 12, scale: 2, null: false, default: 0
      t.decimal :min_stock, precision: 12, scale: 2, null: false, default: 0
      t.references :supplier, null: false, foreign_key: true
      t.timestamps
    end
    add_index :materials, :sku, unique: true
    add_check_constraint :materials, "unit_cost >= 0", name: "materials_unit_cost_check"
    add_check_constraint :materials, "min_stock >= 0", name: "materials_min_stock_check"
  end
end
