require 'rubygems'
require 'rspec'

$ROOT_PATH = $home = File.expand_path(File.dirname(File.expand_path(__FILE__)) + "/..")
$: <<  "#{$home}/lib"
$: <<  "#{$home}/spec"

require 'patriot'

# TODO remove
job_limit = 10

require 'helper'

$: << File.join($home, "plugins", "patriot-mysql2-client", "lib")
require 'patriot/util/db_client/mysql2_client'
TEST_DB_TYPE = 'mysql2'
# require 'patriot/util/db_client/sqlite3_client'
# TEST_DB_TYPE = 'sqlite3'



# truncate dtabase
class TestDBInitiator
  include Patriot::Util::DBClient
  def truncate_database
    dbconfig = config_for_test(nil, TEST_DB_TYPE)
    db = read_dbconfig('jobstore.root', dbconfig)
    connect(db) do |c|
      c.delete('flows', {})
      c.delete('consumers', {})
      c.delete('producers', {})
      c.delete('jobs', {})
      c.insert('jobs', 
               {:job_id    => Patriot::JobStore::INITIATOR_JOB_ID,
                :update_id => Time.now.to_i,
                :state     => Patriot::JobStore::JobState::SUCCEEDED}
              )
    end
  end
end

TestDBInitiator.new.truncate_database

