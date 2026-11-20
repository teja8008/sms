require "rails_helper"
require_relative "../../db/seeds/demo_compensation_seed"

RSpec.describe DemoCompensationSeed do
  it "creates the configured rates and an opening revision for each employee" do
    described_class.run(employee_count: 12, batch_size: 5)

    expect(ExchangeRate.order(:currency_code).pluck(:currency_code, :rate_to_usd)).to eq([
      [ "CAD", BigDecimal("0.740000") ],
      [ "EUR", BigDecimal("1.080000") ],
      [ "GBP", BigDecimal("1.270000") ],
      [ "INR", BigDecimal("0.012000") ],
      [ "SGD", BigDecimal("0.740000") ],
      [ "USD", BigDecimal("1.000000") ]
    ])
    expect(Employee.distinct.pluck(:country_code)).to match_array(%w[CA DE GB IN SG US])
    expect(Employee.count).to eq(12)
    expect(SalaryRevision.count).to eq(12)

    Employee.includes(:salary_revisions).each do |employee|
      expect(employee.salary_revisions.size).to eq(1)
      revision = employee.salary_revisions.first
      expect(revision.attributes.symbolize_keys).to include(
        previous_salary: nil,
        new_salary: employee.annual_salary,
        currency_code: employee.currency_code,
        effective_date: employee.hired_on,
        reason: "initial"
      )
    end
  end

  it "generates identical employee data from an empty database" do
    attributes = %i[employee_code full_name email country_code department job_title job_level annual_salary currency_code status hired_on]
    first_run = nil

    Employee.transaction(requires_new: true) do
      described_class.run(employee_count: 12, batch_size: 5)
      first_run = Employee.order(:employee_code).pluck(*attributes)
      raise ActiveRecord::Rollback
    end

    described_class.run(employee_count: 12, batch_size: 5)

    expect(Employee.order(:employee_code).pluck(*attributes)).to eq(first_run)
  end

  it "preserves edited pay and its history when run again" do
    described_class.run(employee_count: 6, batch_size: 3)
    employee = Employee.order(:employee_code).first
    previous_salary = employee.annual_salary
    updated_salary = previous_salary + 1_000

    Employee.transaction do
      employee.update!(annual_salary: updated_salary)
      employee.salary_revisions.create!(previous_salary: previous_salary, new_salary: updated_salary,
        currency_code: employee.currency_code, effective_date: employee.hired_on + 1, reason: "Pay review")
    end
    history_ids = employee.salary_revisions.order(:id).ids

    described_class.run(employee_count: 7, batch_size: 3)
    described_class.run(employee_count: 7, batch_size: 3)

    expect(Employee.count).to eq(7)
    expect(SalaryRevision.count).to eq(8)
    expect(employee.reload.annual_salary).to eq(updated_salary)
    expect(employee.salary_revisions.order(:id).ids).to eq(history_ids)
  end

  it "rolls back the employee batch when its opening revisions cannot be written" do
    allow(SalaryRevision).to receive(:insert_all!).and_raise(ActiveRecord::StatementInvalid, "seed write failed")

    expect do
      described_class.run(employee_count: 6, batch_size: 3)
    end.to raise_error(ActiveRecord::StatementInvalid, "seed write failed")
    expect(Employee.count).to eq(0)
    expect(SalaryRevision.count).to eq(0)
  end
end
