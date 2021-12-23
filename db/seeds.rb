# This is additional data which was not covered by the rails initializers.
# Run with: `bundle exec ruby -s db/seeds.rb` from parent dir of this file.

require 'active_support/all'
require 'sequel'
require 'yaml'
require_relative '../lib/leihs/constants.rb'
require_relative '../lib/leihs/fields.rb'

### sequel ####################################################################

def db_name
  ENV['DB_NAME'].presence || ENV['PGDATABASE'].presence || 'leihs'
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

###############################################################################


database.extension :pg_json

class Field < Sequel::Model(:fields)
end
Field.unrestrict_primary_key

def setup_fields
  fields = Leihs::Fields.load
  %w(fields_insert_check_trigger).each do |trigger|
    database.run("ALTER TABLE fields DISABLE TRIGGER #{trigger}")
  end
  fields.each do |field|
    Field.create(field)
  end
  %w(fields_insert_check_trigger).each do |trigger|
    database.run("ALTER TABLE fields ENABLE TRIGGER #{trigger}")
  end
end

def resurrect_general_building
  database.run <<-SQL
    INSERT INTO buildings (id, name)
    VALUES ('#{Leihs::Constants::GENERAL_BUILDING_UUID}', 'general building')
  SQL
end

def resurrect_general_room_for_general_building
  database.run <<-SQL
    INSERT INTO rooms (name, building_id, general)
    VALUES ('general room', '#{Leihs::Constants::GENERAL_BUILDING_UUID}', TRUE)
  SQL
end

def seed_authentication_systems
  database[:authentication_systems].insert(
    id: 'password',
    name: 'leihs password',
    type: 'password',
    enabled: true
  )
end

setup_fields
resurrect_general_building
resurrect_general_room_for_general_building
seed_authentication_systems
