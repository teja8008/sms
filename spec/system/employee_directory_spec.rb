require "rails_helper"

RSpec.describe "Employee directory", type: :system do
  before do
    driven_by :selenium, using: :headless_chrome do |options|
      options.binary = ENV.fetch("CHROME_BIN") if ENV["CHROME_BIN"].present?

      if ENV["CI"] == "true"
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
      end
    end
  end

  it "finds and opens an employee while preserving the directory search" do
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

  it "shows field errors and refreshes pay and history after a successful edit" do
    employee = create(:salary_revision).employee
    visit root_path
    click_button employee.full_name
    click_button "Edit salary"
    fill_in "New annual salary", with: "60000.25"
    fill_in "Reason", with: "Annual review"
    click_button "Save salary"

    expect(page).to have_text("must differ from the current salary")
    expect(page).to have_field("Reason", with: "Annual review")

    fill_in "New annual salary", with: "61000.25"
    click_button "Save salary"

    expect(page).to have_text("Salary updated.")
    within("[aria-label='Employee details']") { expect(page).to have_text("USD 61,000.25") }
    within("[aria-label='Salary revisions table']") do
      expect(page).to have_text("Annual review")
      expect(page).to have_text("USD 60,000.25")
    end

    click_button "Back to directory"
    expect(page).to have_text("USD 61,000.25")
  end

  it "offers to reload salary when another edit has already been saved" do
    opening = create(:salary_revision)
    employee = opening.employee
    visit root_path
    click_button employee.full_name
    click_button "Edit salary"

    UpdateEmployeeSalary.new(employee, {
      annual_salary: "62000.25", reason: "Other editor", effective_date: Date.current.iso8601,
      expected_revision_id: opening.id
    }).call
    fill_in "New annual salary", with: "61000.25"
    fill_in "Reason", with: "Annual review"
    click_button "Save salary"

    expect(page).to have_text("This salary changed after you opened the profile.")
    expect(page).to have_field("Reason", with: "Annual review", disabled: true)
    click_button "Reload salary"

    within("[aria-label='Employee details']") { expect(page).to have_text("USD 62,000.25") }
    within("[aria-label='Salary revisions table']") { expect(page).to have_text("Other editor") }
    expect(page).to have_no_button("Save salary")
  end
end
