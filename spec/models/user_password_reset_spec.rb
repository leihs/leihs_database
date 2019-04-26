require 'spec_helper'

describe 'user password resets' do
  example 'trigger deletion of old on insert' do
    user = FactoryBot.create(:user)
    FactoryBot.create(:user_password_reset, user: user, token: 'foo')
    FactoryBot.create(:user_password_reset, user: user, token: 'bar')
    expect(UserPasswordReset.count).to eq 1
    expect(UserPasswordReset.first.token).to eq 'bar'
  end
end
