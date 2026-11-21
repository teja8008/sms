class EmployeeDirectoryQuery
  class InvalidParameters < ArgumentError; end

  SORT_COLUMNS = {
    "name" => :full_name,
    "employee_code" => :employee_code,
    "department" => :department,
    "job_level" => :job_level
  }.freeze
  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100

  def initialize(q: nil, country: nil, department: nil, job_level: nil, sort: nil, direction: nil, page: nil, per_page: nil)
    @search = q.to_s.strip.presence
    @filters = {
      country_code: country.to_s.strip.upcase.presence,
      department: department.to_s.strip.presence,
      job_level: job_level.to_s.strip.upcase.presence
    }.compact
    @sort_column = SORT_COLUMNS[sort.presence || "name"]
    @direction = direction.presence || "asc"
    @page = positive_integer(page, default: 1, field: "page")
    @per_page = positive_integer(per_page, default: DEFAULT_PER_PAGE, field: "per_page")

    raise InvalidParameters, "Unknown sort field." unless @sort_column
    raise InvalidParameters, "Direction must be asc or desc." unless %w[asc desc].include?(@direction)
    raise InvalidParameters, "per_page must be at most #{MAX_PER_PAGE}." if @per_page > MAX_PER_PAGE
  end

  def call
    scope = filtered_employees
    total_count = scope.count
    offset = (@page - 1) * @per_page
    employees = if offset < total_count
      scope.order(@sort_column => @direction, id: :asc).limit(@per_page).offset(offset).to_a
    else
      []
    end

    {
      employees: employees,
      pagination: { page: @page, per_page: @per_page, total_count: total_count, total_pages: total_count.ceildiv(@per_page) },
      filter_options: {
        countries: Employee.distinct.order(:country_code).pluck(:country_code),
        departments: Employee.distinct.order(:department).pluck(:department),
        job_levels: Employee.distinct.order(:job_level).pluck(:job_level)
      }
    }
  end

  private

  def filtered_employees
    scope = Employee.where(@filters)
    return scope unless @search

    term = "%#{Employee.sanitize_sql_like(@search)}%"
    scope.where("full_name ILIKE :term OR email ILIKE :term OR employee_code ILIKE :term", term: term)
  end

  def positive_integer(value, default:, field:)
    return default if value.blank?

    number = Integer(value.to_s, 10, exception: false)
    raise InvalidParameters, "#{field} must be a positive integer." unless number&.positive?

    number
  end
end
