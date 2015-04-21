require 'init_test'

describe Patriot::Util::DBClient::SQLite3Client do
  $home = PLUGIN_ROOT

  before :each do 
    expect(SQLite3::Database).to receive(:new).and_return(Stub::SQLite3Connection.new)
    @obj = Patriot::Util::DBClient::SQLite3Client.new({:database => "test"})
  end

  describe "select" do
    it "should execute select" do
      query ="SELECT * FROM tbl WHERE col = 'val'"
      expect(@obj).to receive(:execute_statement).with(query, :select)
      @obj.select("tbl", {:col => "val"})
    end

    it "should execute select with multiple condition" do
      query ="SELECT * FROM tbl WHERE col1 = 'val1' AND col2 = 1"
      expect(@obj).to receive(:execute_statement).with(query, :select)
      @obj.select("tbl", {:col1 => "val1", :col2 => 1})
    end
  end

  describe "insert" do
    it "should execute an insert statement" do
      query ="INSERT INTO tbl (col) VALUES ('val')"
      expect(@obj).to receive(:execute_statement).with(query, :insert)
      @obj.insert("tbl", {:col => "val"})
    end

    it "should execute an insert statement with escaped value" do
      query = "INSERT INTO tbl (col) VALUES ('val\"')"
      expect(@obj).to receive(:execute_statement).with(query, :insert)
      @obj.insert("tbl", {:col => "val\""})
    end
  end

  describe "update" do
    it "should execute an update statement" do
      query ="UPDATE tbl SET col1 = 'val2',col2 = 2 WHERE col1 = 'val1' AND col2 = 1"
      expect(@obj).to receive(:execute_statement).with(query, :update)
      @obj.update("tbl", {:col1 => "val2", :col2 => 2}, {:col1 => 'val1', :col2 =>1})
    end
    it "should execute an update statement with escaped value" do
      query = "UPDATE tbl SET col1 = 'val''2',col2 = 2 WHERE col1 = 'val1' AND col2 = 1"
      expect(@obj).to receive(:execute_statement).with(query, :update)
      @obj.update("tbl", {:col1 => "val'2", :col2 => 2}, {:col1 => 'val1', :col2 =>1})
    end
  end

  describe "delete" do
    it "should execute delete" do
      query ="DELETE FROM tbl WHERE col1 = 'val1' AND col2 = 1"
      expect(@obj).to receive(:execute_statement).with(query, :update)
      @obj.delete("tbl", {:col1 => 'val1', :col2 =>1})
    end
  end
end
