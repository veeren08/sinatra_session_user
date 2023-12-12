# frozen_string_literal: true

require_relative 'config/environment'

# Log all requests in apache format
use Rack::CommonLogger

# Parse params from POST request
use Rack::JSONBodyParser

use Rack::MethodOverride

run ApplicationController
