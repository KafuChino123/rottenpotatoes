# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
abort("Refusing to run specs in production") if Rails.env.production?
require "rspec/rails"
require "webmock/rspec"
require "capybara/rspec"
require "database_cleaner/active_record"

WebMock.disable_net_connect!(allow_localhost: true)
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.before(:suite) { DatabaseCleaner.clean_with(:truncation) }
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.order = :random
end
