require "rails_helper"

RSpec.describe "Compensation analytics", type: :request do
  it "returns active report data with decimal strings over JSON" do
    usd = create(:exchange_rate)
    rates = create(:exchange_rate, currency_code: "INR", rate_to_usd: "0.012")
    create(:employee, exchange_rate: usd, annual_salary: "60000.00")
    create(:employee, exchange_rate: rates, country_code: "IN", annual_salary: "2000000.00")

    get "/api/v1/analytics", params: { country: "IN", department: "Engineering" }

    expect(response).to have_http_status(:ok)
    expect(response.headers.fetch("Cache-Control")).to include("no-store")
    summary = response.parsed_body.fetch("summary")
    expect(summary).to include("headcount" => 1, "currency_code" => "INR")
    expect(summary.fetch("annual_spend")).to be_a(String)
    expect(BigDecimal(summary.fetch("annual_spend"))).to eq(2_000_000)
    expect(response.parsed_body.fetch("country_breakdown").pluck("country_code")).to eq([ "IN" ])
  end

  it "returns zero spend, no median, and empty breakdowns for a filter with no active employees" do
    create(:employee, status: "inactive")

    get "/api/v1/analytics", params: { country: "US" }

    expect(response).to have_http_status(:ok)
    report = response.parsed_body
    expect(report.fetch("summary")).to include("headcount" => 0, "median_salary" => nil)
    expect(BigDecimal(report.fetch("summary").fetch("annual_spend"))).to eq(0)
    expect(report.fetch("country_breakdown")).to be_empty
    expect(report.fetch("department_level_ranges")).to be_empty
  end
end
