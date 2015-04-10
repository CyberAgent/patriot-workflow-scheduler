require 'init_test'

describe "Patriot::Tool::BatchParser" do
  before :each do
    @obj = Patriot::Tool::BatchParser.new(config_for_test)
  end

  it "should parse daily job" do
    pbc_file = File.join(ROOT_PATH, 'spec', 'pbc', 'cron', 'daily.pbc')
    commands = @obj.parse('2015-04-01', pbc_file)
    expect(commands.size).to eq 1
    expect(commands[0].job_id).to eq "sh_echo_2015-04-01_2015-04-01"
    expect(commands[0][:commands]).to contain_exactly 'echo 1'
  end

  it "should parse hourly job" do
    pbc_file = File.join(ROOT_PATH, 'spec', 'pbc', 'cron', 'hourly.pbc')
    commands = @obj.parse('2015-04-01', pbc_file)
    expect(commands.size).to eq 24
    0.upto(23).each do |h|
      expect(commands[h].job_id).to eq "sh_echo_#{sprintf("%02d",h)}_2015-04-01"
      expect(commands[h][:commands]).to contain_exactly "echo #{h}"
    end
  end

  it "should parse monthly job" do
    pbc_file = File.join(ROOT_PATH, 'spec', 'pbc', 'cron', 'monthly.pbc')
    commands = @obj.parse('2015-04-01', pbc_file)
    expect(commands.size).to eq 0
    @obj = Patriot::Tool::BatchParser.new(config_for_test)
    commands = @obj.parse('2015-03-31', pbc_file)
    expect(commands.size).to eq 1
    expect(commands[0].job_id).to eq "sh_echo_2015-03_2015-03-31"
    expect(commands[0][:commands]).to contain_exactly "echo 2015-03"

    @obj = Patriot::Tool::BatchParser.new(config_for_test)
    commands = @obj.parse('2015-02-28', pbc_file)
    expect(commands.size).to eq 1
    expect(commands[0].job_id).to eq "sh_echo_2015-02_2015-02-28"
    expect(commands[0][:commands]).to contain_exactly "echo 2015-02"
  end

  it "should parse weekly job" do
    # Monday and Wednesday
    pbc_file = File.join(ROOT_PATH, 'spec', 'pbc', 'cron', 'weekly.pbc')
    1.upto(7).each do |w|
      @obj = Patriot::Tool::BatchParser.new(config_for_test)
      date = DateTime.new(2015,4,w).strftime('%Y-%m-%d')
      commands = @obj.parse(date, pbc_file)
      case w
      when 1
        expect(commands.size).to eq 1
        expect(commands[0].job_id).to eq "sh_echo_Wednesday_2015-04-01"
        expect(commands[0][:commands]).to contain_exactly "echo 2015-04-01"
      when 6
        expect(commands.size).to eq 1
        expect(commands[0].job_id).to eq "sh_echo_Monday_2015-04-06"
        expect(commands[0][:commands]).to contain_exactly "echo 2015-04-06"
      else
        expect(commands.size).to eq 0
      end
    end
  end

end
