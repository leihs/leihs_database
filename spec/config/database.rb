require 'active_support/all'
require 'addressable'
require 'logger'
require 'ostruct'
require 'sequel'
require 'yaml'


### sequel ####################################################################

def db_name
  ENV['LEIHS_DATABASE_NAME'] || ENV['DB_NAME'] || 'leihs'
end

def db_port
  Integer(ENV['DB_PORT'].presence || ENV['PGPORT'].presence || 5432)
end

def db_con_str
  logger = Logger.new(STDOUT)
  s = 'postgres://' \
    + (ENV['PGUSER'].presence || 'postgres') \
    + ((pw = (ENV['DB_PASSWORD'].presence || ENV['PGPASSWORD'].presence)) ? ":#{pw}" : "") \
    + '@' + (ENV['PGHOST'].presence || 'localhost') \
    + ':' + (db_port).to_s \
    + '/' + (db_name)
  logger.info "SEQUEL CONN #{s}"
  s
end

def database
  @database ||= Sequel.connect(db_con_str)
end



################## NOTE #######################################
database.extension :pg_json
###############################################################

def clean_db
  sql = <<-SQL
    SELECT table_name
      FROM information_schema.tables
    WHERE table_type = 'BASE TABLE'
    AND table_schema = 'public'
    ORDER BY table_type, table_name;
  SQL

  database[sql]
    .map { |r| r[:table_name] }
    .reject { |tn| tn == 'schema_migrations' }
    .join(', ')
    .tap { |tables| database.run " TRUNCATE TABLE #{tables} CASCADE; " }
end

RSpec.configure do |config|
  config.before(:example)  do
    clean_db
    system("LEIHS_DATABASE_NAME=#{db_name} ./scripts/restore-seeds")
  end
end

def with_disabled_triggers
  database.run 'SET session_replication_role = replica;'
  result = yield
  database.run 'SET session_replication_role = DEFAULT;'
  result
end

