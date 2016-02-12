require 'init_test'

describe Patriot::Util::Param do
  before :each do
    @obj = "double".extend(Patriot::Util::Param)
  end

  describe ".eval_string_attr" do
    it "should eval string with vertical bar" do
      expect(@obj.eval_string_attr '#{"abc|def"}').to eq "abc|def"
    end

    it "should return same string" do
      expect(@obj.eval_string_attr("const")).to eq "const"
    end
    
    it "should expand nested string" do
      str = '#{-5.2.round()}'
      expect(@obj.eval_string_attr(str)).to eq "-5"
      expect(@obj.eval_string_attr('prefix#{-5.2.round()}postfix')).to eq "prefix-5postfix"
      expect(@obj.eval_string_attr('prefix#{"#{-5.2.round()}".size}postfix')).to eq "prefix2postfix"
    end

    it "should set a string variable " do
      expect(@obj.eval_string_attr('bar#{var}', {'var' => 'foo'})).to eq "barfoo"
    end

    it "should set an object variable " do
      var = "var"
      def var.foo; 'foo'; end
      expect(@obj.eval_string_attr('bar#{var.foo}', {'var' => var})).to eq "barfoo"
      expect(@obj.eval_string_attr('bar#{var1.foo}#{var2}', {'var1' => var, 'var2' => "baz"})).to eq "barfoobaz"
    end
  end

end
