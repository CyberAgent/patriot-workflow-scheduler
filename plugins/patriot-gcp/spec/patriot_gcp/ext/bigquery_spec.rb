require 'init_test'
require 'erb'
include PatriotGCP::Ext::BigQuery


describe PatriotGCP::Ext::BigQuery do
  it "should load data to bigquery" do
    bigquery_mock = double('Google::Cloud::Bigquery mock')
    dataset_mock  = double('Google::Cloud::Bigquery dataset mock')
    table_mock    = double('Google::Cloud::Bigquery table mock')
    job_mock      = double('Google::Cloud::Bigquery job mock')

    allow(Google::Cloud::Bigquery).to receive(:new).and_return(bigquery_mock)
    allow(bigquery_mock).to receive(:dataset).and_return(dataset_mock)
    allow(dataset_mock).to receive(:table).and_return(table_mock)
    allow(dataset_mock).to receive(:create_table)
    allow(dataset_mock).to receive(:load_job).and_return(job_mock)
    allow(table_mock).to receive(:nil?).and_return(true)
    allow(job_mock).to receive(:wait_until_done!)
    allow(job_mock).to receive(:failed?).and_return(false)
    allow(job_mock).to receive(:statistics)

    bq_load(
      File.join(SAMPLE_DIR, "hive_result.txt"),
      '/path/to/bigquery_keyfile',
      'test-project',
      'test-dataset',
      'test-table',
      'field1',
      {
        'fieldDelimiter' => '\t',
        'writeDisposition' => 'WRITE_APPEND'
      }
    )

    expect(ENV.fetch('BIGQUERY_KEYFILE')).to eq('/path/to/bigquery_keyfile')
    expect(Google::Cloud::Bigquery).to have_received(:new).with(
      project: 'test-project',
      retries: 3,
      timeout: 3600
    ).once
    expect(bigquery_mock).to have_received(:dataset).with('test-dataset').once
    expect(dataset_mock).to have_received(:load_job).with(
      'test-table',
      File.join(SAMPLE_DIR, "hive_result.txt"),
      format: nil,
      quote: nil,
      skip_leading: nil,
      write: 'WRITE_APPEND',
      delimiter: '\t',
      null_marker: nil
    ).once
    expect(job_mock).to have_received(:wait_until_done!).once
    expect(job_mock).to have_received(:failed?).once
    expect(job_mock).to have_received(:statistics).once
  end

  it "should set time" do
    bigquery_mock = double('Google::Cloud::Bigquery mock')
    dataset_mock  = double('Google::Cloud::Bigquery dataset mock')
    table_mock    = double('Google::Cloud::Bigquery table mock')
    job_mock      = double('Google::Cloud::Bigquery job mock')

    allow(Google::Cloud::Bigquery).to receive(:new).and_return(bigquery_mock)
    allow(bigquery_mock).to receive(:dataset).and_return(dataset_mock)
    allow(dataset_mock).to receive(:table).and_return(table_mock)
    allow(dataset_mock).to receive(:create_table)
    allow(dataset_mock).to receive(:load_job).and_return(job_mock)
    allow(job_mock).to receive(:wait_until_done!)
    allow(job_mock).to receive(:failed?).and_return(false)
    allow(job_mock).to receive(:statistics)

    bq_load(
      File.join(SAMPLE_DIR, "hive_result.txt"),
      '/path/to/bigquery_keyfile',
      'test-project',
      'test-dataset',
      'test-table',
      'field1',
      options = {
        'fieldDelimiter' => '\t',
        'writeDisposition' => 'WRITE_APPEND'
      },
      polling_interval = 1
    )

    expect(Google::Cloud::Bigquery).to have_received(:new)
      .with(
      project: 'test-project',
      retries: 3,
      timeout: 60
    ).once
    expect(Google::Cloud::Bigquery).to have_received(:new)
    expect(job_mock).to have_received(:wait_until_done!).once
    expect(job_mock).to have_received(:failed?).once
    expect(job_mock).to have_received(:statistics).once
  end

  it "raises BigQueryException when not finishing in time" do
    bigquery_mock = double('Google::Cloud::Bigquery mock')
    dataset_mock  = double('Google::Cloud::Bigquery dataset mock')
    table_mock    = double('Google::Cloud::Bigquery table mock')

    allow(Google::Cloud::Bigquery).to receive(:new).and_return(bigquery_mock)
    allow(bigquery_mock).to receive(:dataset).and_return(dataset_mock)

    # execution expired (Google::Cloud::Error)
    allow(dataset_mock).to receive(:table).and_return(table_mock)
    allow(dataset_mock).to receive(:create_table)
    allow(dataset_mock).to receive(:load_job).and_raise(Google::Cloud::Error)

    expect {
      bq_load(
        File.join(SAMPLE_DIR, "hive_result.txt"),
        '/path/to/bigquery_keyfile',
        'test-project',
        'test-dataset',
        'test-table',
        'field1',
        options = {
          'fieldDelimiter' => '\t',
          'writeDisposition' => 'WRITE_APPEND'
        }
      )
    }.to raise_error(Google::Cloud::Error)
  end

  it "raises BigQueryException when getting error from api" do
    bigquery_mock = double('Google::Cloud::Bigquery mock')
    dataset_mock  = double('Google::Cloud::Bigquery dataset mock')
    table_mock    = double('Google::Cloud::Bigquery table mock')
    job_mock      = double('Google::Cloud::Bigquery job mock')

    allow(Google::Cloud::Bigquery).to receive(:new).and_return(bigquery_mock)
    allow(bigquery_mock).to receive(:dataset).and_return(dataset_mock)
    allow(dataset_mock).to receive(:table).and_return(table_mock)
    allow(dataset_mock).to receive(:create_table)
    allow(dataset_mock).to receive(:load_job).and_return(job_mock)
    allow(job_mock).to receive(:wait_until_done!)
    allow(job_mock).to receive(:failed?).and_return(true)
    allow(job_mock).to receive(:errors)

    expect {
      bq_load(
        File.join(SAMPLE_DIR, "hive_result.txt"),
        '/path/to/bigquery_keyfile',
        'test-project',
        'test-dataset',
        'test-table',
        'field1',
        options = {
          'fieldDelimiter' => '\t',
          'writeDisposition' => 'WRITE_APPEND'
        }
      )
    }.to raise_error(BigQueryException)

    expect(job_mock).to have_received(:wait_until_done!).once
    expect(job_mock).to have_received(:failed?).once
    expect(job_mock).to have_received(:errors).once
  end
end
