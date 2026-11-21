require "rails_helper"

RSpec.describe CompensationAnalyticsQuery do
  let(:usd) { create(:exchange_rate) }
  let(:inr) { create(:exchange_rate, currency_code: "INR", rate_to_usd: "0.012") }
  let!(:us_employee) { create(:employee, exchange_rate: usd, annual_salary: "60000.00") }
  let!(:india_employee) do
    create(:employee, exchange_rate: inr, country_code: "IN", annual_salary: "2000000.00")
  end

  it "reports active headcount, USD spend, and the exact median and range across countries" do
    create(:employee, exchange_rate: usd, annual_salary: "90000.00", status: "inactive")
    report = described_class.new.call
    summary = report.fetch("summary")
    range = report.fetch("department_level_ranges").sole

    expect(summary).to include("headcount" => 2, "currency_code" => "USD")
    expect(BigDecimal(summary.fetch("annual_spend"))).to eq(84_000)
    expect(BigDecimal(summary.fetch("median_salary"))).to eq(42_000)
    expect(range).to include("department" => "Engineering", "job_level" => "L3", "headcount" => 2, "currency_code" => "USD")
    expect(range.values_at("min_salary", "median_salary", "max_salary").map { |value| BigDecimal(value) })
      .to eq([ 24_000, 42_000, 60_000 ])
  end

  it "reports local pay and USD equivalents after applying the country and department filters" do
    create(:employee, exchange_rate: inr, country_code: "IN", department: "Finance", annual_salary: "1000000.00")
    report = described_class.new(country: "in", department: "Engineering").call
    summary = report.fetch("summary")
    country = report.fetch("country_breakdown").sole
    range = report.fetch("department_level_ranges").sole

    expect(summary).to include("headcount" => 1, "currency_code" => "INR")
    expect(summary.values_at("annual_spend", "median_salary").map { |value| BigDecimal(value) }).to eq([ 2_000_000, 2_000_000 ])
    expect(country).to include("country_code" => "IN", "currency_code" => "INR")
    expect(country.values_at("annual_spend_usd", "median_salary_usd").map { |value| BigDecimal(value) }).to eq([ 24_000, 24_000 ])
    expect(range.fetch("currency_code")).to eq("INR")
    expect(report.fetch("filter_options")).to eq("countries" => %w[IN US], "departments" => %w[Engineering Finance])
  end

  it "uses USD for the all-country view even if a department only exists in one country" do
    india_employee.update!(department: "Finance")

    summary = described_class.new(department: "Finance").call.fetch("summary")

    expect(summary).to include("currency_code" => "USD", "headcount" => 1)
    expect(BigDecimal(summary.fetch("annual_spend"))).to eq(24_000)
  end

  it "keeps the half cent when averaging two middle decimal salaries" do
    create(:employee, exchange_rate: usd, department: "Finance", annual_salary: "60000.01")
    create(:employee, exchange_rate: usd, department: "Finance", annual_salary: "60000.02")

    range = described_class.new(department: "Finance").call.fetch("department_level_ranges").sole

    expect(BigDecimal(range.fetch("median_salary"))).to eq(BigDecimal("60000.015"))
  end

  it "converts totals to USD if a selected country contains multiple currencies" do
    india_employee.update!(country_code: "US")

    report = described_class.new(country: "US").call

    expect(report.fetch("summary")).to include("currency_code" => "USD", "headcount" => 2)
    expect(BigDecimal(report.fetch("summary").fetch("annual_spend"))).to eq(84_000)
    expect(report.fetch("country_breakdown").pluck("currency_code")).to eq(%w[INR USD])
  end

  it "reflects a saved raise without counting historical revisions as spend" do
    opening = create(:salary_revision, employee: us_employee)
    UpdateEmployeeSalary.new(us_employee, {
      annual_salary: "61000.00", reason: "Annual review", effective_date: opening.effective_date.iso8601,
      expected_revision_id: opening.id
    }).call

    summary = described_class.new.call.fetch("summary")

    expect(summary.fetch("headcount")).to eq(2)
    expect(BigDecimal(summary.fetch("annual_spend"))).to eq(85_000)
    expect(BigDecimal(summary.fetch("median_salary"))).to eq(42_500)
  end
end
