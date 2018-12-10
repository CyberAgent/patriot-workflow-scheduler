patriot-gcp plugin
=============

This plugin adds some commands for Patriot Workflow Scheduler to collaborate with Google Cloud Platform (GCP).


Implemented Commands
-------------

### load_to_bigquery

This command enables you to upload data into BigQuery.

Option Name | Required | Description
----------- | :------: | ------------
inifile | yes | Indicate the location of the ini file. Assumed format is described below.
project_id | yes | Set the name of the project id to use.
dataset | yes | Set the name of the dataset you want to upload data into.
table | yes | Set the name of the table under the dataset. If the table doesn't exist, it will be created along with the schema you indicate.
schema | | Set the schema which generated data would have.
input_file | | Indicate the location of the file you want to upload.
name_suffix | | Set a name suffix for job_id if needed.
options | | Set BigQuery's load options if needed. These options are set under "configuration.load". For official information, see https://cloud.google.com/bigquery/docs/reference/v2/jobs#configuration.load
polling_interval | | Set polling interval(min) if needed. Default is 60 mins. If a registered job doesn't finish within the specified polling time, you should check if the job would succeed later on. Its job_id would be written in the log file.


#### inifile

An ini file for this plugin should have the following directives:

```
[gcp]
bigquery_keyfile = <path to json credential file>
```


#### Example

You can use `load_to_bigquery` command in your PBC file like the following. If the indicated table doesn't exist in BigQuery, it would be created automatically along with the schema. By using variables as `_month_`, data will be splitted into each month. Note that a table name in BigQuery must contain only letters (a-z, A-Z), numbers (0-9), or underscores (_).

```
load_to_bigquery {
  input_file "/tmp/data_#{_date_}.tsv"
  inifile '/home/foo/.gcp.ini'
  project_id 'the_project_id'
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

---

### bq

This command enables you to upload data into BigQuery.


Option Name | Required | Description
----------- | :------: | ------------
inifile | yes | Indicate the location of the ini file. Assumed format is described below.
project_id | yes | Set the name of the project id to use.
name_suffix | yes | Set job name suffix. To set only _date_ is not allowed to avoid job name duplicate.
statement | yes | Set SQL statement to execute.


#### inifile

An ini file for this plugin should have the following directives:

```
[gcp]
bigquery_keyfile = <path to json credential file>
```


#### Example

You can use `bq` command in your PBC file like the following.

```
bq {
  inifile '/home/foo/.gcp.ini'
  name_suffix "insert_some_data_#{_date_}"
  project_id 'your-project'
  statement "INSERT INTO `dataset1.table1` (column1) SELECT dt FROM `dataset2.table2` WHERE dt = '2018-05-21'"
}
```

#### statement examples

```
# insert fixed values
statement "INSERT INTO `dataset1.table1` (column1) VALUES ('A')"

# insert values
statement "INSERT INTO `dataset1.table1` (column1) SELECT dt FROM `dataset2.table2` WHERE dt = '2018-05-21'"

# insert values from partitioned table
statement "INSERT INTO `dataset1.table1` (column1) SELECT dt FROM `dataset2.partitioned_table1` WHERE _PARTITIONTIME = '2018-05-21'"

# insert values from partitioned table to partitioned table
statement "INSERT INTO `dataset1.partitioned_table1` (_PARTITIONTIME, dt) SELECT _PARTITIONTIME, dt FROM `dataset2.partitioned_table2` WHERE _PARTITIONTIME = '2018-05-21'"

# delete from partitioned table
statement "DELETE FROM `dataset1.partitioned_table1` WHERE _PARTITIONTIME = '2018-05-21'"
```

* It is not allowed to use decoration characters like "$". Please set `_PARTITIONTIME` to use partitioned table.

---

### gcs

This command enables you to upload, download, delete data to/from Google Cloud Storage.


Option Name | Required | Description
----------- | :------: | ------------
inifile | yes | Location of the ini file. Assumed format is described below.
project_id | yes | Project ID to use.
name_suffix | yes | Suffix of Job ID. To set only _date_ is not allowed to avoid job name duplicate.
bucket | yes | Bucket ID to use.
command | yes | `create_file` / `download` / `delete` ( use `create_file` to upload files. )
source_file | no | Source file.
dest_file | no | Destination file.


#### inifile

An ini file for this plugin should have the following directives:

```
[gcp]
gcs_keyfile = <path to json credential file>
```


#### Example

You can use `gcs` command in your PBC file as follows.

##### create_file

```
gcs {
  name_suffix "test_#{_date_}"
  inifile '/path/to/inifile'
  project_id 'test_project_id'
  bucket 'test_bucket'
  command 'create_file'
  source_file '/path/to/source_file'
  dest_file '/path/to/dest_file'
}
```

##### download

```
gcs {
  ...
  command 'download'
  source_file '/path/to/source_file'
  dest_file '/path/to/dest_file'
}
```

##### delete

```
gcs {
  ...
  command 'delete'
  source_file '/path/to/source_file'
}
```
