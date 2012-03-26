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
  s.files += ['Rakefile']
  s.test_files = Dir['test/**/*']
  s.require_paths = ['lib']

  s.add_runtime_dependency 'sequel', '~> 3.33.0'
  s.add_development_dependency 'sqlite3', '~> 1.3.5'
  s.add_development_dependency 'bacon', '~> 1.1.0'
end
