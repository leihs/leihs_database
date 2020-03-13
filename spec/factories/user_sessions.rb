class UserSession < Sequel::Model
  attr_accessor :token
end

FactoryBot.define do
  factory :user_session do
    token { SecureRandom.uuid }

    after(:build) do |user_session|
      user_session[:token_hash] = Digest::SHA256.hexdigest user_session.token
    end

  end
end
