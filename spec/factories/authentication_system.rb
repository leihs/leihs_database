class AuthenticationSystem < Sequel::Model(:authentication_systems)
end

FactoryBot.define do
  factory :authentication_system do
    name { Faker::Name.last_name }
    id { name.downcase }
    enabled  true
    type 'external'
    description { Faker::Lorem.sentence }
    priority 10
    internal_private_key <<-KEY.strip_heredoc
        -----BEGIN EC PRIVATE KEY-----
        MHcCAQEEIHErTjw8Z1yNisngEuZ5UvBn1qM2goN3Wd1V4Pn3xQeYoAoGCCqGSM49
        AwEHoUQDQgAEzGT0FBI/bvn21TOuLmkzDwzRsIuOyIf9APV7DAZr3fgCqG1wzXce
        MGG42wJIDRduJ9gb3LJiewqzq6VVURvyKQ==
        -----END EC PRIVATE KEY-----
      KEY
     internal_public_key  <<-KEY.strip_heredoc
          -----BEGIN PUBLIC KEY-----
          MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEzGT0FBI/bvn21TOuLmkzDwzRsIuO
          yIf9APV7DAZr3fgCqG1wzXceMGG42wJIDRduJ9gb3LJiewqzq6VVURvyKQ==
          -----END PUBLIC KEY-----
      KEY
     external_public_key <<-KEY.strip_heredoc
          -----BEGIN PUBLIC KEY-----
          MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEzGT0FBI/bvn21TOuLmkzDwzRsIuO
          yIf9APV7DAZr3fgCqG1wzXceMGG42wJIDRduJ9gb3LJiewqzq6VVURvyKQ==
          -----END PUBLIC KEY-----
      KEY
  end
end
