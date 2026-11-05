class Warehouse < ApplicationRecord
  has_many :stocks, dependent: :restrict_with_error
  has_many :materials, through: :stocks
  has_many :movements, dependent: :restrict_with_error

  validates :name, presence: true
end