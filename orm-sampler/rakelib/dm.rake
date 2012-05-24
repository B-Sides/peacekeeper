namespace :dm do
  require 'data_mapper'

  DM_DB_FILE = "#{File.expand_path('../../', __FILE__)}/dm.sqlite3"

  desc "Connect to the DB for DataMapper"
  task :connect do
    begin
      # Create the SQLite database
      DataMapper.setup(:default, "sqlite3://#{DM_DB_FILE}")
      puts "DataMapper connected to the DB at #{DM_DB_FILE}"
    rescue Exception => e
      $stderr.puts e, *(e.backtrace)
      $stderr.puts "Couldn't create database at #{DM_DB_FILE}."
    end
  end
end
