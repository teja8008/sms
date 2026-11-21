ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
abort("RSpec needs RAILS_ENV=test") unless Rails.env.test?

require "rspec/rails"

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.use_transactional_fixtures = true

  config.before(type: :system) do
    driven_by :selenium, using: :headless_chrome do |options|
      options.binary = ENV.fetch("CHROME_BIN") if ENV["CHROME_BIN"].present?

      if ENV["CI"] == "true"
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
      end
    end
  end
end
