class Employee < ApplicationRecord
  belongs_to :exchange_rate, foreign_key: :currency_code
  has_many :salary_revisions, inverse_of: :employee

  validates :employee_code, :email, presence: true, uniqueness: true
  validates :full_name, :department, :job_title, :hired_on, presence: true
  validates :country_code, format: { with: /\A[A-Z]{2}\z/ }
  validates :job_level, inclusion: { in: %w[L1 L2 L3 L4 L5 L6] }
  validates :status, inclusion: { in: %w[active inactive] }
  validates :annual_salary, salary_amount: true
end
