class SalaryRevision < ApplicationRecord
  belongs_to :employee, inverse_of: :salary_revisions
  belongs_to :exchange_rate, foreign_key: :currency_code

  validates :reason, :effective_date, presence: true
  validates :previous_salary, salary_amount: true, allow_nil: true
  validates :new_salary, salary_amount: true

  def readonly?
    persisted? || super
  end

  def delete
    raise ActiveRecord::ReadOnlyRecord, "Salary revisions are append-only" if persisted?

    super
  end
end
