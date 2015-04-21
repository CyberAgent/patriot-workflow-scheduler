require 'erb'
require 'init_test'

unless ENV['TEST_DBMS'].nil?
  erb = ERB.new(File.open(File.join(ROOT_PATH, 'spec', 'template', 'job_store_spec.erb')).read)
  init_conf_statement = '@config = config_for_test(nil, ENV["TEST_DBMS"])'
  job_store_class = 'Patriot::JobStore::RDBJobStore'
  eval erb.result(binding)
end

