require "rails_helper"

RSpec.describe ExchangeRate, type: :model do
  it "uses the currency code as its key and preserves the decimal rate" do
    create(:exchange_rate, currency_code: "INR", rate_to_usd: "0.012345")

    expect(described_class.find("INR").rate_to_usd).to eq(BigDecimal("0.012345"))
  end

  it "rejects malformed currency codes and nonpositive rates" do
    rate = build(:exchange_rate, currency_code: "us", rate_to_usd: 0)

    expect(rate).not_to be_valid
    expect(rate.errors.attribute_names).to include(:currency_code, :rate_to_usd)
  end
end
