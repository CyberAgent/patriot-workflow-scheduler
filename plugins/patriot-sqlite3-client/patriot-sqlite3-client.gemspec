# -*- encoding: utf-8 -*-
require 'rubygems'
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "patriot-sqlite3-client"
  s.version     = "0.7.0"
  s.licenses    = ['Apache License, Version 2.0']
  s.authors     = ["Teruyoshi Zenmyo"]
  s.email       = ["zenmyo_teruyoshi@cyberagent.co.jp"]
  s.homepage    = "https://github.com/CyberAgent/patriot-workflow-scheduler"
  s.summary     = %q{SQLite3 Client for Patriot Workflow Scheduler}
  s.description     = %q{A dbadapter implementation to use sqlite3 as jobstore}
  s.platform = Gem::Platform::RUBY

  s.rubyforge_project = "patriot-sqlite3-client"

  s.files         = Dir.glob("lib/**/*") | ["init.rb"]
  # s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency 'sqlite3', '~>1.3'
  s.add_dependency 'patriot-workflow-scheduler', '~>0.6'
end
