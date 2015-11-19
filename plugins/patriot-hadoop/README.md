patriot-hadoop plugin
=============

This plugin adds some commands for Patriot Workflow Scheduler to collaborate with Hadoop-related softwares.


Implemented Commands
-------------

### hive

This command enables you to execute a hive query. The result is stored in the directory you indicate.


Option Name | Description
----------- | ------------
hive_ql | Set the hive query you want to execute.
output_prefix | Set the directory prefix where the result and the query should be stored. They are saved as _output_prefix_.tsv and _output_prefix_.hql. If this directive isn't provided, `hive` command would save them as `/tmp/<job_id>.hql` and `/tmp/<job_id>.tsv`.
exec_user | Set the user name who executes the query if needed. For example, this directive could be used when the query inserts data into Hive table and its operation needs specific authentication.
props | Provide Hive configuration properties if needed. These properties are stored within the query file.
name_suffix | Set a name suffix for job_id if needed.


#### Example

You can use `hive` command in your PBC file. Generated TSV file can be passed to following commands. Here is a simplified example of a PBC file. This PBC executes hive query and puts the result into HDFS.

```
composite_job {
  name 'execute_daily_summary'
  name_suffix '#{_date_}'

  hive {
    name_suffix daily_summary_#{_date_}
    output_prefix /tmp/execute_daily_summary_#{_date_}
    hive_ql 'SELECT ...'
  }

  sh {
    name hdfs_put_daily_summary_#{_date_}
    commands <<-EOS
      hadoop fs -put /tmp/execute_daily_summary_#{_date_}.tsv /tmp/execute_daily_summary_#{_date_}
    EOS
  }
}
```
