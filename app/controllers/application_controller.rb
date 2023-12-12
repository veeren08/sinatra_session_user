# frozen_string_literal: true

require 'sinatra/flash'
require 'sinatra/namespace'
require 'sinatra/partial'
require 'bcrypt'
require 'sinatra'
require 'letter_opener'
require 'active_record'
require 'dotenv/load'

require_relative 'users_controller'

class ApplicationController < Sinatra::Base
  register Sinatra::Flash
  register Sinatra::Namespace
  register Sinatra::Partial

  register UsersController

  helpers Sinatra::ViewHelper

  enable :sessions

  configure :development, :test do
    db_config = YAML.load(File.read('config/database.yml'))
    ActiveRecord::Base.establish_connection(db_config['development'])
    set :delivery_method, :letter_opener
  end
  
  configure :production do
    db_config = YAML.load(File.read('config/database.yml'))
    ActiveRecord::Base.establish_connection(db_config['production'])
    set :delivery_method, :smtp
  end

  configure do
    set :public_dir, 'public'
    set :views, 'app/views'
    set :protect_from_csrf, true
    set :partial_template_engine, :erb
    set :method_override, true
    set :smtp_options, {
      address: 'smtp.gmail.com',
      port: '587',
      user_name: ENV['EMAIL_USERNAME'],
      password: ENV['EMAIL_PASSWORD'],
      enable_ssl: true, # or false, depending on your SMTP server
      authentication: :plain, # or :login or :cram_md5, depending on your SMTP server
      enable_ssl: true,
      domain: 'localhost',
      enable_starttls_auto: true  
    }
  end

  helpers do
    def base_url
      @base_url ||= ENV.fetch('BASE_URL', 'http://localhost:9292')
    end
  end

  not_found do
    status 404
    erb :'404'
  end
end
