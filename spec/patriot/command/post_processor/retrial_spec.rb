require 'init_test'

describe Patriot::Command::PostProcessor::Retrial do 

  include JobStoreMatcher
  include Patriot::Command::Parser

  before :each do 
    @config = config_for_test
    @worker = Patriot::Worker::Base.new(@config)
    @target_datetime = Time.new(2015,8,1)
    @cmds   = Patriot::Command::CommandGroup.new(@config).parse(@target_datetime, <<'EOJ'
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
    @job_store = @worker.instance_variable_get(:@job_store)
    @update_id = Time.now.to_i
    @jobs       = @cmds.map(&:to_job)
    @job_store.register(@update_id, @jobs)
  end

  it "should retry failed job" do
    retry_job_id = 'sh_test_2015-08-01'
    0.upto(2) do |i|
      job_ticket = @job_store.get_job_tickets("", [])[0]
      expect(job_ticket.job_id).to eq retry_job_id
      expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::FAILED
      history = @job_store.get_execution_history(retry_job_id, {:limit => 1})[0]
      expect(history[:exit_code]).to eq Patriot::Command::ExitCode::FAILED
      job = @job_store.get(retry_job_id, {:include_dependency => true})
      if i == 2
        expect(job).to be_failed_in @job_store
      else
        next_time = (history[:end_at] + 2).strftime("%Y-%m-%d %H-%M-%S")
        expect(job[Patriot::Command::START_DATETIME_ATTR].strftime("%Y-%m-%d %H-%M-%S")).to eq next_time
        expect(job).to be_waited_in @job_store
        sleep 2
      end
    end
  end
end
