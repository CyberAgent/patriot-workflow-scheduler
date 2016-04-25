# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'rubygems'
require 'patriot_aws/version'

Gem::Specification.new do |s|
  s.name        = VERSION::PROJECT_NAME
  s.version     = VERSION::VERSION
  s.license     = 'Apache-2.0'
  s.authors     = ['Takayuki Tanaka']
  s.email       = ['takat007@gmail.com']
  s.homepage    = 'https://github.com/CyberAgent/patriot-workflow-scheduler/tree/master/plugins/patriot-aws'
  s.summary     = 'AWS plugin for Patriot Workflow Scheduler'
  s.description = 'plugins for Patriot Workflow Scheduler, which deal with AWS such as S3.'
  s.platform = Gem::Platform::RUBY

  s.rubyforge_project = VERSION::PROJECT_NAME

  s.files         = Dir.glob('lib/**/*') | ['init.rb']
  s.require_paths = ['lib']

  s.add_dependency 'aws-sdk', '~>2'
  s.add_dependency 'patriot-workflow-scheduler', '~>0.7'
end
