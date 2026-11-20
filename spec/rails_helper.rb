ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
abort("RSpec needs RAILS_ENV=test") unless Rails.env.test?

require "rspec/rails"

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.use_transactional_fixtures = true
end
