require 'active_support/all'
require 'addressable'
require 'ostruct'
require 'sequel'
require 'yaml'

DB_ENV = ENV['LEIHS_DATABASE_URL'].presence

def http_uri
  @http_uri ||= \
    Addressable::URI.parse DB_ENV.gsub(/^jdbc:postgresql/,'http').gsub(/^postgres/,'http')
end

def database
  @database ||= \
    Sequel.connect(
      if DB_ENV
        yml_path = 'config/database.yml'
        if File.exists?(yml_path)
          yml = YAML::load(IO.read(yml_path))
          dbname_from_yml = yml.try(:[], 'test').try(:[], 'database')
        end
        'postgres://' \
          + (http_uri.user.presence || ENV['PGUSER'].presence || 'postgres') \
          + ((pw = (http_uri.password.presence || ENV['PGPASSWORD'].presence)) ? ":#{pw}" : "") \
          + '@' + (http_uri.host.presence || ENV['PGHOST'].presence || ENV['PGHOSTADDR'].presence || 'localhost') \
          + ':' + (http_uri.port.presence || ENV['PGPORT'].presence || 5432).to_s \
          + '/' + ( http_uri.path.presence.try(:gsub,/^\//,'') || ENV['PGDATABASE'].presence || dbname_from_yml || 'leihs') \
          + '?pool=5'
      else
        'postgresql://leihs:leihs@localhost:5432/leihs?pool=5'
      end)
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
    system("DATABASE_NAME=#{http_uri.basename} ./scripts/restore-seeds")
  end
end
