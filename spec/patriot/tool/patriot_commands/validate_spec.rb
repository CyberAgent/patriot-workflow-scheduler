require 'init_test'

describe Patriot::Tool::PatriotCommands::Validate do

  describe "validete" do
    it "should show help" do
      args = ['help']
      Patriot::Tool::PatriotCommand.start(args)
    end
  end

  describe "validate_files" do
    before :all do
      @sh_pbc = "#{$ROOT_PATH}/spec/pbc/sh.pbc"
      @dup_sh_pbc = "#{$ROOT_PATH}/spec/pbc/dup_sh.pbc"
      @dup_sh_composite_pbc = "#{$ROOT_PATH}/spec/pbc/dup_sh_composite.pbc"
      @invalid_json_pbc = "#{$ROOT_PATH}/spec/pbc/invalid_json.pbc"
    end

    it "should validate correct a batch file" do
      args = ['validate', "--config=#{path_to_test_config}", @sh_pbc]
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
    end

    it "should validate correct a batch file with date" do
      args = ['validate', "--config=#{path_to_test_config}", @sh_pbc, '--date', '1970-01-01']
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
    end

    it "should report duplication" do
      args = ['validate', "--config=#{path_to_test_config}", @sh_pbc, @dup_sh_pbc]
      expect{Patriot::Tool::PatriotCommand.start(args)}.to raise_error
    end

    it "should report invalid syntax" do
      args = ['validate', "--config=#{path_to_test_config}", @invalid_json_pbc]
      expect{Patriot::Tool::PatriotCommand.start(args)}.to raise_error
    end

    it "should validate a correct composite command" do
      args = ['validate', "--config=#{path_to_test_config}", @dup_sh_composite_pbc]
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
    end

    it "should report duplication in a composite command" do
      args = ['validate', "--config=#{path_to_test_config}", @sh_pbc, @dup_sh_composite_pbc]
      expect{Patriot::Tool::PatriotCommand.start(args)}.to raise_error
    end
  end

end
