# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'patriot/version'

$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new "patriot-workflow-scheduler", Patriot::VERSION do |s|
  s.licenses    = ['Apache License, Version 2.0']
  s.authors     = ["Teruyoshi Zenmyo"]
  s.email       = ["zenmyo_teruyoshi@cyberagent.co.jp"]
  s.homepage    = "http://github.com/CyberAgent/patriot-workflow-scheduler"
  s.summary     = %q{Patriot Workflow Scheduler}
  s.description = %q{a workflow scheduler enabling fine-grained dependency management}
  s.platform = Gem::Platform::RUBY

  s.rubyforge_project = "patriot-workflow-scheduler"

  s.files         = Dir.glob("{lib,skel,bin}/**/*")
  # s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = ["patriot-init"]
  s.require_paths = ["lib"]

  s.add_dependency 'activesupport', '~>4.0'
  s.add_dependency 'log4r', '~>1.1'
  s.add_dependency 'json', '~>1.8'
  s.add_dependency 'inifile', '~>2.0'
  s.add_dependency 'thor', '~>0.18'
  s.add_dependency 'rest-client', '~>2.0'
  s.add_dependency 'sinatra', '~>1.4'
  s.add_dependency 'sinatra-contrib', '~>1.4'
  s.add_dependency 'mail', '~>2.6'
  s.add_dependency 'tilt', '~>1.4'
  s.add_dependency 'thin', '~>1.6'
  s.add_dependency 'rack-rewrite', '~>1.5'
end
