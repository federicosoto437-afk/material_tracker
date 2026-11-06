class Movement < ApplicationRecord
  TYPES = %w[entrada salida ajuste].freeze

  belongs_to :material
  belongs_to :warehouse
  belongs_to :user

  validates :movement_type, inclusion: { in: TYPES }
  validates :quantity, numericality: { other_than: 0 }
  validates :quantity, numericality: { greater_than: 0 }, unless: -> { movement_type == "ajuste" }
end