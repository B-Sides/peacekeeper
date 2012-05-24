$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift File.expand_path('../fixtures', __FILE__)
$-w = nil
require 'pry'
require 'fileutils'

TEMP_DIR = File.expand_path('../tmp/', __FILE__)
SEQUEL_TEST_DB = File.join(TEMP_DIR, 'sequel.sqlite3')

# Clear out the tmp dir at the start
FileUtils.rm_rf(File.join(TEMP_DIR, '*'))
