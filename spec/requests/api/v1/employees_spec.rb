require "rails_helper"

RSpec.describe "Employees API", type: :request do
  let(:usd) { create(:exchange_rate) }

  it "returns paged employees, decimal salaries, and available filter values" do
    employee = create(:employee, exchange_rate: usd, full_name: "Taylor Morgan", department: "Engineering")
    create(:employee, exchange_rate: usd, full_name: "Avery Chen", department: "Finance")

    get "/api/v1/employees", params: { q: "taylor", country: "US", job_level: "L3", per_page: 1 }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to match(
      "employees" => [ a_hash_including("id" => employee.id, "annual_salary" => "60000.25", "currency_code" => "USD") ],
      "pagination" => { "page" => 1, "per_page" => 1, "total_count" => 1, "total_pages" => 1 },
      "filter_options" => { "countries" => [ "US" ], "departments" => %w[Engineering Finance], "job_levels" => [ "L3" ] }
    )
  end

  it "returns an empty result when no employee matches" do
    get "/api/v1/employees", params: { q: "does not exist" }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("employees")).to be_empty
    expect(response.parsed_body.fetch("pagination").fetch("total_count")).to eq(0)
  end

  it "returns a JSON error for invalid sorting or pagination" do
    [ { sort: "annual_salary" }, { direction: "sideways" }, { page: "0" }, { per_page: "101" } ].each do |invalid_params|
      get "/api/v1/employees", params: invalid_params

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body.fetch("error")).to be_present
    end
  end

  it "returns the profile and reads the latest revision from the ordered history" do
    opening = create(:salary_revision)
    timestamp = Time.utc(2025, 7, 1, 12)
    first_change = create(:salary_revision, employee: opening.employee, previous_salary: opening.new_salary,
      new_salary: "61000.25", reason: "Pay review", effective_date: timestamp.to_date, created_at: timestamp)
    latest = create(:salary_revision, employee: opening.employee, previous_salary: first_change.new_salary,
      new_salary: "62000.25", reason: "Adjustment", effective_date: timestamp.to_date, created_at: timestamp)

    get "/api/v1/employees/#{opening.employee_id}"

    expect(response).to have_http_status(:ok)
    profile = response.parsed_body.fetch("employee")
    expect(profile).to include("id" => opening.employee_id, "latest_revision_id" => latest.id,
      "hired_on" => opening.employee.hired_on.iso8601)
    expect(profile.fetch("salary_revisions").pluck("id")).to eq([ latest.id, first_change.id, opening.id ])
    expect(profile.fetch("salary_revisions").first).to include("previous_salary" => "61000.25", "new_salary" => "62000.25")
    expect(profile.fetch("salary_revisions").last.fetch("previous_salary")).to be_nil
  end

  it "returns null for the latest revision when the employee has no history" do
    employee = create(:employee, exchange_rate: usd)

    get "/api/v1/employees/#{employee.id}"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("employee")).to include("latest_revision_id" => nil, "salary_revisions" => [])
  end

  it "returns a JSON 404 for a missing employee" do
    get "/api/v1/employees/999999"

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.fetch("error")).to eq("Employee not found.")
  end
end
