# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'rubygems'
require 'patriot_gcp/version'

Gem::Specification.new do |s|
  s.name        = VERSION::PROJECT_NAME
  s.version     = VERSION::VERSION
  s.licenses    = ['Apache License, Version 2.0']
  s.authors     = ["Hitoshi Tsuda"]
  s.email       = ["tsuda_hitoshi@cyberagent.co.jp"]
  s.homepage    = "https://github.com/CyberAgent/patriot-workflow-scheduler"
  s.summary     = %q{GCP plugin for Patriot Workflow Scheduler}
  s.description = %q{plugins for Patriot Worlflow Scheduler, which deal with GCP such as BigQuery.}
  s.platform = Gem::Platform::RUBY

  s.rubyforge_project = VERSION::PROJECT_NAME

  s.files         = Dir.glob("lib/**/*") | ["init.rb"]
  s.require_paths = ["lib"]

  s.add_dependency 'patriot-workflow-scheduler', '~>0.7'
end
