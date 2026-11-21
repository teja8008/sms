require "rails_helper"
require "timeout"

RSpec.describe UpdateEmployeeSalary, type: :model do
  it "rolls back current pay when writing the revision fails" do
    opening = create(:salary_revision)
    employee = opening.employee
    history = employee.salary_revisions
    allow(employee).to receive(:salary_revisions).and_return(history)
    allow(history).to receive(:create!) do
      expect(Employee.find(employee.id).annual_salary).to eq(BigDecimal("61000.25"))
      raise ActiveRecord::StatementInvalid, "Revision write failed"
    end
    attributes = {
      annual_salary: "61000.25", reason: "Annual review", effective_date: opening.effective_date.iso8601,
      expected_revision_id: opening.id
    }

    expect { described_class.new(employee, attributes).call }
      .to raise_error(ActiveRecord::StatementInvalid, "Revision write failed")
    expect(employee.reload.annual_salary).to eq(BigDecimal("60000.25"))
    expect(SalaryRevision.where(employee_id: employee.id).ids).to eq([ opening.id ])
  end

  context "with separate database connections" do
    self.use_transactional_tests = false

    it "lets exactly one concurrent editor save with the same revision token" do
      rate = create(:exchange_rate, currency_code: "CAD", rate_to_usd: "0.74")
      employee = create(:employee, exchange_rate: rate, country_code: "CA")
      opening = create(:salary_revision, employee: employee)
      employee_id = employee.id
      ready = Queue.new
      start = Queue.new
      workers = %w[61000.25 62000.25].map do |amount|
        Thread.new do
          Employee.connection_pool.with_connection do
            editor = Employee.find(employee_id)
            ready << true
            start.pop
            described_class.new(editor, {
              annual_salary: amount, reason: "Annual review", effective_date: opening.effective_date.iso8601,
              expected_revision_id: opening.id
            }).call
            :saved
          end
        rescue described_class::StaleRevision
          :stale
        end
      end
      Timeout.timeout(10) do
        workers.size.times { ready.pop }
        workers.size.times { start << true }
        expect(workers.map(&:value)).to match_array([ :saved, :stale ])
      end

      revisions = SalaryRevision.where(employee_id: employee_id).order(:id)
      expect(revisions.count).to eq(2)
      expect(revisions.last.new_salary).to eq(Employee.find(employee_id).annual_salary)
    ensure
      workers&.each { |worker| worker.kill.join if worker.alive? }
      if employee
        SalaryRevision.where(employee_id: employee.id).delete_all
        Employee.where(id: employee.id).delete_all
      end
      ExchangeRate.where(currency_code: rate.currency_code).delete_all if rate
    end
  end
end
