class Movement < ApplicationRecord
  TYPES = %w[entrada salida ajuste].freeze

  belongs_to :material
  belongs_to :warehouse
  belongs_to :user

  validates :movement_type, inclusion: { in: TYPES }
  validates :quantity, numericality: { other_than: 0 }
  validates :quantity, numericality: { greater_than: 0 }, unless: -> { movement_type == "ajuste" }

  after_create :apply_to_stock

  private

  def apply_to_stock
    stock = Stock.lock.find_or_create_by!(material: material, warehouse: warehouse)
    stock.quantity += signed_quantity
    stock.save!
  end

  def signed_quantity
    movement_type == "salida" ? -quantity : quantity
  end
end