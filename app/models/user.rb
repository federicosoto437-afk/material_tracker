class User < ApplicationRecord
  ROLES = %w[admin almacenista supervisor].freeze

  has_secure_password
  has_many :movements, dependent: :restrict_with_error

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: ROLES }
end