require 'erb'
require 'init_test'

erb = ERB.new(File.open(File.join($ROOT_PATH, 'spec', 'template', 'job_store_spec.erb')).read)
init_conf_statement = '@config = config_for_test'
job_store_class = 'Patriot::JobStore::InMemoryStore'
eval erb.result(binding)

