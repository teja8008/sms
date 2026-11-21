require "rails_helper"

RSpec.describe "Employee directory", type: :system do
  it "finds and opens an employee while preserving the directory search" do
    driven_by :selenium, using: :headless_chrome do |options|
      options.binary = ENV.fetch("CHROME_BIN") if ENV["CHROME_BIN"].present?

      if ENV["CI"] == "true"
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
      end
    end

    employee = create(:salary_revision).employee
    create(:employee, exchange_rate: employee.exchange_rate, full_name: "Avery Chen", department: "Finance")

    visit root_path

    expect(page).to have_css("#app h1", text: "Employee directory")
    expect(page).to have_text("Avery Chen")
    fill_in "Search employees", with: employee.employee_code
    click_button "Search"
    select "Engineering", from: "Department"
    expect(page).to have_no_text("Avery Chen")

    within("tbody tr", text: employee.employee_code) do
      click_button employee.full_name
    end

    expect(page).to have_css("h1", text: employee.full_name)
    expect(page).to have_text("Salary history")
    expect(page).to have_text("Opening salary")
    expect(page).to have_text("USD 60,000.25")

    click_button "Back to directory"

    expect(page).to have_field("Search employees", with: employee.employee_code)
    expect(page).to have_select("Department", selected: "Engineering")
    expect(page).to have_no_text("Avery Chen")
  end
end
