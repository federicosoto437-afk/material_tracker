class Supplier < ApplicationRecord
  has_many :materials, dependent: :restrict_with_error

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
end