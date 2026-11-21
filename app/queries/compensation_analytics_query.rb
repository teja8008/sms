class CompensationAnalyticsQuery
  def initialize(country: nil, department: nil)
    @country = country.to_s.strip.upcase.presence
    @department = department.to_s.strip.presence
  end

  def call
    active_employees = Employee.where(status: "active")
    pay = active_employees
      .where({ country_code: @country, department: @department }.compact)
      .joins(:exchange_rate)
      .select(:country_code, :currency_code, :department, :job_level, :annual_salary,
        "employees.annual_salary * exchange_rates.rate_to_usd AS usd_salary")
    countries = active_employees.select(:country_code).distinct.order(:country_code)
    departments = active_employees.select(:department).distinct.order(:department)

    sql = <<~SQL
      WITH pay AS (#{pay.to_sql}),
        presentation AS (
          SELECT CASE WHEN #{@country.present?} AND COUNT(DISTINCT currency_code) = 1
            THEN MIN(currency_code) END AS local_currency
          FROM pay
        ),
        reported_pay AS (
          SELECT department, job_level,
            COALESCE(local_currency, 'USD') AS currency_code,
            CASE WHEN local_currency IS NULL THEN usd_salary ELSE annual_salary END AS amount
          FROM pay CROSS JOIN presentation
        ),
        summary AS (
          SELECT COUNT(*) AS headcount,
            (SELECT COALESCE(local_currency, 'USD') FROM presentation) AS currency_code,
            COALESCE(SUM(amount), 0)::text AS annual_spend,
            (#{median("amount")})::text AS median_salary
          FROM reported_pay
        ),
        country_breakdown AS (
          SELECT country_code, currency_code, COUNT(*) AS headcount,
            SUM(annual_salary)::text AS annual_spend,
            (#{median("annual_salary")})::text AS median_salary,
            SUM(usd_salary)::text AS annual_spend_usd,
            (#{median("usd_salary")})::text AS median_salary_usd
          FROM pay
          GROUP BY country_code, currency_code
        ),
        department_level_ranges AS (
          SELECT department, job_level, currency_code, COUNT(*) AS headcount,
            MIN(amount)::text AS min_salary,
            (#{median("amount")})::text AS median_salary,
            MAX(amount)::text AS max_salary
          FROM reported_pay
          GROUP BY department, job_level, currency_code
        )
      SELECT json_build_object(
        'summary', (SELECT row_to_json(summary) FROM summary),
        'country_breakdown', (
          SELECT COALESCE(json_agg(country_breakdown ORDER BY country_code, currency_code), '[]'::json)
          FROM country_breakdown
        ),
        'department_level_ranges', (
          SELECT COALESCE(json_agg(department_level_ranges ORDER BY department, job_level), '[]'::json)
          FROM department_level_ranges
        ),
        'filter_options', json_build_object(
          'countries', ARRAY(#{countries.to_sql}),
          'departments', ARRAY(#{departments.to_sql})
        )
      )::text
    SQL

    Employee.connection_pool.with_connection { |connection| JSON.parse(connection.select_value(sql)) }
  end

  private

  def median(column)
    # Ascending and descending percentiles select the two middle values as numerics.
    <<~SQL.squish
      (percentile_disc(0.5) WITHIN GROUP (ORDER BY #{column}) +
        percentile_disc(0.5) WITHIN GROUP (ORDER BY #{column} DESC)) / 2
    SQL
  end
end
