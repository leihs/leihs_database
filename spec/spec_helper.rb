require "base32/crockford"
require "config/database"
require "config/factories"
require "pry"
require "uuidtools"

RSpec.configure do |config|
  config.before(:example) do |example|
    db_clean
    db_restore_data seeds_sql
  end
end
