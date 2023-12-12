require 'securerandom'

Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id
      String :uuid, default: SecureRandom.uuid, null: false, unique: true
      String :email, null: false, unique: true
      FalseClass :confirmed, default: false
      String :password_digest, null: false  # Use this column to store the hashed password
      String :salt, default: SecureRandom.hex(16), null: false  # Use this column for salting
      String :reset_token, default: false, null: true
      DateTime :otp_generated_at
      String :otp

      DateTime :created_at
      DateTime :updated_at
    end
  end
end
