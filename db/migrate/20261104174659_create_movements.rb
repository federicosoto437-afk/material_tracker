class CreateMovements < ActiveRecord::Migration[8.1]
  def change
    create_table :movements do |t|
      t.references :material, null: false, foreign_key: true
      t.references :warehouse, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :movement_type, null: false
      t.decimal :quantity, precision: 12, scale: 2, null: false
      t.text :notes
      t.timestamps
    end
    add_check_constraint :movements, "movement_type IN ('entrada', 'salida', 'ajuste')", name: "movements_type_check"
    add_check_constraint :movements, "quantity > 0 OR (movement_type = 'ajuste' AND quantity <> 0)", name: "movements_quantity_check"
  end
end	