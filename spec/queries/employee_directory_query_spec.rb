require "rails_helper"

RSpec.describe EmployeeDirectoryQuery do
  let(:usd) { create(:exchange_rate) }
  let(:inr) { create(:exchange_rate, currency_code: "INR", rate_to_usd: "0.012") }

  it "matches a name, email, or employee code without regard to case" do
    employee = create(:employee, exchange_rate: usd, full_name: "Jamie Chen",
      email: "person@example.test", employee_code: "ACME-042")
    create(:employee, exchange_rate: usd, full_name: "Avery Morgan")

    %w[chEN PERSON acme-042].each do |term|
      expect(described_class.new(q: term).call.fetch(:employees)).to eq([ employee ])
    end
  end

  it "treats wildcard characters in a search as literal text" do
    employee = create(:employee, exchange_rate: usd, full_name: "Taylor 100%")
    create(:employee, exchange_rate: usd, full_name: "Taylor 1000")

    expect(described_class.new(q: "100%").call.fetch(:employees)).to eq([ employee ])
  end

  it "combines country, department, and level filters" do
    employee = create(:employee, exchange_rate: inr, country_code: "IN", department: "Engineering", job_level: "L3")
    create(:employee, exchange_rate: inr, country_code: "IN", department: "Engineering", job_level: "L2")
    create(:employee, exchange_rate: inr, country_code: "IN", department: "Sales", job_level: "L3")
    create(:employee, exchange_rate: usd, country_code: "US", department: "Engineering", job_level: "L3")

    result = described_class.new(country: "in", department: "Engineering", job_level: "L3").call

    expect(result.fetch(:employees)).to eq([ employee ])
    expect(result.fetch(:pagination).fetch(:total_count)).to eq(1)
  end

  it "paginates employees with the same name in stable ID order" do
    first = create(:employee, exchange_rate: usd, full_name: "Alex Morgan")
    second = create(:employee, exchange_rate: usd, full_name: "Alex Morgan")
    create(:employee, exchange_rate: usd, full_name: "Zoe Rivera")

    expect(described_class.new(per_page: 1).call.fetch(:employees)).to eq([ first ])
    result = described_class.new(page: 2, per_page: 1).call
    expect(result.fetch(:employees)).to eq([ second ])
    expect(result.fetch(:pagination)).to eq(page: 2, per_page: 1, total_count: 3, total_pages: 3)
  end

  it "sorts on an allowed column and returns an empty page past the results" do
    first = create(:employee, exchange_rate: usd, employee_code: "ACME-001")
    second = create(:employee, exchange_rate: usd, employee_code: "ACME-002")

    result = described_class.new(sort: "employee_code", direction: "desc").call
    expect(result.fetch(:employees)).to eq([ second, first ])
    expect(described_class.new(page: 2).call.fetch(:employees)).to be_empty
  end
end
