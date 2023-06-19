require 'active_support/all'

Dir.chdir(ENV['LEIHS_DATABASE_DIR'].presence \
          || raise("LEIHS_DATABASE_DIR not set")  )do
  require 'yaml'
  db_config = {
    'adapter' => 'postgresql',
    'encoding' => 'unicode',
    'host' => 'localhost',
    'pool' => 20,
    'timeout' => 20,
    'port' => ENV['PG15PORT'],
    'username' => ENV['PG15USER'],
    'password' =>  ENV['PG15PASSWORD'],
    'database' => ENV['LEIHS_DATABASE_NAME']}
  config = { (ENV['RAILS_ENV'].presence || raise('RAILS_ENV not set')) => db_config}
  File.open('config/database.yml','w') { |file| file.write config.to_yaml }
end
