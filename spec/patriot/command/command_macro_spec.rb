require 'init_test'

describe Patriot::Command::CommandMacro do 

  before :all do
    @base = Class.new do
      class << self
        include Patriot::Command::CommandMacro
      end
    end
    @base.class_eval do
      def param(p)
        @param = p
      end
    end
  end

  describe "command_attr" do 
    it "should register command attrs" do 
      @cls = Class.new(@base) do 
        command_attr :a, :b
      end
      expect(@cls.command_attrs.keys).to contain_exactly(:a,:b)
      obj = @cls.new
      obj.instance_eval do
        a 'a'
      end
      expect(obj.instance_variable_get(:@param)['a']).to eq  'a'
    end

    it "should register command attrs with default values" do 
      @cls = Class.new(@base) do 
        command_attr :a => "da", :b => "db"
      end
      expect(@cls.command_attrs[:a]).to eq "da"
      expect(@cls.command_attrs[:b]).to eq "db"
    end

    it "should register command attrs with transformation" do 
      @cls = Class.new(@base) do 
        command_attr :a, :b do |cmd, k, v|
          if k == :a
            cmd.instance_variable_set("@#{k}".to_sym, v*10)
          else
            cmd.instance_variable_set("@#{k}".to_sym, [v])
          end
        end
      end
      obj = @cls.new
      obj.instance_eval do
        a 1
        b 2
      end
      expect(obj.instance_variable_get(:@a)).to eq 10
      expect(obj.instance_variable_get(:@b)).to eq [2]
    end

    it "should raise error for reserved words" do
      expect{
        Class.new(@base) do
          command_attr :instance_eval do |c, k, v|
            puts v
          end
        end
      }.to raise_error
    end
  end

  describe "volaitle_attr" do
    it "should register volatiel attrs " do 
      @cls = Class.new(@base) do 
        volatile_attr :a 
        command_attr :b
      end
      expect(@cls.volatile_attrs).to contain_exactly(:a)
      expect(@cls.command_attrs.keys).to contain_exactly(:a, :b)
    end
  end

  describe "valiate_attr" do
    it "should register validattion logic " do 
      @cls = Class.new(@base) do 
        command_attr :a
        validate_attr :a do |cmd, k, v|
          k == v
        end
      end
      obj = @cls.new
      obj.instance_eval do
        a 1
      end
      expect(@cls.validation_logics[:a].size).to eq 1
      expect(@cls.validation_logics[:a][0].call(@cls, "a", "b")).to be false
      expect(@cls.validation_logics[:a][0].call(@cls, "a", "a")).to be true
    end

    it "should register exisitence validattion" do 
      @cls = Class.new(@base) do 
        command_attr :a
        validate_existence :a 
      end
      obj = @cls.new
      expect(@cls.validation_logics[:a].size).to eq 1
      expect(@cls.validation_logics[:a][0].call(@cls, "a", nil)).to be false
      expect(@cls.validation_logics[:a][0].call(@cls, "a", "a")).to be true
    end
  end


end
