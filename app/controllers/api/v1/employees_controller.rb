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
        profile = Employee.transaction do
          # Read pay and its revision token together while salary writes are blocked.
          employee = Employee.lock("FOR SHARE").find(params[:id])
          revisions = employee.salary_revisions.newest_first.to_a
          latest = revisions.first
          employee_payload(employee).merge(
            "hired_on" => employee.hired_on.iso8601,
            "latest_revision_id" => latest&.id,
            "salary_effective_dates" => {
              "min" => (latest&.effective_date || employee.hired_on).iso8601,
              "max" => Date.current.iso8601
            },
            "salary_revisions" => revisions.map { |revision| revision_payload(revision) }
          )
        end

        render json: { employee: profile }
      end

      def update_salary
        unless request.media_type == "application/json"
          return render json: { error: "Send the salary change as JSON." }, status: :unsupported_media_type
        end

        employee = Employee.find(params[:id])
        attributes = ActionController::Parameters.new(request.request_parameters)
          .permit(:annual_salary, :reason, :effective_date, :expected_revision_id).to_h.symbolize_keys
        revision = UpdateEmployeeSalary.new(employee, attributes).call

        render json: { salary_revision: revision_payload(revision) }
      rescue UpdateEmployeeSalary::InvalidChange => error
        render json: { error: error.message, fields: error.fields }, status: :unprocessable_content
      rescue UpdateEmployeeSalary::StaleRevision => error
        render json: { error: error.message }, status: :conflict
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
