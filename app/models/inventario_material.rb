class InventarioMaterial < ApplicationRecord
  self.table_name = "inventario_materiales"

  scope :stock_bajo, -> { where(estado: "Stock bajo") }
  scope :en_almacen, ->(nombre) { where(almacen: nombre) }

  def readonly?
    true
  end
end