# This is additional data which was not covered by the rails initializers.
# Run with: `bundle exec ruby -s db/seeds.rb` from parent dir of this file.

require 'active_support/all'
require 'sequel'
require 'addressable'
require 'yaml'
require_relative '../lib/leihs/constants.rb'
require_relative '../lib/leihs/fields.rb'

def database
  @database ||= \
    Sequel.connect(
      if (db_env = ENV['LEIHS_DATABASE_URL'].presence)
        # trick Addressable to parse db urls
        http_uri = Addressable::URI.parse db_env.gsub(/^jdbc:postgresql/,'http').gsub(/^postgres/,'http')
        db_url = 'postgres://' \
          + (http_uri.user.presence || ENV['PGUSER'].presence || 'postgres') \
          + ((pw = (http_uri.password.presence || ENV['PGPASSWORD'].presence)) ? ":#{pw}" : "") \
          + '@' + (http_uri.host.presence || ENV['PGHOST'].presence || ENV['PGHOSTADDR'].presence || 'localhost') \
          + ':' + (http_uri.port.presence || ENV['PGPORT'].presence || 5432).to_s \
          + '/' + ( http_uri.path.presence.try(:gsub,/^\//,'') || ENV['PGDATABASE'].presence || 'leihs') \
          + '?pool=5'
      else
        'postgresql://leihs:leihs@localhost:5432/leihs?pool=5'
      end
    )
end

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
