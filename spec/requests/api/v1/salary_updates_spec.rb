require "rails_helper"

RSpec.describe "Employee salary updates", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:opening) { create(:salary_revision) }
  let(:employee) { opening.employee }
  let(:path) { "/api/v1/employees/#{employee.id}/salary" }
  let(:attributes) do
    { annual_salary: "61000.25", reason: "Annual review", effective_date: "2026-03-15", expected_revision_id: opening.id }
  end

  around do |example|
    travel_to(Time.utc(2026, 3, 15, 12)) { example.run }
  end

  it "saves the new pay and appends exactly one revision" do
    expect do
      patch path, params: attributes, as: :json
    end.to change { employee.salary_revisions.count }.from(1).to(2)

    expect(response).to have_http_status(:ok)
    expect(employee.reload.annual_salary).to eq(BigDecimal("61000.25"))
    expect(response.parsed_body.fetch("salary_revision")).to include(
      "previous_salary" => "60000.25", "new_salary" => "61000.25", "reason" => "Annual review",
      "effective_date" => "2026-03-15", "currency_code" => "USD"
    )
    expect(opening.reload.new_salary).to eq(BigDecimal("60000.25"))
  end

  it "rejects unchanged, nonpositive, over-precise, and non-string amounts" do
    [ "60000.25", "0", "-1", "61000.251", "61000.250", "NaN", 61000 ].each do |amount|
      patch path, params: attributes.merge(annual_salary: amount), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("fields").fetch("annual_salary")).to be_present
    end

    expect(employee.reload.annual_salary).to eq(BigDecimal("60000.25"))
    expect(employee.salary_revisions.count).to eq(1)
  end

  it "requires a reason and an explicit revision token" do
    patch path, params: attributes.except(:expected_revision_id).merge(reason: "   "), as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.fetch("fields")).to include("reason", "expected_revision_id")
    expect(employee.salary_revisions.count).to eq(1)
  end

  it "rejects malformed dates and dates outside the allowed range" do
    [ "2025-01-14", "2026-03-16", "2026-02-30", "20260315" ].each do |date|
      patch path, params: attributes.merge(effective_date: date), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("fields").fetch("effective_date")).to be_present
    end

    expect(employee.salary_revisions.count).to eq(1)
  end

  it "allows the latest effective date and then uses the new revision as the token" do
    patch path, params: attributes.merge(effective_date: opening.effective_date.iso8601), as: :json

    expect(response).to have_http_status(:ok)
    new_id = response.parsed_body.fetch("salary_revision").fetch("id")
    get "/api/v1/employees/#{employee.id}"

    expect(response.parsed_body.fetch("employee")).to include(
      "latest_revision_id" => new_id,
      "salary_effective_dates" => { "min" => opening.effective_date.iso8601, "max" => "2026-03-15" }
    )
  end

  it "uses the most recent effective date as the lower bound" do
    patch path, params: attributes.merge(effective_date: "2026-03-01"), as: :json
    new_id = response.parsed_body.fetch("salary_revision").fetch("id")

    patch path, params: attributes.merge(annual_salary: "62000.25", expected_revision_id: new_id, effective_date: "2026-02-28"), as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.fetch("fields").fetch("effective_date")).to be_present
    expect(employee.reload.annual_salary).to eq(BigDecimal("61000.25"))
    expect(employee.salary_revisions.count).to eq(2)
  end

  it "rejects replayed or stale submissions without changing the saved result" do
    patch path, params: attributes, as: :json
    expect(response).to have_http_status(:ok)

    patch path, params: attributes, as: :json
    expect(response).to have_http_status(:conflict)

    patch path, params: attributes.merge(annual_salary: "62000.25"), as: :json
    expect(response).to have_http_status(:conflict)
    expect(employee.reload.annual_salary).to eq(BigDecimal("61000.25"))
    expect(employee.salary_revisions.count).to eq(2)
  end

  it "accepts an explicit null token when an employee has no revisions" do
    employee_without_history = create(:employee)
    patch "/api/v1/employees/#{employee_without_history.id}/salary",
      params: { annual_salary: "61000.25", reason: "Annual review", effective_date: "2025-01-15", expected_revision_id: nil }, as: :json

    expect(response).to have_http_status(:ok)
    expect(employee_without_history.salary_revisions.sole.previous_salary).to eq(BigDecimal("60000.25"))
  end

  it "accepts JSON bodies and returns 404 for a missing employee" do
    patch path, params: attributes
    expect(response).to have_http_status(:unsupported_media_type)

    patch "/api/v1/employees/999999/salary", params: attributes, as: :json
    expect(response).to have_http_status(:not_found)
  end
end
