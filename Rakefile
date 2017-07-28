# -*- coding: utf-8 -*-
load 'Rakefile.base'

PLUGINS = {'mysql2'  => 'patriot-mysql2-client',
           'sqlite3' => 'patriot-sqlite3-client',
           'aws'     => 'patriot-aws',
           'gcp'     => 'patriot-gcp',
           'hadoop'  => 'patriot-hadoop'}
TASKS   = ['build', 'install', 'spec', 'yard', 'clean', 'clobber']

TASKS.each do |t|
  namespace t do
    PLUGINS.each do |key, plugin|
      desc "#{t} #{plugin}"
      task key.to_sym do
        cd File.join('plugins', plugin) do
          sh "rake #{t}"
        end
      end
    end
    desc "perform #{t} for core and plugins"
    task :all => [t] | PLUGINS.keys.map{|plugin| "#{t}:#{plugin}"}
  end
end

