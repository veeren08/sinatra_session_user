# frozen_string_literal: true

require 'bundler'
require 'sinatra/base'

ENV['RACK_ENV'] ||= 'development'

Bundler.require :default, ENV['RACK_ENV'].to_sym

require_relative '../config/initializers/init'
require_relative '../app/helpers/init'
# require_relative '../app/mailers/sendgrid_mailer'

require_all 'app'
