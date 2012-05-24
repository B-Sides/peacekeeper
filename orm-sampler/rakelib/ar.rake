namespace :ar do
  require 'active_record'

  AR_DB_FILE = "#{File.expand_path('../../', __FILE__)}/ar.sqlite3"
  CONFIG =  { adapter: 'sqlite3',
              database: AR_DB_FILE }

  desc "Connect to the DB for ActiveRecord"
  task :connect do
    begin
      # Create the SQLite database
      ActiveRecord::Base.establish_connection(CONFIG)
      ActiveRecord::Base.connection
    rescue Exception => e
      $stderr.puts e, *(e.backtrace)
      $stderr.puts "Couldn't create database for #{CONFIG.inspect}"
    end
    puts "ActiveRecord connected to the DB at #{AR_DB_FILE}"
  end

  desc "Run all migrations for ActiveRecord"
  task :migrate => :connect do
    ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
    ActiveRecord::Migrator.migrate(Dir['./migrations/ar/*.rb'], ENV["VERSION"] ? ENV["VERSION"].to_i : nil) do |migration|
      ENV["SCOPE"].blank? || (ENV["SCOPE"] == migration.scope)
    end
  end
end
