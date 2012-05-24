namespace :sequel do
  require 'sequel'
  Sequel.require 'extensions/migration'

  SEQUEL_DB_FILE = File.expand_path('../../sequel.sqlite3', __FILE__)
  SEQUEL_MIGRATION_DIR = File.expand_path('../../migrations/sequel/', __FILE__)

  desc "Connect to the DB for Sequel"
  task :connect do
    begin
      # Create the SQLite database
      DB = Sequel.connect("sqlite://#{SEQUEL_DB_FILE}")
      puts "Sequel connected to the DB at #{SEQUEL_DB_FILE}"
    rescue Exception => e
      $stderr.puts e, *(e.backtrace)
      $stderr.puts "Couldn't create database at #{SEQUEL_DB_FILE}."
    end
  end

  desc "Run all migrations for Sequel"
  task :migrate => :connect do
    Sequel::Migrator.apply(DB, SEQUEL_MIGRATION_DIR, ENV['VERSION'])
  end
end
