require 'init_test'
require 'erb'
include PatriotGCP::Ext::BigQuery


describe PatriotGCP::Ext::BigQuery do

  before :each do 
    allow(Google::APIClient::KeyUtils).to receive(:load_from_pkcs12).with('/path/to/keyfile', 'key_pass').and_return('test-key')
    allow(Signet::OAuth2::Client).to receive(:new).and_return(double('auth-client-mock', {"fetch_access_token!" => true}))
    @config = config_for_test
  end


  it "sholud load data to bigquery" do
    api_client_mock = double('api-client-mock')
    allow(api_client_mock).to receive(:discovered_api).with('bigquery', 'v2'){
        double(nil,
               {:jobs => double(nil,
                                {:get => "GET",
                                 :insert => "INSERT"})})
    }
    allow(api_client_mock).to receive(:execute).with(hash_including(:api_method => 'INSERT',
                                                                    :parameters => {
                                                                        'projectId' => 'test-project',
                                                                        'uploadType' => 'multipart'
                                                                    })){
        double(nil,
               {:response => double(nil,
                                    {:body => '{"jobReference": {"jobId": "job_id01"}}'})})
    }
    allow(api_client_mock).to receive(:execute).with(hash_including(:api_method => 'GET',
                                                                    :parameters => {
                                                                        'projectId' => 'test-project',
                                                                        'jobId' => "job_id01"
                                                                    })){
        double(nil,
               {:response => double(nil,
                                    {:body => '{"status": {"state": "DONE"},
                                                "statistics": {"insertline": 1}}'})})
    }

    allow(Google::APIClient).to receive(:new).and_return(api_client_mock)
    expect(api_client_mock).to receive(:execute).with(hash_including(:api_method => "INSERT")).once
    expect(api_client_mock).to receive(:execute).with(hash_including(:api_method => "GET")).once
    bq_load(File.join(SAMPLE_DIR, "hive_result.txt"),
            '/path/to/keyfile',
            'key_pass',
            'test-account@developer.gserviceaccount.com',
            'test-project',
            'test-dataset',
            'test-table',
            'field1',
            options={'fieldDelimiter' => '\t',
                     'writeDisposition' => 'WRITE_APPEND',
                     'allowLargeResults' => true})
  end


  it "raises BigQueryException when not finishing in time" do
    api_client_mock = double('api-client-mock')
    allow(api_client_mock).to receive(:discovered_api).with('bigquery', 'v2'){
        double(nil,
               {:jobs => double(nil,
                                {:get => "GET",
                                 :insert => "INSERT"})})
    }
    allow(api_client_mock).to receive(:execute).with(hash_including(:api_method => 'INSERT',
                                                                    :parameters => {
                                                                        'projectId' => 'test-project',
                                                                        'uploadType' => 'multipart'
                                                                    })){
        double(nil,
               {:response => double(nil,
                                    {:body => '{"jobReference": {"jobId": "job_id01"}}'})})
    }

    allow(Google::APIClient).to receive(:new).and_return(api_client_mock)
    expect(api_client_mock).to receive(:execute).with(hash_including(:api_method => "INSERT")).once
    expect {
        bq_load(File.join(SAMPLE_DIR, "hive_result.txt"),
                '/path/to/keyfile',
                'key_pass',
                'test-account@developer.gserviceaccount.com',
                'test-project',
                'test-dataset',
                'test-table',
                'field1',
                options={'fieldDelimiter' => '\t',
                         'writeDisposition' => 'WRITE_APPEND',
                         'allowLargeResults' => true},
                polling_interval=0)
    }.to raise_error(BigQueryException)

  end


  it "raises BigQueryException when getting error from api" do
    api_client_mock = double('api-client-mock')
    allow(api_client_mock).to receive(:discovered_api).with(
      'bigquery', 'v2'
    ){
      double(
        nil, 
        {:jobs => double(
          nil,
          {:get => "GET", :insert => "INSERT"}
        )}
      )
    }

    allow(api_client_mock).to receive(:execute).with(
      hash_including(
        :api_method => 'INSERT',
        :parameters => {
          'projectId' => 'test-project',
          'uploadType' => 'multipart'
        }
      )
    ){
      double(
        nil,
        {:response => double(
          nil, 
          {
            :body => '{"status": {
              "state": "DONE"
              "errorResult"=>{
                "reason"=>"invalid",
                "message"=>"Too many errors encountered. Limit is: 0."
              },
              "errors"=>[
                {
                  "reason"=>"invalid",
                  "location"=>"File: 0 / Line:100 / Field:6",
                  "message"=>"Invalid argument: 1,234.0"
                },
                {
                  "reason"=>"invalid",
                  "message"=>"Too many errors encountered. Limit is: 0."
                }
              ]
            }}'
          }
        )}
      )
    }
      
    allow(Google::APIClient).to receive(:new).and_return(api_client_mock)
    expect(api_client_mock).to receive(:execute).with(hash_including(:api_method => "INSERT")).once
    expect(api_client_mock).to receive(:execute).with(hash_including(:api_method => "GET")).never
    expect {
      bq_load(File.join(SAMPLE_DIR, "hive_result.txt"),
              '/path/to/keyfile',
              'key_pass',
              'test-account@developer.gserviceaccount.com',
              'test-project',
              'test-dataset',
              'test-table',
              'field1',
              options={'fieldDelimiter' => '\t',
                       'writeDisposition' => 'WRITE_APPEND',
                       'allowLargeResults' => true})
    }.to raise_error(BigQueryException)
  end


  it "loads data to bigquery but fails to register a job" do
    api_client_mock = double('api-client-mock')
    allow(api_client_mock).to receive(:discovered_api).with('bigquery', 'v2'){
        double(nil,
               {:jobs => double(nil,
                                {:get => "GET",
                                 :insert => "INSERT"})})
    }

    allow(api_client_mock).to receive(:execute).with(hash_including(:api_method => 'INSERT',
                                                                    :parameters => {
                                                                        'projectId' => 'test-project',
                                                                        'uploadType' => 'multipart'
                                                                    })){
        double(nil, {:response => double(nil, {:body => '{}'})})  # response doesn't include a job ID
    }   
    allow(Google::APIClient).to receive(:new).and_return(api_client_mock)
    expect(api_client_mock).to receive(:execute).with(hash_including(:api_method => "INSERT")).once
    expect(api_client_mock).to receive(:execute).with(hash_including(:api_method => "GET")).never
    expect {
      bq_load(File.join(SAMPLE_DIR, "hive_result.txt"),
              '/path/to/keyfile',
              'key_pass',
              'test-account@developer.gserviceaccount.com',
              'test-project',
              'test-dataset',
              'test-table',
              'field1',
              options={'fieldDelimiter' => '\t',
                       'writeDisposition' => 'WRITE_APPEND',
                       'allowLargeResults' => true})
    }.to raise_error(BigQueryException)
  end


  it "loads data to bigquery but the job fails" do
    api_client_mock = double('api-client-mock')
    allow(api_client_mock).to receive(:discovered_api).with('bigquery', 'v2'){
        double(nil,
               {:jobs => double(nil,
                                {:get => "GET",
                                 :insert => "INSERT"})})
    }
    allow(api_client_mock).to receive(:execute).with(hash_including(:api_method => 'INSERT',
                                                                    :parameters => {
                                                                        'projectId' => 'test-project',
                                                                        'uploadType' => 'multipart'
                                                                    })){
        double(nil,
               {:response => double(nil,
                                    {:body => '{"jobReference": {"jobId": "job_id01"}}'})})
    }

    # response contains errors
    allow(api_client_mock).to receive(:execute).with(hash_including(:api_method => 'GET',
                                                                    :parameters => {
                                                                        'projectId' => 'test-project',
                                                                        'jobId' => "job_id01"
                                                                    })){
        double(nil,
               {:response => double(nil,
                                    {:body => '{"status": {"state": "DONE", "errors": ["test error"]},
                                                "statistics": {"insertline": 1}}'})})
    }

    allow(Google::APIClient).to receive(:new).and_return(api_client_mock)
    expect(api_client_mock).to receive(:execute).with(hash_including(:api_method => "INSERT")).once
    expect(api_client_mock).to receive(:execute).with(hash_including(:api_method => "GET")).once
    expect {
      bq_load(File.join(SAMPLE_DIR, "hive_result.txt"),
              '/path/to/keyfile',
              'key_pass',
              'test-account@developer.gserviceaccount.com',
              'test-project',
              'test-dataset',
              'test-table',
              'field1',
              options={'fieldDelimiter' => '\t',
                       'writeDisposition' => 'WRITE_APPEND',
                       'allowLargeResults' => true})
    }.to raise_error(BigQueryException)
  end
end
