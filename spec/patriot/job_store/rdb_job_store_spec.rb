require 'erb'
require 'init_test'

erb = ERB.new(File.open(File.join($ROOT_PATH, 'spec', 'template', 'job_store_spec.erb')).read)
init_conf_statement = '@config = config_for_test(nil, TEST_DB_TYPE)'
job_store_class = 'Patriot::JobStore::RDBJobStore'
eval erb.result(binding)

