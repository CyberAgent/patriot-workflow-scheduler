require 'init_test'

describe Patriot::Command::PostProcessor::Retrial do

  include JobStoreMatcher
  include Patriot::Command::Parser

  before :each do
    @config = config_for_test
    @worker = Patriot::Worker::Base.new(@config)
    @target_datetime = Time.new(2015,8,1)
    @job_store = @worker.instance_variable_get(:@job_store)
    @update_id = Time.now.to_i
  end

  it "should retry failed job" do
    retry_job_id = 'sh_test_2015-08-01'

    cmds   = Patriot::Command::CommandGroup.new(@config).parse(@target_datetime, <<'EOJ'
  sh{
    produce ['input']
    skip
    name 'producer'
    commands 'echo producer'
  }
  sh{
    require ['input']
    produce ['output']
    retrial 'count' => 3, 'interval' => 2
    name 'test'
    commands 'sh -c "exit 1"'
  }
  sh{
    skip
    require ['output']
    name 'consumer'
    commands 'echo consumer'
  }
EOJ
    )
    jobs       = cmds.map(&:to_job)
    @job_store.register(@update_id, jobs)
    0.upto(2) do |i|
      job_ticket = @job_store.get_job_tickets("", [])[0]
      expect(job_ticket.job_id).to eq retry_job_id
      expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::FAILED
      execution_history = @job_store.get_execution_history(retry_job_id, {:limit => 1})[0]
      expect(execution_history[:exit_code]).to eq Patriot::Command::ExitCode::FAILED
      job = @job_store.get(retry_job_id, {:include_dependency => true})
      if i == 2
        expect(job).to be_failed_in @job_store
      else
        next_time = (execution_history[:end_at] + 2).strftime("%Y-%m-%d %H-%M-%S")
        expect(job[Patriot::Command::START_DATETIME_ATTR].strftime("%Y-%m-%d %H-%M-%S")).to eq next_time
        expect(job).to be_waited_in @job_store
        sleep 2
      end
    end
  end

  it "should retry failed job with retrial set at job_group which has sh command" do
    retry_job_id = 'sh_test_retrial_set_at_job_group_which_has_sh_command_2015-08-01'

    cmds   = Patriot::Command::CommandGroup.new(@config).parse(@target_datetime, <<'EOJ'
  job_group {
    retrial 'count' => 3, 'interval' => 2
    sh {
      name 'test_retrial_set_at_job_group_which_has_sh_command'
      commands 'sh -c "exit 1"'
    }
  }
EOJ
    )
    jobs       = cmds.map(&:to_job)
    @job_store.register(@update_id, jobs)
    0.upto(2) do |i|
      job_ticket = @job_store.get_job_tickets("", [])[0]
      expect(job_ticket.job_id).to eq retry_job_id
      expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::FAILED
      execution_history = @job_store.get_execution_history(retry_job_id, {:limit => 1})[0]
      expect(execution_history[:exit_code]).to eq Patriot::Command::ExitCode::FAILED
      job = @job_store.get(retry_job_id, {:include_dependency => true})
      if i == 2
        expect(job).to be_failed_in @job_store
      else
        next_time = (execution_history[:end_at] + 2).strftime("%Y-%m-%d %H-%M-%S")
        expect(job[Patriot::Command::START_DATETIME_ATTR].strftime("%Y-%m-%d %H-%M-%S")).to eq next_time
        expect(job).to be_waited_in @job_store
        sleep 2
      end
    end
  end

  it "should retry failed job with retrial set at command in job_group" do
    retry_job_id = 'sh_test_retrial_set_at_command_in_job_group_2015-08-01'

    cmds   = Patriot::Command::CommandGroup.new(@config).parse(@target_datetime, <<'EOJ'
  job_group {
    sh {
      retrial 'count' => 3, 'interval' => 2
      name 'test_retrial_set_at_command_in_job_group'
      commands 'sh -c "exit 1"'
    }
  }
EOJ
    )
    jobs       = cmds.map(&:to_job)
    @job_store.register(@update_id, jobs)
    0.upto(2) do |i|
      job_ticket = @job_store.get_job_tickets("", [])[0]
      expect(job_ticket.job_id).to eq retry_job_id
      expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::FAILED
      execution_history = @job_store.get_execution_history(retry_job_id, {:limit => 1})[0]
      expect(execution_history[:exit_code]).to eq Patriot::Command::ExitCode::FAILED
      job = @job_store.get(retry_job_id, {:include_dependency => true})
      if i == 2
        expect(job).to be_failed_in @job_store
      else
        next_time = (execution_history[:end_at] + 2).strftime("%Y-%m-%d %H-%M-%S")
        expect(job[Patriot::Command::START_DATETIME_ATTR].strftime("%Y-%m-%d %H-%M-%S")).to eq next_time
        expect(job).to be_waited_in @job_store
        sleep 2
      end
    end
  end

  it "should retry failed job with retrial set at composite_job" do
    retry_job_id = 'composite_test_retrial_set_at_composite_job_2015-08-01'

    cmds   = Patriot::Command::CommandGroup.new(@config).parse(@target_datetime, <<'EOJ'
  composite_job {
    name 'test_retrial_set_at_composite_job'
    retrial 'count' => 3, 'interval' => 2

    sh {
      name 'ok'
      commands 'sh -c "exit 1"'
    }
  }
EOJ
    )
    jobs       = cmds.map(&:to_job)
    @job_store.register(@update_id, jobs)
    0.upto(2) do |i|
      job_ticket = @job_store.get_job_tickets("", [])[0]

      expect(job_ticket.job_id).to eq retry_job_id
      expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::FAILED
      execution_history = @job_store.get_execution_history(retry_job_id, {:limit => 1})[0]

      expect(execution_history[:exit_code]).to eq Patriot::Command::ExitCode::FAILED
      job = @job_store.get(retry_job_id, {:include_dependency => true})

      if i == 2
        expect(job).to be_failed_in @job_store
      else
        next_time = (execution_history[:end_at] + 2).strftime("%Y-%m-%d %H-%M-%S")
        expect(job[Patriot::Command::START_DATETIME_ATTR].strftime("%Y-%m-%d %H-%M-%S")).to eq next_time
        expect(job).to be_waited_in @job_store
        sleep 2
      end
    end
  end

  it "should retry failed job with retrial set at job_group which has composite_job" do
    retry_job_id = 'composite_test_retrial_set_at_job_group_which_has_composite_job_2015-08-01'

    cmds   = Patriot::Command::CommandGroup.new(@config).parse(@target_datetime, <<'EOJ'
  job_group {
    retrial 'count' => 3, 'interval' => 2

    composite_job {
      name 'test_retrial_set_at_job_group_which_has_composite_job'

      sh {
        name 'ok'
        commands 'sh -c "exit 1"'
      }
    }
  }
EOJ
    )
    jobs       = cmds.map(&:to_job)
    @job_store.register(@update_id, jobs)
    0.upto(2) do |i|
      job_ticket = @job_store.get_job_tickets("", [])[0]

      expect(job_ticket.job_id).to eq retry_job_id
      expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::FAILED
      execution_history = @job_store.get_execution_history(retry_job_id, {:limit => 1})[0]

      expect(execution_history[:exit_code]).to eq Patriot::Command::ExitCode::FAILED
      job = @job_store.get(retry_job_id, {:include_dependency => true})

      if i == 2
        expect(job).to be_failed_in @job_store
      else
        next_time = (execution_history[:end_at] + 2).strftime("%Y-%m-%d %H-%M-%S")
        expect(job[Patriot::Command::START_DATETIME_ATTR].strftime("%Y-%m-%d %H-%M-%S")).to eq next_time
        expect(job).to be_waited_in @job_store
        sleep 2
      end
    end
  end

  it "should retry failed job with retrial set at composite_job in job_group" do
    retry_job_id = 'composite_test_retrial_set_at_composite_job_in_job_group_2015-08-01'

    cmds   = Patriot::Command::CommandGroup.new(@config).parse(@target_datetime, <<'EOJ'
  job_group {
    composite_job {
      name 'test_retrial_set_at_composite_job_in_job_group'
      retrial 'count' => 3, 'interval' => 2

      sh {
        name 'ok'
        commands 'sh -c "exit 1"'
      }
    }
  }
EOJ
    )
    jobs       = cmds.map(&:to_job)
    @job_store.register(@update_id, jobs)
    0.upto(2) do |i|
      job_ticket = @job_store.get_job_tickets("", [])[0]

      expect(job_ticket.job_id).to eq retry_job_id
      expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::FAILED
      execution_history = @job_store.get_execution_history(retry_job_id, {:limit => 1})[0]

      expect(execution_history[:exit_code]).to eq Patriot::Command::ExitCode::FAILED
      job = @job_store.get(retry_job_id, {:include_dependency => true})

      if i == 2
        expect(job).to be_failed_in @job_store
      else
        next_time = (execution_history[:end_at] + 2).strftime("%Y-%m-%d %H-%M-%S")
        expect(job[Patriot::Command::START_DATETIME_ATTR].strftime("%Y-%m-%d %H-%M-%S")).to eq next_time
        expect(job).to be_waited_in @job_store
        sleep 2
      end
    end
  end

  it "should raise error when parsing pbc with retrial set at subcommand of composite_job" do
    pbc = <<'EOJ'
composite_job {
  name 'test_retrial_set_at_subcommand_of_composite_job'

  sh {
    retrial 'count' => 3, 'interval' => 2
    name 'ng'
    commands 'sh -c "exit 1"'
  }
}
EOJ
    parser = Patriot::Command::CommandGroup.new(@config)
    expect {parser.parse(@target_datetime, pbc)}.to raise_error(/you cannot set "post_processor" at subcommand of composite_job\'s/)
  end

  it "should raise error when parsing pbc with retrial set at subcommand of composite_job in job_group" do
    pbc = <<'EOJ'
job_group {
  composite_job {
    name 'test_retrial_set_at_subcommand_of_composite_job_in_job_group'

    sh {
      retrial 'count' => 3, 'interval' => 2
      name 'ng'
      commands 'sh -c "exit 1"'
    }
  }
}
EOJ
    parser = Patriot::Command::CommandGroup.new(@config)
    expect {parser.parse(@target_datetime, pbc)}.to raise_error(/you cannot set "post_processor" at subcommand of composite_job\'s/)
  end

end
