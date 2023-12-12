# frozen_string_literal: true

require 'spec_helper'

RSpec.describe User do
  describe 'before create' do
    let(:user) { build(:user) }

    before do
      expect(user.uuid).to be_nil
    end

    it 'generates uuid' do
      user.save
      expect(user.uuid).not_to be_nil
    end
  end

  describe 'validations' do
    let(:user) { build(:user) }

    before do
      expect(user.valid?).to be true
    end

    it 'validates presence of email' do
      user.email = nil

      expect(user.valid?).to be false
      expect(user.errors.full_messages).to eq ['email is not present']
    end

    context 'with invalid email' do
      let(:invalid_emails) { %w[email @domain.com] }

      it 'validates email format' do
        invalid_emails.each do |email|
          user.email = email
          expect(user.valid?).to be false
          expect(user.errors.full_messages).to eq ['email is invalid']
        end
      end
    end
  end
end
