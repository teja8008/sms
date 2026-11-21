module Api
  module V1
    class EmployeesController < ActionController::API
      DIRECTORY_FIELDS = %i[id employee_code full_name email country_code department job_title job_level currency_code status].freeze
      REVISION_FIELDS = %i[id currency_code reason effective_date created_at].freeze

      before_action { response.headers["Cache-Control"] = "no-store" }
      rescue_from EmployeeDirectoryQuery::InvalidParameters do |error|
        render json: { error: error.message }, status: :bad_request
      end
      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: "Employee not found." }, status: :not_found
      end

      def index
        filters = params.permit(:q, :country, :department, :job_level, :sort, :direction, :page, :per_page)
        result = EmployeeDirectoryQuery.new(**filters.to_h.symbolize_keys).call

        render json: result.merge(employees: result.fetch(:employees).map { |employee| employee_payload(employee) })
      end

      def show
        employee = Employee.find(params[:id])
        revisions = employee.salary_revisions.order(effective_date: :desc, created_at: :desc, id: :desc).to_a
        profile = employee_payload(employee).merge(
          "hired_on" => employee.hired_on.iso8601,
          "latest_revision_id" => revisions.first&.id,
          "salary_revisions" => revisions.map { |revision| revision_payload(revision) }
        )

        render json: { employee: profile }
      end

      private

      def employee_payload(employee)
        employee.as_json(only: DIRECTORY_FIELDS).merge("annual_salary" => employee.annual_salary.to_s("F"))
      end

      def revision_payload(revision)
        revision.as_json(only: REVISION_FIELDS).merge(
          "previous_salary" => revision.previous_salary&.to_s("F"),
          "new_salary" => revision.new_salary.to_s("F")
        )
      end
    end
  end
end
