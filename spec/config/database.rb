require "active_support/all"
require "logger"
require "sequel"

### data ######################################################################

DB_PROJECT_DIR = Pathname(__FILE__).join("../../..")

def seeds_sql
  @seeds_sql ||= IO.read(DB_PROJECT_DIR.join("db/seeds.sql"))
end

def personas_sql
  @personas_sql ||= IO.read(DB_PROJECT_DIR.join("db/personas.sql"))
end

### sequel ####################################################################

# general rules for getting connection env params
#
# 1. LEIHS_DATABASE_
# 2. DB_
# 3. PG_
# 4. some sensible default constant

def database_name
  ENV["DB_NAME_TEST"].presence ||
    ENV["LEIHS_DATABASE_NAME"].presence ||
    ENV["DB_NAME"].presence ||
    ENV["PGDATABASE"].presence ||
    ENV["PGDATABASE"].presence ||
    "leihs"
end

def database_user
  ENV["LEIHS_DATABASE_USER"].presence ||
    ENV["DB_USER"].presence ||
    ENV["PGUSER"].presence ||
    "postgres"
end

def database_password
  ENV["LEIHS_DATABASE_PASSWORD"].presence ||
    ENV["DB_PASSWORD"].presence ||
    ENV["PGPASSWORD"].presence
end

def database_host
  ENV["LEIHS_DATABASE_HOST"].presence ||
    ENV["DB_HOST"].presence ||
    ENV["PGHOST"].presence ||
    "localhost"
end

def database_port
  Integer(
    ENV["LEIHS_DATABASE_PORT"].presence ||
    ENV["DB_PORT"].presence ||
    ENV["PGPORT"].presence ||
    5415
  )
end

def database
  @database ||= Sequel.postgres(
    database: database_name,
    user: database_user,
    password: database_password,
    host: database_host,
    port: database_port
  )
end

database.extension :pg_json
database.wrap_json_primitives = true

### helpers ###################################################################

def db_clean
  table_names = database[ <<-SQL.strip_heredoc
    SELECT table_name
      FROM information_schema.tables
    WHERE table_type = 'BASE TABLE'
    AND table_schema = 'public'
    ORDER BY table_type, table_name;
  SQL
  ].map { |r| r[:table_name] }.reject { |tn| tn == "schema_migrations" }
  return if table_names.empty?

  quoted_tables = table_names.map { |tn| database.quote_identifier(tn) }.join(", ")
  database.run "TRUNCATE TABLE #{quoted_tables} CASCADE;"
end

def db_restore_data data
  database.transaction do
    # pg_dumps reset the search_path for the current session
    # we restore it to the setting before the dump was restored
    search_path = database[
      "SELECT setting FROM pg_settings WHERE name = 'search_path'"
    ].first[:setting]
    database.run "SET session_replication_role = REPLICA;"
    database.run data
    database.run "SET session_replication_role = DEFAULT;"
    database["SELECT set_config('search_path', ?, false)", search_path].first
  end
end

def db_with_disabled_triggers
  database.run "SET session_replication_role = REPLICA;"
  result = yield
  database.run "SET session_replication_role = DEFAULT;"
  result
end
