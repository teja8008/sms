require "rails_helper"

RSpec.describe SalaryRevision, type: :model do
  it "records an opening salary on the hire date" do
    revision = create(:salary_revision)
    employee = revision.employee

    expect(employee.salary_revisions).to contain_exactly(revision)
    expect(revision.previous_salary).to be_nil
    expect(revision.new_salary).to eq(employee.annual_salary)
    expect(revision.currency_code).to eq(employee.currency_code)
    expect(revision.effective_date).to eq(employee.hired_on)
  end

  it "requires a positive new salary and an effective date and reason" do
    revision = build(:salary_revision, previous_salary: -1, new_salary: 0,
      effective_date: nil, reason: "")

    expect(revision).not_to be_valid
    expect(revision.errors.attribute_names).to include(:previous_salary, :new_salary, :effective_date, :reason)
  end

  it "allows an employee to accumulate salary changes after the opening revision" do
    opening = create(:salary_revision)
    change = create(:salary_revision, employee: opening.employee,
      previous_salary: opening.new_salary, new_salary: "61000.25",
      effective_date: opening.effective_date + 1, reason: "Annual review")

    expect(opening.employee.salary_revisions).to contain_exactly(opening, change)
  end

  it "blocks updates and deletes of a recorded revision" do
    revision = create(:salary_revision)

    expect { revision.update!(reason: "Edited") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { revision.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { revision.delete }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end
end
