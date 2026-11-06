class InventarioAuditoria < ApplicationRecord
  self.table_name = "inventario_auditoria"

  belongs_to :material
  belongs_to :warehouse

  def readonly?
    !new_record?
  end
end