# frozen_string_literal: true

class User < Sequel::Model
  plugin :validation_helpers

  def before_create
    self.uuid = SecureRandom.uuid
  end

  def validate
    super
    validates_presence :email
    validates_unique :email
    validates_format URI::MailTo::EMAIL_REGEXP, :email unless email.to_s.empty?
  end
end
