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
  names = database[ <<-SQL.strip_heredoc
    SELECT table_name
      FROM information_schema.tables
    WHERE table_type = 'BASE TABLE'
    AND table_schema = 'public'
    AND table_name <> 'schema_migrations'
    ORDER BY table_type, table_name;
  SQL
  ].map { |r| r[:table_name] }

  names.each do |tn|
    unless tn.match?(/\A[a-z][a-z0-9_]*\z/)
      raise "refusing TRUNCATE: invalid public table name #{tn.inspect}"
    end
  end

  return if names.empty?

  list = names.join(", ")
  database.run " TRUNCATE TABLE #{list} CASCADE; "
end

def db_restore_data data
  database.transaction do
    # pg_dumps reset the search_path for the current session
    # we restore it to the setting before the dump was restored
    search_path = database[
      "SELECT setting FROM pg_settings WHERE name = 'search_path'"
    ].first[:setting]
    search_path_sql = database.literal(search_path)
    database.run \
      "SET session_replication_role = REPLICA;" \
      << data \
      << "SET session_replication_role = DEFAULT;" \
      << "SET search_path = #{search_path_sql}"
  end
end

# Inserts a contract row before any reservation exists. The DB enforces that with
# trigger_check_contract_has_at_least_one_reservation (deferred constraint trigger).
# Historically tests used session_replication_role = replica to skip triggers during
# that insert; current PostgreSQL versions still run this constraint trigger, so we
# disable it explicitly for the wrapped operation only.
def db_with_disabled_triggers
  database.run <<~SQL.squish
    ALTER TABLE IF EXISTS public.contracts
    DISABLE TRIGGER trigger_check_contract_has_at_least_one_reservation
  SQL
  yield
ensure
  database.run <<~SQL.squish
    ALTER TABLE IF EXISTS public.contracts
    ENABLE TRIGGER trigger_check_contract_has_at_least_one_reservation
  SQL
end
