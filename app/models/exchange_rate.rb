class ExchangeRate < ApplicationRecord
  self.primary_key = :currency_code

  validates :currency_code, format: { with: /\A[A-Z]{3}\z/ }, uniqueness: true
  validates :rate_to_usd, numericality: { greater_than: 0 }
end
