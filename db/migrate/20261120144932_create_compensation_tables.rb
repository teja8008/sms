class CreateCompensationTables < ActiveRecord::Migration[8.1]
  def change
    create_table :exchange_rates, id: :string, primary_key: :currency_code, limit: 3 do |t|
      t.decimal :rate_to_usd, precision: 12, scale: 6, null: false

      t.check_constraint "currency_code ~ '^[A-Z]{3}$'", name: "exchange_rates_currency_code_format"
      t.check_constraint "rate_to_usd > 0 AND rate_to_usd <> 'NaN'::numeric", name: "exchange_rates_rate_positive"
    end

    create_table :employees do |t|
      t.string :employee_code, null: false
      t.string :full_name, null: false
      t.string :email, null: false
      t.string :country_code, limit: 2, null: false
      t.string :department, null: false
      t.string :job_title, null: false
      t.string :job_level, null: false
      t.decimal :annual_salary, precision: 14, scale: 2, null: false
      t.string :currency_code, limit: 3, null: false
      t.string :status, default: "active", null: false
      t.date :hired_on, null: false
      t.timestamps

      t.index :employee_code, unique: true
      t.index :email, unique: true
      t.index :status, name: "idx_employees_on_status"
      t.index [ :country_code, :department, :job_level ], name: "idx_employees_on_country_dept_level"
      t.foreign_key :exchange_rates, column: :currency_code, primary_key: :currency_code
      t.check_constraint "annual_salary > 0 AND annual_salary <> 'NaN'::numeric", name: "employees_salary_positive"
      t.check_constraint "status IN ('active', 'inactive')", name: "employees_status_valid"
      t.check_constraint "job_level IN ('L1', 'L2', 'L3', 'L4', 'L5', 'L6')", name: "employees_job_level_valid"
    end

    create_table :salary_revisions do |t|
      t.references :employee, null: false, foreign_key: true, index: { name: "idx_salary_revisions_on_employee_id" }
      t.decimal :previous_salary, precision: 14, scale: 2
      t.decimal :new_salary, precision: 14, scale: 2, null: false
      t.string :currency_code, limit: 3, null: false
      t.string :reason, null: false
      t.date :effective_date, null: false
      t.datetime :created_at, null: false

      t.index :employee_id, unique: true, where: "previous_salary IS NULL", name: "idx_salary_revisions_one_opening"
      t.foreign_key :exchange_rates, column: :currency_code, primary_key: :currency_code
      t.check_constraint "previous_salary > 0 AND previous_salary <> 'NaN'::numeric", name: "salary_revisions_previous_positive"
      t.check_constraint "new_salary > 0 AND new_salary <> 'NaN'::numeric", name: "salary_revisions_new_positive"
    end
  end
end
