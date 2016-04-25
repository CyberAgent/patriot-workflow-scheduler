patriot-aws plugin
=============

This plugin adds some commands for Patriot Workflow Scheduler to collaborate with Amazon Web Services (AWS).


Implemented Commands
-------------

### s3

This command enables you to deal with Amazon S3.

Option Name | Description
----------- | ------------
name | Base name of this job.
name_suffix | Name suffix for job_id if needed.
inifile | Location of the ini file if needed. Assumed format is described below.
command | Command to execute
src | Source path
dest | Destination path
options | Options, such as credentials, a region and options passed to Amazon S3 API if needed. You can also set credentials and a region in inifile.

#### inifile

An ini file for this plugin should have the following directives:

```
[common]
access_key_id = <your access_key_id>
secret_access_key = <your secret_access_key>
region = <region>
```

or

```
[common]
access_key_id = <your access_key_id>
secret_access_key = <your secret_access_key>

[s3]
region = <region>
```

Note: you can also set credentials and a region in a PBC file.

#### Example

You can use `s3` command in your PBC file like the following.

```
s3 {
  name 'log'
  name_suffix _date_
  inifile '/path/to/aws.ini'
  command 'copy'
  options region: 'ap-northeast-1'
  src '/path/to/file_to_upload'
  dest 's3://bucket_name/object_name'
}
```

```
s3 {
  name 'log'
  name_suffix _date_
  inifile '/path/to/aws.ini'
  command 'copy'
  options access_key_id: '<your access_key_id>', secret_access_key: '<your secret_access_key>', region: '<region>'
  src '/path/to/file_to_upload'
  dest 's3://bucket_name/object_name'
}
```

Note: you can pass options to Amazon S3 API.
```
  ...
  options region: 'ap-northeast-1', cmd_opts: { multipart_threshold: 5_242_880 }
  ...
```
For official information, see http://docs.aws.amazon.com/sdkforruby/api/Aws/S3/Object.html#upload_file-instance_method
