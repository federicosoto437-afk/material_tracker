class Stock < ApplicationRecord
  belongs_to :material
  belongs_to :warehouse

  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :material_id, uniqueness: { scope: :warehouse_id }
end