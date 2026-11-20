FactoryBot.define do
  factory :exchange_rate do
    currency_code { "USD" }
    rate_to_usd { "1.000000" }
  end

  factory :employee do
    exchange_rate
    sequence(:employee_code) { |n| "ACME-#{n}" }
    sequence(:email) { |n| "employee-#{n}@example.test" }
    full_name { "Taylor Morgan" }
    country_code { "US" }
    department { "Engineering" }
    job_title { "Software Engineer" }
    job_level { "L3" }
    annual_salary { "60000.25" }
    hired_on { Date.new(2025, 1, 15) }
  end

  factory :salary_revision do
    employee
    exchange_rate { employee.exchange_rate }
    new_salary { employee.annual_salary }
    effective_date { employee.hired_on }
    reason { "initial" }
  end
end
