patriot-gcp plugin
=============

This plugin adds some commands for Patriot Workflow Scheduler to collaborate with Google Cloud Platform (GCP).


Impremented Commands
-------------

### load_to_bigquery

This command enables you to upload data into BigQuery.


Option Name | Description
----------- | ------------
inifile | Indicate the location of the ini file. Assumed format is described below.
dataset | Set the name of the dataset you want to upload data into.
table | Set the name of the table under the dataset. If the table doesn't exist, it will be created along with the schema you indicate.
schema | Set the schema which generated data would have.
input_file | Indicate the location of the file you want to upload.
name_suffix | Set a name suffix for job_id if needed.
options | Set BigQuery's load options if needed. These options are set under "configuration.load". For official information, see https://cloud.google.com/bigquery/docs/reference/v2/jobs#configuration.load
polling_interval | Set polling interval(min) if needed. Default is 60 mins. If a registered job doesn't finish within the specified polling time, you should check if the job would succeed later on. Its job_id would be written in the log file.


#### inifile

An ini file for this plugin should have the following directives:

```
[gcp]
service_account = <your service account email address>
private_key = <the location of your p12 key file>
key_pass = <the key phrase for the private key>

[bigquery]
project_id = <project_id you want to upload into>
```


#### Example

You can use `load_to_bigquery` command in your PBC file like the following. If the indicated table doesn't exist in BigQuery, it would be created automatically along with the schema. By using variables as `_month_`, data will be splitted into each month. Note that a table name in BigQuery must contain only letters (a-z, A-Z), numbers (0-9), or underscores (_).

```
load_to_bigquery {
  input_file "/tmp/data_#{_date_}.tsv"
  inifile '/home/foo/.project.ini'
  dataset 'the_dataset'
  table 'the_table' + _month_.gsub(/-/, "_")
  schema 'fields' => [{ "name"=> "timestamp",
                        "type"=> "TIMESTAMP",
                        "mode"=> "REQUIRED"
                      },{
                        "name"=> "url",
                        "type"=> "STRING"
                      },{
                        "name"=> "impression",
                        "type"=> "INTEGER",
                        "mode"=> "REQUIRED"
                     }]
  options 'fieldDelimiter' => '\t',
          'writeDisposition' => 'WRITE_APPEND',
          'allowLargeResults' => true
}
```
