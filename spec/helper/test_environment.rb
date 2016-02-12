module  TestEnvironment
  include Patriot::Util::Config

  TEST_TARGET_DATE = Time.new(2015, 4, 1)
  def build_job(opt = {})
    options = {
        :job_id          => rand(100000),
        :node            => nil,
        :host            => nil,
        :state           => Patriot::JobStore::JobState::WAIT,
        :commands        => 'echo 1',
        :require         => [],
        :produce         => [],
        :config          => config_for_test,
      }.merge(opt)
    config = options.delete(:config)

    job_id = options[:job_id]
    n = (options[:node]) ? options[:node] : nil
    j = Patriot::Command::ShCommand.new(config)
    j.target_datetime = TEST_TARGET_DATE
    j.name         "job_#{job_id}"
    j.require      options[:require]
    j.produce      options[:produce]
    j.commands     options[:commands]
    j.exec_host    options[:host] unless options[:host].nil?
    j.exec_node    options[:node] unless options[:node].nil?
    j.instance_variable_set(:@state, options[:state])
    j.post_processors = options[:post_processors] unless options[:post_processors].nil?
    return j.build[0].to_job
  end

  def path_to_test_config(type = "test")
    File.join(ROOT_PATH,'spec', 'config', "#{type}.ini")
  end

  def config_for_test(type=nil, opt = "test")
    return load_config({:path => path_to_test_config(opt), :type=> type})
  end
end
