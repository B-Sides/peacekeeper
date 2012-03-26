$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift File.expand_path('../fixtures', __FILE__)
begin
  require 'pry'
rescue LoadError
  $stderr.puts 'Install the pry gem for better debugging.'
end
require 'fileutils'

TEMP_DIR = File.expand_path('../tmp/', __FILE__) unless defined? TEMP_DIR
SEQUEL_TEST_DB = File.join(TEMP_DIR, 'sequel.sqlite3') unless defined? SEQUEL_TEST_DB

# Clear out the tmp dir at the start
FileUtils.rm_rf(File.join(TEMP_DIR, '*'))
