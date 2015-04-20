require 'rubygems'
require 'rspec'

ROOT_PATH = $home = File.expand_path(File.dirname(File.expand_path(__FILE__)) + "/..")
$: <<  "#{$home}/lib"
$: <<  "#{$home}/spec"

require 'patriot'

require 'helper'

unless ENV['TEST_DBMS'].nil?
  case ENV['TEST_DBMS']
  when 'sqlite3' then
    $: << File.join($home, "plugins", "patriot-sqlite3-client", "lib")
    require 'patriot/util/db_client/sqlite3_client'
  when 'mysql2' then
    $: << File.join($home, "plugins", "patriot-mysql2-client", "lib")
    require 'patriot/util/db_client/mysql2_client'
  else
    raise "unsupported dbms #{ENV['TEST_DBMS']}"
  end

  # truncate database
  class TestDBInitiator
    include Patriot::Util::DBClient
    def truncate_database
      dbconfig = config_for_test(nil, ENV['TEST_DBMS'])
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
end


