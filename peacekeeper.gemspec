# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'peacekeeper/version'

Gem::Specification.new do |s|
  s.name        = 'peacekeeper'
  s.version     = Peacekeeper::VERSION
  s.authors     = ['Josh Ballanco']
  s.email       = ['jballanc@gmail.com']
  s.homepage    = ""
  s.summary     = %q|Peacekeeper handles delegation to a variety of ORMs|
  s.description = %q|Using Peacekeeper, you can develop models separately from the ORM used to persist data.|

  s.rubyforge_project = 'peacekeeper'

  s.files = Dir['{lib,test}/**/*']
  s.files += ['Rakefile', 'README.md']
  s.test_files = Dir['test/**/*']
  s.require_paths = ['lib']

  s.add_runtime_dependency 'sequel', '~> 3.38.0'
  s.add_runtime_dependency 'activerecord', '~> 3.2.6'
  s.add_runtime_dependency 'activerecord-jdbc-adapter', '~> 1.2.2'
  s.add_runtime_dependency 'nasreddin', '~> 0.1'
  s.add_development_dependency 'jdbc-sqlite3', '~> 3.7.2'
  s.add_development_dependency 'bacon', '~> 1.1.0'
  s.add_development_dependency 'facon', '~> 0.5.0'
  s.add_development_dependency 'kramdown', '~> 0.13.7'
  s.add_development_dependency 'yard', '~> 0.8.2'
end
