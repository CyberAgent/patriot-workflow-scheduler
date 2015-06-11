patriot-workflow-scheduler
=============

Patriot-workflow-scheduler is a workflow scheduler that can manage
batch jobs with complicated dependency relations.  The workflow
scheduler can deal with a extensible monolithic workflow.  Since the
various kinds of jobs can be consolidated into the monolithic
workflow, various combinations of data integration can be flexibly
achieved.

The scheduler offers a original DSL for batch configuration (Patriot
Batch Configuration).  The description of a complicated workflows can
be simplified by the DSL.  In addition, the DSL is designed to be
extensible so that customized job types can be easily integrated.


Features
-------

* Execution management of batch jobs with complicated dependency
* an extensible DSL for batch job configurations
* a simple web console for jobs administration


Getting Started
-------

```
% git clone https://github.com/CyberAgent/patriot-workflow-scheduler.git
% cd patriot-workflow-scheduler
% gem build patriot-workflow-scheduler.gemspec
% gem install patriot-workflow-scheduler-${VERSION}.gem
% patriot-init ${install_dir}
% cd ${install_dir}
% ./bin/patriot execute 2015-04-01 batch/sample/daily/test.pbc
```

For more information, please see the Github pages.

   
Requirements
-------
* Ruby 1.9
* MySQL (recommended for production use)

License
-------

Copyright © CyberAgent, Inc. All Rights Reserved.

This package is released under Apache License Ver. 2.0.  
http://www.apache.org/licenses/LICENSE-2.0.txt
