# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

# All app related scripts are required here.
require_relative '../config/environment'

require 'database_cleaner/sequel'
require 'factory_bot'
require 'rspec'
require 'rack/test'
require 'require_all'

# Require all controllers and models
require_all 'app/controllers'
require_all 'app/models'

# See https://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include Rack::Test::Methods

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.order = :random
  # config.profile_examples = 10

  config.before(:suite) do
    FactoryBot.find_definitions
    DatabaseCleaner[:sequel].strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before do
    next unless ENV['RACK_ENV'] == 'test'

    DatabaseCleaner.start
  end

  config.after do
    next unless ENV['RACK_ENV'] == 'test'

    DatabaseCleaner.clean
  end

  Kernel.srand config.seed
end

RSpec::Matchers.define_negated_matcher :not_change, :change
