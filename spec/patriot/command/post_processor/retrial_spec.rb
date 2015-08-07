require 'init_test'

describe Patriot::Command::PostProcessor::Retrial do 

  include JobStoreMatcher
  include Patriot::Command::Parser

  before :each do 
    @config = config_for_test
    @worker = Patriot::Worker::Base.new(@config)
    @cmds   = Patriot::Command::CommandGroup.new(@config).parse(DateTime.new(2015,8,1), <<'EOJ'
  sh{
    retrial 'count' => 3, 'interval' => 2
    name 'test_#{_date_}'
    commands 'sh -c "exit 1"'
  }
EOJ
    )
    @job_store = @worker.instance_variable_get(:@job_store)
    @update_id = Time.now.to_i
    @job       = @cmds[0].to_job
    @job_store.register(@update_id, [@job])
  end

  it "sholud retry failed job" do
    0.upto(2) do |i|
      job_ticket = @job_store.get_job_tickets("", [])[0]
      expect(job_ticket.job_id).to eq @job.job_id
      expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::FAILED
      history = @job_store.get_execution_history(@job.job_id, {:limit => 1})[0]
      expect(history[:exit_code]).to eq Patriot::Command::ExitCode::FAILED
      job = @job_store.get_job(@job.job_id)
      if i == 2
        expect(@job).to be_failed_in @job_store
      else
        next_time = (history[:end_at] + 2).strftime("%Y-%m-%d %H-%M-%S")
        expect(job[Patriot::Command::START_DATETIME_ATTR].strftime("%Y-%m-%d %H-%M-%S")).to eq next_time
        expect(@job).to be_waited_in @job_store
        sleep 2
      end
    end
  end
end
