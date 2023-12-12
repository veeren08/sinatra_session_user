module UsersController
  module Helpers
    require 'bcrypt'
    include BCrypt

    def user_params
      params.slice(:email, :password, :confirm_password)
    end

    def generate_salt
      BCrypt::Engine.generate_salt
    end

    def validate_email(email)
      regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
      return regex.match?(email)
    end

    def generate_otp
      SecureRandom.random_number(1_000_000).to_s.rjust(6, '0')
    end

    def send_otp(user)
      otp = generate_otp
      user.update(otp: otp, otp_generated_at: Time.now)
    
      confirmation_link = "#{base_url}/verify_otp/#{user.uuid}"
      message = <<-MESSAGE
      Please confirm your account by clicking the following link #{user.otp}:
      #{confirmation_link}
      MESSAGE
    
      mail_data = Mail.new do
        from    ENV['EMAIL_USERNAME']
        to      user.email
        subject 'Varification Email'
        body    message
      end
    
      if settings.production?
        mail_data.delivery_method :smtp, settings.smtp_options
      else
        mail_data.delivery_method LetterOpener::DeliveryMethod, location: File.expand_path('tmp/letter_opener', __dir__)
      end
    
      mail_data.deliver!
    
      flash[:info] = 'OTP sent to your email. Please check your inbox.'
    end
    

    def verify_otp(user, entered_otp)
      return false if user.otp.nil? || user.otp_generated_at.nil?

      # Check if the OTP is still valid (not expired)
      otp_expiration_time = 1 * 60 # 1 minute in seconds
      current_time = Time.now
      otp_generated_time = user.otp_generated_at.to_time
      time_difference = current_time - otp_generated_time

      return false if time_difference > otp_expiration_time

      user.otp == entered_otp
    end

    def password_digest(new_password, salt)
      BCrypt::Engine.hash_secret(new_password, salt)
    end

    def generate_reset_token
      SecureRandom.hex(20)
    end

    def send_password_reset_email(user)
      reset_token = generate_reset_token
      user.update(reset_token: reset_token)
      reset_password_email(user)
    end

    def reset_password_email(user)
      reset_link = "#{base_url}/reset_password/#{user.reset_token}"
      message = "Please change your password by clicking the following link:\n#{reset_link}"
    
      mail_data = Mail.new do
        from    ENV['EMAIL_USERNAME']
        to      user.email
        subject settings.development? ? 'Confirmation Email' : smtp_options[:subject] || 'Confirmation Email'
        body    message
      end
    
      if settings.development?
        mail_data.delivery_method LetterOpener::DeliveryMethod, location: File.expand_path('tmp/letter_opener', __dir__)
      else
        mail_data.delivery_method :smtp, settings.smtp_options
      end
    
      mail_data.deliver!
    end
    

    def email_confirmed?
      User.find(email: params[:email]).confirmed
    end

    def authenticate(entered_password, stored_password_digest, salt)
      hashed_entered_password = BCrypt::Engine.hash_secret(entered_password, salt)
      hashed_entered_password == stored_password_digest
    end
  end

  def self.registered(app)
    app.helpers Helpers

    app.get '/signup' do
      @user = User.new
      erb :'users/signup'
    end
    
    app.post '/signup' do
      @user = User.new(user_params)
    
      if params[:password] == params[:confirm_password]
        salt = generate_salt
        @user.salt = salt
        @user.password_digest = password_digest(params[:password], salt)
    
        if validate_email(@user.email) && @user.save
          send_otp(@user) # Send OTP to the user's email
          erb :'users/verify_otp', locals: { user: @user } # Render the OTP verification page
        else
          @errors = ["Invalid email format."] if !validate_email(@user.email)
          @errors ||= @user.errors.full_messages
          erb :'users/signup'
        end
      else
        @errors = ["Password and Confirm Password do not match."]
        erb :'users/signup'
      end
    end

    app.get '/forgot_password' do
      erb :'users/forgot_password'
    end

    app.post '/forgot_password' do
      email = params[:email]
      @user = User.find(email: email)
  
      if @user
        send_password_reset_email(@user)
        flash[:success] = 'Password reset instructions sent to your email.'
        redirect '/login'
      else
        @errors = ['User with this email address not found.']
        erb :'users/forgot_password'
      end
    end

    app.get '/reset_password/:token' do
      @token = params[:token]
      erb :'users/reset_password'
    end

    app.post '/reset_password/:token' do
      @token = params[:token]
      password = params[:password]
      confirm_password = params[:confirm_password]
  
      @user = User.find(reset_token: @token)
  
      if @user && password == confirm_password
        salt = generate_salt
        @user.salt = salt
        @user.password_digest = password_digest(password, salt)
        @user.update(reset_token: nil)
  
        flash[:success] = 'Password reset successfully. You can now log in with your new password.'
        redirect '/login'
      else
        @errors = ['Invalid password reset attempt. Please try again.']
        erb :'users/reset_password'
      end
    end

    app.get '/verify_otp/:id' do
      @user = User.find(uuid: params[:id])

      if @user
        erb :'users/verify_otp', locals: { user: @user }
      else
        flash[:error] = 'Invalid user or OTP verification link.'
        redirect '/signup'
      end
    end

    app.post '/verify_otp/:id' do
      @user = User.find(id: params[:id])
      entered_otp = params[:otp]

      if @user && verify_otp(@user, entered_otp)
        @user.update(confirmed: true, otp: nil)
        flash[:success] = 'User registered and verified successfully!'
        redirect '/login'
      else
        @errors = ['Invalid OTP. Please try again.']
        erb :'users/verify_otp', locals: { user: @user }
      end
    end

    app.get '/login' do
      erb :'users/login'
    end

    app.post '/login' do
      email = params[:email]
      password = params[:password]

      @user = User.find(email: email)

      if @user
        unless email_confirmed?
          flash[:success] = 'Please confirm the email first!'
          redirect '/'
        end
      end

      if @user && authenticate(password, @user.password_digest, @user.salt)
        session[:user_id] = @user.id

        flash[:success] = 'Login successful!'
        redirect '/'
      else
        @errors = ['Invalid email or password']
        erb :'users/login'
      end
    end

    app.get '/logout' do
      session.clear
      flash[:success] = 'Logout successful!'
      redirect '/'
    end

    app.get '/confirm/:id' do
      user = User.find(uuid: params[:id])
    
      if user
        user.update(confirmed: true)
        flash[:success] = 'Account confirmed successfully!'
      else
        flash[:error] = 'Invalid confirmation link.'
      end
    
      redirect '/login'
    end
  end
end
