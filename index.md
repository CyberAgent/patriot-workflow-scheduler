---
layout: default
---
## Overview
The patriot workflow scheduler has developed at CyberAgent for
managing batch jobs on Hadoop-based data analytic platform (Patriot).
Batch jobs for the scheduler can be defined with original DSL (PBC:
Patriot Batch Config) which allows modular description of complex
dependency flows.

## Getting Started
### Executing a sample job

```
% git clone https://github.com/CyberAgent/patriot-workflow-scheduler.git
% cd patriot-workflow-scheduler
% gem build patriot-workflow-scheduler.gemspec
% sudo gem install patriot-workflow-scheduler-<$VERSION>.gem
% patriot-init ${INSTALL_DIR}
% cd ${INSTALL_DIR}
% ./bin/patriot execute 2015-04-01 batch/sample/daily/test.pbc
```

The initial target of this scheduler is daily batch jobs and the
script takes a date (or range of dates) as an argument.


### Configuring dependency

Dependencies between jobs are defined through *products*. A job
becomes ready to be executed when all products required by the job are
available. The products become available when all jobs which
produce the product are finished.

```
% cat flow_sample.pbc
sh{
  require ['product'] # run after 'product' is created
  name "consumer"
  commands "echo 'this is a consumer'"
}
sh{
  produce ['product'] # this job creates 'product'
  name "producer"
  commands "echo 'this is a producer'"
}
% ./bin/patriot execute --strict 2015-04-01 flow_sample.pbc
# execute echo 'this is a producer'
# execute echo 'this is a consumer'
```

## Running workers with JobStore

The JobStore has a role of managing dependency among jobs.
By using the JobStore, multiple jobs can be executed by workers in parallel and distributively (see [architecture](arch.html)).

1. Configure database.

    The recommended implementation of JobStore uses MySQL to manage the dependency. So MySQL database and tables should be configured. The three variables (PATRIOT\_DB, PATRIOT\_USER, PATRIOT\_PASSWORD) have to be set by users. The DDL file is included in this repository (in the __misc__ directory).

    ```
    % mysql
    > create database ${PATRIOT_DB}
    > grant all on ${PATRIOT_DB}.* to ${PATRIOT_USER}@'%' identified by '${PATRIOT_PASSWORD}'
    > exit;
    % mysql -u ${PATRIOT_USER} --password ${PATRIOT_PASSWORD} ${PATRIOT_DB} <  misc/mysql.sql
    ```

2. Install the DB adapter

    The DB adapter is included in the this repository and is implemented as a plugin.

    ```
    % cd ${CLONE_DIR}/plugins/patriot-mysql2-client
    % gem build patriot-mysql2-client.gemspec
    % sudo gem install patriot-mysql-client-${VERSION}.gem
    ```

    then

    ```
    % cd ${INSTALL_DIR}
    % ./bin/patriot plugin install ${CLONE_DIR}/plugins/patriot-mysql2-client/patriot-mysql-client-${VERSION}.gem
    ```

3. Configure JobStore and workers.

    An example configuration is as below.
    See [configuration](config.html) for more detail.

    ```
    % cat ${INSTALL_DIR}/config/patriot.ini
    [common]
    plugins=patriot-mysql2-client
    jobstore.root.class=Patriot::JobStore::RDBJobStore
    jobstore.root.adapter=mysql2
    jobstore.root.database=${PATRIOT_DB}
    jobstore.root.host=127.0.0.1
    jobstore.root.username=${PATRIOT_USER}
    jobstore.root.password=${PATRIOT_PASSWORD}

    log_factory = Patriot::Util::Logger::Log4rFactory
    log_level   = INFO
    log_format  = "[%l] %d %C (%h) : %m"
    log_outputters = stdout
    log_outputter.stdout.class = Log4r::StdoutOutputter

    [worker]
    nodes=test
    node.test.type=any
    node.test.threads=1
    log_outputters = file
    log_outputter.file.class = Log4r::DateFileOutputter
    log_outputter.file.dir =  ${LOG_DIR}
    log_outputter.file.file = patriot-worker.log
    ```

4. Start a worker

    ```
    % mkdir ${LOG_DIR} # if necessary
    % sudo ./bin/patriot worker start
    ```

5. Register jobs

    ```
    % ${INSTALL_DIR}/bin/patriot register YYYY-mm-DD ${batch config file}
    ```

    Jobs defined in the batch config file will be executed by the worker.
    See [batch config](pbc.html) for more detail on batch config files.

    In addition, a job management web console is available at 'http://${HOST}:36104/jobs/'


