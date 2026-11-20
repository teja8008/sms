require "rails_helper"

RSpec.describe Employee, type: :model do
  it "stores salary to the cent and defaults to active" do
    employee = create(:employee).reload

    expect(employee.annual_salary).to eq(BigDecimal("60000.25"))
    expect(employee.status).to eq("active")
    expect(employee.exchange_rate.currency_code).to eq("USD")
  end

  it "rejects a duplicate code and email in model validation" do
    employee = create(:employee)
    duplicate = build(:employee, exchange_rate: employee.exchange_rate,
      employee_code: employee.employee_code, email: employee.email)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors.of_kind?(:employee_code, :taken)).to be(true)
    expect(duplicate.errors.of_kind?(:email, :taken)).to be(true)
  end

  it "rejects a currency without an exchange rate" do
    employee = build(:employee, exchange_rate: nil, currency_code: "INR")

    expect(employee).not_to be_valid
    expect(employee.errors[:exchange_rate]).to be_present
  end

  it "rejects salary amounts that would be rounded or cannot fit in the column" do
    employee = build(:employee)

    [ "60000.251", "0", "-0.01", "NaN", "1000000000000.00" ].each do |amount|
      employee.annual_salary = amount

      expect(employee).not_to be_valid
      expect(employee.errors[:annual_salary]).to be_present
    end
  end

  it "rejects an unknown status and job level" do
    employee = build(:employee, status: "pending", job_level: "L9")

    expect(employee).not_to be_valid
    expect(employee.errors.attribute_names).to include(:status, :job_level)
  end
end
