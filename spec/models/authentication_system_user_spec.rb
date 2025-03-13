require "spec_helper"

describe "authentication system user" do
  context "trigger deletion of obsolete user password reset" do
    example "on insert" do
      user = FactoryBot.create(:user)
      FactoryBot.create(:user_password_reset, user: user)
      expect(UserPasswordReset.count).to eq 1
      AuthenticationSystemUser.find(user_id: user.id, authentication_system_id: "password").delete
      FactoryBot.create(:authentication_system_user, user: user, authentication_system_id: "password")
      expect(UserPasswordReset.count).to eq 0
    end

    example "on update" do
      user = FactoryBot.create(:user)
      asu = AuthenticationSystemUser.find(user_id: user.id, authentication_system_id: "password")
      FactoryBot.create(:user_password_reset, user: user)
      expect(UserPasswordReset.count).to eq 1
      asu.update(data: Faker::Crypto.md5)
      expect(UserPasswordReset.count).to eq 0
    end
  end

  example "don't trigger deletion of obsolete user password reset" do
    user = FactoryBot.create(:user)
    FactoryBot.create(:user_password_reset, user: user)
    expect(UserPasswordReset.count).to eq 1
    FactoryBot.create(:authentication_system_user,
      user: user,
      authentication_system:
        FactoryBot.create(:authentication_system,
          id: "aai"))
    expect(UserPasswordReset.count).to eq 1
  end
end
