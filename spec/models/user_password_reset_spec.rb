require 'spec_helper'

describe 'user password resets' do
  example 'trigger deletion of old on insert' do
    user = FactoryBot.create(:user)
    FactoryBot.create(:user_password_reset, user: user)
    FactoryBot.create(:user_password_reset, user: user, token: '1234567890ABC')
    expect(UserPasswordReset.count).to eq 1
    expect(UserPasswordReset.first.token).to eq '1234567890ABC'
  end
end
