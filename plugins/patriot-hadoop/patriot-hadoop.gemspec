# -*- encoding: utf-8 -*-
require 'rubygems'
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "patriot-hadoop"
  s.version     = "0.1.2.alpha"
  s.licenses    = ['Apache License, Version 2.0']
  s.authors     = ["Hitoshi Tsuda"]
  s.email       = ["tsuda_hitoshi@cyberagent.co.jp"]
  s.homepage    = "https://github.com/CyberAgent/patriot-workflow-scheduler/tree/master/plugins/patriot-hadoop"
  s.summary     = %q{Hadoop plugin for Patriot Workflow Scheduler}
  s.description     = %q{a plugin for Patriot Workflow Scheduler, which deal with Hadoop-related softwares.}
  s.platform = Gem::Platform::RUBY

  s.rubyforge_project = "patriot-hadoop"

  s.files         = Dir.glob("lib/**/*") | ["init.rb"]
  s.require_paths = ["lib"]

  s.add_dependency 'patriot-workflow-scheduler', '~>0.7'
end
