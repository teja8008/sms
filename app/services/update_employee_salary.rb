class UpdateEmployeeSalary
  class StaleRevision < StandardError; end

  class InvalidChange < StandardError
    attr_reader :fields

    def initialize(fields)
      @fields = fields
      super("Check the salary change details.")
    end
  end

  def initialize(employee, attributes)
    @employee = employee
    @attributes = attributes
  end

  def call
    amount, reason, effective_date, revision_id = validated_inputs

    @employee.with_lock(requires_new: true) do
      latest = @employee.salary_revisions.newest_first.first
      unless latest&.id == revision_id
        raise StaleRevision, "This salary changed after you opened the profile. Reload the salary and try again."
      end

      earliest_date = latest&.effective_date || @employee.hired_on
      unless effective_date.between?(earliest_date, Date.current)
        raise InvalidChange.new(effective_date: [ "must be between #{earliest_date.iso8601} and today" ])
      end

      previous_salary = @employee.annual_salary
      if BigDecimal(amount) == previous_salary
        raise InvalidChange.new(annual_salary: [ "must differ from the current salary" ])
      end

      @employee.update!(annual_salary: amount)
      @employee.salary_revisions.create!(
        previous_salary: previous_salary,
        new_salary: @employee.annual_salary,
        currency_code: @employee.currency_code,
        reason: reason,
        effective_date: effective_date
      )
    end
  rescue ActiveRecord::RecordInvalid => error
    raise InvalidChange.new(error.record.errors.to_hash)
  end

  private

  def validated_inputs
    amount = @attributes[:annual_salary]
    reason = @attributes[:reason]
    date = parse_date(@attributes[:effective_date])
    revision_id = @attributes[:expected_revision_id]
    errors = {}

    unless amount.is_a?(String) && amount.match?(/\A-?\d+(?:\.\d{1,2})?\z/)
      errors[:annual_salary] = [ "must be a decimal string with at most two decimal places" ]
    end
    errors[:reason] = [ "is required" ] unless reason.is_a?(String) && reason.strip.present?
    errors[:effective_date] = [ "must be a valid date in YYYY-MM-DD format" ] unless date
    unless @attributes.key?(:expected_revision_id) && (revision_id.nil? || (revision_id.is_a?(Integer) && revision_id.positive?))
      errors[:expected_revision_id] = [ "must be the revision ID from the profile or null for empty history" ]
    end

    raise InvalidChange.new(errors) if errors.any?

    [ amount, reason.strip, date, revision_id ]
  end

  def parse_date(value)
    return unless value.is_a?(String) && value.match?(/\A\d{4}-\d{2}-\d{2}\z/)

    Date.iso8601(value)
  rescue Date::Error
    nil
  end
end
