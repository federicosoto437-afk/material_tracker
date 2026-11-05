class Material < ApplicationRecord
  belongs_to :supplier
  has_many :stocks, dependent: :restrict_with_error
  has_many :warehouses, through: :stocks
  has_many :movements, dependent: :restrict_with_error

  validates :sku, presence: true, uniqueness: true
  validates :name, :unit, presence: true
  validates :unit_cost, :min_stock, numericality: { greater_than_or_equal_to: 0 }

  def total_stock
    stocks.sum(:quantity)
  end
end