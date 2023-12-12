# frozen_string_literal: true

module Sinatra
  module ViewHelper
    def current_user
      @current_user ||= User.find(id: session[:user_id]) if session[:user_id]
    end
  end
  helpers ViewHelper
end
