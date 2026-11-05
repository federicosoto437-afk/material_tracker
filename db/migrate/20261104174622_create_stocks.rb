class CreateStocks < ActiveRecord::Migration[8.1]
  def change
    create_table :stocks do |t|
      t.references :material, null: false, foreign_key: true
      t.references :warehouse, null: false, foreign_key: true
      t.decimal :quantity, precision: 12, scale: 2, null: false, default: 0
      t.timestamps
    end
    add_index :stocks, [:material_id, :warehouse_id], unique: true
    add_check_constraint :stocks, "quantity >= 0", name: "stocks_quantity_check"
  end
end
