class DemoCompensationSeed
  EMPLOYEE_COUNT = 10_000
  BATCH_SIZE = 500
  RANDOM_SEED = 42
  REFERENCE_DATE = Date.new(2026, 1, 1)

  # Country, currency, USD per local unit, and entry-level annual pay.
  MARKETS = [
    [ "US", "USD", "1.000000", 65_000 ],
    [ "IN", "INR", "0.012000", 900_000 ],
    [ "GB", "GBP", "1.270000", 36_000 ],
    [ "DE", "EUR", "1.080000", 44_000 ],
    [ "CA", "CAD", "0.740000", 62_000 ],
    [ "SG", "SGD", "0.740000", 58_000 ]
  ].freeze

  ROLES = [
    [ "Engineering", "Software Engineer" ],
    [ "Product", "Product Specialist" ],
    [ "Sales", "Account Executive" ],
    [ "Operations", "Operations Specialist" ],
    [ "Finance", "Financial Analyst" ],
    [ "People", "People Operations Specialist" ]
  ].freeze

  FIRST_NAMES = %w[Aditi Alex Amara Avery Daniel Elena Hana Jamie Kai Leila Maya Nora Priya Ravi Sam Taylor].freeze
  LAST_NAMES = %w[Chen Clarke Dubois Fischer Gomez Hassan Iyer Kim Lee Mehta Morgan Patel Rivera Singh Tan Weber].freeze

  class << self
    def run(employee_count: EMPLOYEE_COUNT, batch_size: BATCH_SIZE)
      random = Random.new(RANDOM_SEED)
      rates = MARKETS.map do |_country, currency_code, rate_to_usd, _base_salary|
        { currency_code: currency_code, rate_to_usd: rate_to_usd }
      end
      ExchangeRate.insert_all(rates, unique_by: :currency_code, returning: false)

      1.upto(employee_count).each_slice(batch_size) do |numbers|
        employees = numbers.map { |number| employee_attributes(number, random) }
        insert_batch(employees)
      end
    end

    private

    def employee_attributes(number, random)
      country_code, currency_code, _rate, base_salary = MARKETS[(number - 1) % MARKETS.length]
      department, job_title = ROLES.sample(random: random)
      level = random.rand(1..6)
      salary_percent = 80 + (level - 1) * 30 + random.rand(0..40)
      serial = format("%05d", number)

      {
        employee_code: "ACME-#{serial}",
        full_name: "#{FIRST_NAMES.sample(random: random)} #{LAST_NAMES.sample(random: random)}",
        email: "demo-#{serial}@example.test",
        country_code: country_code,
        department: department,
        job_title: job_title,
        job_level: "L#{level}",
        annual_salary: base_salary * salary_percent / 100,
        currency_code: currency_code,
        status: random.rand(20).zero? ? "inactive" : "active",
        hired_on: REFERENCE_DATE - random.rand(0..3_650)
      }
    end

    def insert_batch(employees)
      Employee.transaction do
        inserted = Employee.insert_all(employees, unique_by: :employee_code,
          returning: %w[id annual_salary currency_code hired_on])
        revisions = inserted.map do |employee|
          {
            employee_id: employee.fetch("id"),
            new_salary: employee.fetch("annual_salary"),
            currency_code: employee.fetch("currency_code"),
            reason: "initial",
            effective_date: employee.fetch("hired_on")
          }
        end
        SalaryRevision.insert_all!(revisions, returning: false) if revisions.any?
      end
    end
  end
end
