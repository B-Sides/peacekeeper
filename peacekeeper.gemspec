# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "peacekeeper/version"

Gem::Specification.new do |s|
  s.name        = "peacekeeper"
  s.version     = Peacekeeper::VERSION
  s.authors     = ["Josh Ballanco"]
  s.email       = ["jballanc@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Peacekeeper handles delegation to a variety of ORMs}
  s.description = %q{Using Peacekeeper, you can develop models separately from the ORM used to persist data.}

  s.rubyforge_project = "peacekeeper"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
