patriot-workflow-scheduler
=============

Patriot-workflow-scheduler is a workflow scheduler that can manage
batch jobs with complicated dependency relations.  The workflow
scheduler can deal with an extensible monolithic workflow.  Since the
various kinds of jobs can be consolidated into the monolithic
workflow, various combinations of data integration can be flexibly
achieved.

The scheduler offers an original DSL for batch configuration (PBC: Patriot
Batch Configuration).  The description of a complicated workflow can
be simplified by the DSL.  In addition, the DSL is designed to be
extensible so that customized job types can be easily integrated.


Features
-------

* Execution management of batch jobs with complicated dependency
* an extensible DSL for batch job configurations
* a simple web console for jobs administration


Getting Started
-------

### Install

```
% git clone https://github.com/CyberAgent/patriot-workflow-scheduler.git
% cd patriot-workflow-scheduler
% gem build patriot-workflow-scheduler.gemspec
% gem install patriot-workflow-scheduler-${VERSION}.gem
% patriot-init ${install_dir}
```

### Execute a sample job

Command line tools are available for processing jobs defined in PBC.
The tool can be triggered by the _patriot_ script.
The script takes three arguments: a tool name ('execute' for job execution), a target date of the jobs (in yyyy-MM-dd) and a path to the PBC file.
In processing the PBC files, a variable '\_date\_' will be replaced with the target date.

```
% cd ${install_dir}
% cat batch/sample/daily/test.pbc
sh{
  name "test"
  commands "echo '{_date_}' > /tmp/test.out"
}
% ./bin/patriot execute 2015-04-01 batch/sample/daily/test.pbc
% echo /tmp/test.out
2015-04-01

```

### Dependency Configuration

Dependencies between jobs are defined through *products*. 
The products produced/required by jobs are configured by _produce_ and _require_, respectively.
A job becomes ready to be executed when all products required by the job are available.
The products become available when all jobs which produce the product are finished.

To run jobs according to dependencies, the _strict_ option should be passed to the execute tool.

```
% cat flow_sample.pbc
sh{
  require ['product1'] # run after 'product1' is created
  name "consumer"
  commands "echo 'this is a consumer'"
}
sh{
  produce ['product1'] # this job creates 'product1'
  name "producer"
  commands "echo 'this is a producer'"
}
% ./bin/patriot execute --strict 2015-04-01 flow_sample.pbc
# execute echo 'this is a producer'
# execute echo 'this is a consumer'
```

### For more information

For understanding how to manage dependencies in a complicated workflow, the architecture of the scheduler, other command line tools, etc, 
please see the [Github pages](https://CyberAgent.github.io/patriot-workflow-scheduler).
   
Requirements
-------
* Ruby ( >= 1.9 )
* MySQL ( recommended for production use )

License
-------

Copyright © CyberAgent, Inc. All Rights Reserved.

This package is released under Apache License Ver. 2.0.  
http://www.apache.org/licenses/LICENSE-2.0.txt
