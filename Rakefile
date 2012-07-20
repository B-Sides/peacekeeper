require 'bundler/gem_tasks'
require 'yard'

desc 'Run all the tests'
task :test do
  sh 'bacon -a'
end

YARD::Rake::YardocTask.new do |t|
  t.name = 'doc'
  t.files = Dir["#{File.dirname(__FILE__)}/lib/**/*"]
end
