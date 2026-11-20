# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_20_144932) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "employees", force: :cascade do |t|
    t.string "employee_code", null: false
    t.string "full_name", null: false
    t.string "email", null: false
    t.string "country_code", limit: 2, null: false
    t.string "department", null: false
    t.string "job_title", null: false
    t.string "job_level", null: false
    t.decimal "annual_salary", precision: 14, scale: 2, null: false
    t.string "currency_code", limit: 3, null: false
    t.string "status", default: "active", null: false
    t.date "hired_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_code", "department", "job_level"], name: "idx_employees_on_country_dept_level"
    t.index ["email"], name: "index_employees_on_email", unique: true
    t.index ["employee_code"], name: "index_employees_on_employee_code", unique: true
    t.index ["status"], name: "idx_employees_on_status"
    t.check_constraint "annual_salary > 0::numeric AND annual_salary <> 'NaN'::numeric", name: "employees_salary_positive"
    t.check_constraint "job_level::text = ANY (ARRAY['L1'::character varying, 'L2'::character varying, 'L3'::character varying, 'L4'::character varying, 'L5'::character varying, 'L6'::character varying]::text[])", name: "employees_job_level_valid"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying, 'inactive'::character varying]::text[])", name: "employees_status_valid"
  end

  create_table "exchange_rates", primary_key: "currency_code", id: { type: :string, limit: 3 }, force: :cascade do |t|
    t.decimal "rate_to_usd", precision: 12, scale: 6, null: false
    t.check_constraint "currency_code::text ~ '^[A-Z]{3}$'::text", name: "exchange_rates_currency_code_format"
    t.check_constraint "rate_to_usd > 0::numeric AND rate_to_usd <> 'NaN'::numeric", name: "exchange_rates_rate_positive"
  end

  create_table "salary_revisions", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.decimal "previous_salary", precision: 14, scale: 2
    t.decimal "new_salary", precision: 14, scale: 2, null: false
    t.string "currency_code", limit: 3, null: false
    t.string "reason", null: false
    t.date "effective_date", null: false
    t.datetime "created_at", null: false
    t.index ["employee_id"], name: "idx_salary_revisions_on_employee_id"
    t.index ["employee_id"], name: "idx_salary_revisions_one_opening", unique: true, where: "(previous_salary IS NULL)"
    t.check_constraint "new_salary > 0::numeric AND new_salary <> 'NaN'::numeric", name: "salary_revisions_new_positive"
    t.check_constraint "previous_salary > 0::numeric AND previous_salary <> 'NaN'::numeric", name: "salary_revisions_previous_positive"
  end

  add_foreign_key "employees", "exchange_rates", column: "currency_code", primary_key: "currency_code"
  add_foreign_key "salary_revisions", "employees"
  add_foreign_key "salary_revisions", "exchange_rates", column: "currency_code", primary_key: "currency_code"
end
