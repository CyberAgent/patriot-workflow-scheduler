include Patriot::Util::Config

def path_to_test_config(name = 'test.ini')
  File.join(File.dirname(File.expand_path(__FILE__)), 'config', name)
end

def config_for_test(name = 'test.ini')
  load_config(path: path_to_test_config(name))
end
