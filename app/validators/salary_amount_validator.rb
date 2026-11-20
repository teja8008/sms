class SalaryAmountValidator < ActiveModel::EachValidator
  EXCLUSIVE_LIMIT = 1_000_000_000_000

  def validate_each(record, attribute, value)
    # Active Record can round excess fractional digits before validation.
    input = record.read_attribute_before_type_cast(attribute)
    amount = BigDecimal(input.to_s, exception: false)

    if !amount&.finite? || !amount.positive?
      record.errors.add(attribute, "must be a positive amount")
    elsif amount >= EXCLUSIVE_LIMIT
      record.errors.add(attribute, "must fit in 12 whole digits")
    elsif amount != value
      record.errors.add(attribute, "must have at most two decimal places")
    end
  end
end
