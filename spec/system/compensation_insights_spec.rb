require "rails_helper"

RSpec.describe "Compensation insights", type: :system do
  it "filters the charts in local currency and updates them after a salary edit" do
    us_employee = create(:employee, full_name: "Jamie Chen", annual_salary: "60000.00")
    create(:salary_revision, employee: us_employee)
    inr = create(:exchange_rate, currency_code: "INR", rate_to_usd: "0.012")
    create(:employee, exchange_rate: inr, country_code: "IN", full_name: "Priya Singh", annual_salary: "2000000.00")

    visit root_path
    click_link "Insights"
    expect(page).to have_current_path("/insights")

    within("[aria-label='Compensation summary']") do
      expect(page).to have_text("USD 84,000.00")
      expect(page).to have_text("USD 42,000.00")
    end
    within("[aria-labelledby='insights-spend-title']") do
      expect(page).to have_css("li:first-child", text: "United States")
      expect(page).to have_text("60K")
      expect(page).to have_text("24K")
    end
    within("[aria-labelledby='insights-range-title']") { expect(page).to have_text("42K") }

    select "India", from: "Country"
    select "Engineering", from: "Department"

    expect(page).to have_current_path("/insights?country=IN&department=Engineering")
    page.refresh
    expect(page).to have_select("Country", selected: "India")
    expect(page).to have_select("Department", selected: "Engineering")
    within("[aria-label='Compensation summary']") { expect(page).to have_text("INR 2,000,000.00") }
    within("[aria-labelledby='insights-spend-title']") do
      expect(page).to have_text("INR")
      expect(page).to have_text("2M")
      expect(page).to have_no_text("United States")
    end
    find("summary", text: "View detailed breakdown").click
    within("[aria-label='Country breakdown']") do
      expect(page).to have_text("INR 2,000,000.00")
      expect(page).to have_no_text("United States")
    end

    select "All countries", from: "Country"
    click_link "Employees"
    click_link us_employee.full_name
    click_button "Edit salary"
    fill_in "New annual salary", with: "61000.00"
    fill_in "Reason", with: "Annual review"
    click_button "Save salary"
    expect(page).to have_text("Salary updated.")

    click_link "Insights"

    expect(page).to have_select("Department", selected: "Engineering")
    within("[aria-label='Compensation summary']") do
      expect(page).to have_text("USD 85,000.00")
      expect(page).to have_text("USD 42,500.00")
    end
    within("[aria-labelledby='insights-spend-title']") { expect(page).to have_text("61K") }
    within("[aria-labelledby='insights-range-title']") { expect(page).to have_text("42.5K") }
  end

  it "lets HR compare another department and handles filters with no matching employees" do
    usd = create(:exchange_rate)
    create(:employee, exchange_rate: usd, department: "Engineering", annual_salary: "60000.00")
    create(:employee, exchange_rate: usd, department: "Engineering", annual_salary: "80000.00")
    inr = create(:exchange_rate, currency_code: "INR", rate_to_usd: "0.012")
    create(:employee, department: "Sales", country_code: "IN", exchange_rate: inr, annual_salary: "2000000.00")

    visit "/insights"

    within("[aria-labelledby='insights-range-title']") do
      expect(page).to have_select("Compare levels in", selected: "Engineering")
      expect(page).to have_text("70K")
      select "Sales", from: "Compare levels in"
      expect(page).to have_text("24K")
    end
    within("[aria-label='Compensation summary']") { expect(page).to have_text("USD 164,000.00") }

    select "India", from: "Country"
    select "Engineering", from: "Department"
    expect(page).to have_text("No active employees match these filters.")
    expect(page).to have_no_text("Annual spend by country")

    click_button "Clear filters"
    within("[aria-labelledby='insights-range-title']") do
      expect(page).to have_select("Compare levels in", selected: "Sales")
      expect(page).to have_text("24K")
    end

    page.current_window.resize_to(390, 900)
    expect(page.evaluate_script(<<~JS)).to be(true)
      (() => {
        const spend = document.querySelector('[aria-labelledby="insights-spend-title"]').getBoundingClientRect();
        const range = document.querySelector('[aria-labelledby="insights-range-title"]').getBoundingClientRect();
        return range.top >= spend.bottom && document.documentElement.scrollWidth <= window.innerWidth;
      })()
    JS
  end
end
