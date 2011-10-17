# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "configy/version"

Gem::Specification.new do |s|
  s.name        = "configy"
  s.version     = Configy::VERSION
  s.authors     = ["Kyle Hargraves"]
  s.email       = ["rhargraves@enovafinancial.com"]
  s.homepage    = ""
  s.summary     = %q{Smart YAML config loading library}
  s.description = %q{TODO}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "aruba"
  s.add_development_dependency "heredoc_unindent"
end
