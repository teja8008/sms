require "rails_helper"

RSpec.describe "Payroll database constraints" do
  it "rejects duplicate employee codes even when validations are bypassed" do
    employee = create(:employee)
    duplicate = build(:employee, employee_code: employee.employee_code, exchange_rate: employee.exchange_rate)

    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "rejects duplicate employee emails even when validations are bypassed" do
    employee = create(:employee)
    duplicate = build(:employee, email: employee.email, exchange_rate: employee.exchange_rate)

    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "rejects a currency with no matching exchange rate" do
    employee = create(:employee)

    expect { employee.update_columns(currency_code: "INR") }.to raise_error(ActiveRecord::InvalidForeignKey)
  end

  it "rejects a zero salary even when validations are bypassed" do
    employee = create(:employee)

    expect { employee.update_columns(annual_salary: 0) }.to raise_error(ActiveRecord::StatementInvalid, /employees_salary_positive/)
  end

  it "rejects PostgreSQL NaN as salary" do
    employee = create(:employee)

    expect {
      Employee.where(id: employee.id).update_all("annual_salary = 'NaN'::numeric")
    }.to raise_error(ActiveRecord::StatementInvalid, /employees_salary_positive/)
  end

  it "allows at most one opening revision per employee" do
    employee = create(:salary_revision).employee

    expect { create(:salary_revision, employee: employee) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "protects revision history when an employee is deleted" do
    employee = create(:salary_revision).employee

    expect { employee.delete }.to raise_error(ActiveRecord::InvalidForeignKey)
  end
end
