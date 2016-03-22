require 'init_test'
require 'patriot/job_store/job_ticket'

describe Patriot::JobStore::JobTicket do

  describe "initialize" do
    it "should be correct class" do
      obj = Patriot::JobStore::JobTicket.new("job_id", 2)
      expect(obj).to be_a Patriot::JobStore::JobTicket
      expect(obj.job_id).to eq "job_id"
      expect(obj.update_id).to eq 2
    end
  end
end
