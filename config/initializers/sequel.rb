# frozen_string_literal: true

require 'logger'
require 'sequel'
require 'yaml'

database_url = ENV.fetch('DATABASE_URL', nil)

if database_url
  DB = Sequel.connect(database_url)
else
  config = YAML.load_file('config/database.yml')
  DB_CONFIG = config.fetch(ENV['RACK_ENV'] || 'development')
  DB = Sequel.connect(DB_CONFIG)
end

# Enable logging of SQL queries.
DB.loggers << Logger.new($stdout) if ENV['RACK_ENV'] == 'development'

Sequel::Model.strict_param_setting = false
