===========================
Getting Started
===========================

Requirements
==============

* Ruby ( >= 1.9 )
* MySQL ( recommended for production use )

Install
========

.. TODO make a developer page
  % git clone https://github.com/CyberAgent/patriot-workflow-scheduler.git
  % cd patriot-workflow-scheduler
  % gem build patriot-workflow-scheduler.gemspec
  % sudo gem install patriot-workflow-scheduler-<$VERSION>.gem
  % patriot-init ${INSTALL_DIR}

::

  % sudo gem install patriot-workflow-scheduler
  % patriot-init ${INSTALL_DIR}


Job Execution
===============

Command line tools are available for processing jobs defined in :doc:`PBC <pbc>`.
The tool can be triggered by :doc:`the patriot script <cli>`.
The script takes three arguments: a tool name ('execute' for job execution), a target date of the jobs (in yyyy-MM-dd) and a path to the PBC file. In processing the PBC files, a variable '_date_' will be replaced with the target date.

::

  % cd ${INSTALL_DIR}
  % ./bin/patriot execute 2015-04-01 batch/sample/daily/test.pbc

The initial target of this scheduler is daily batch jobs and the
script takes a date (or range of dates) as an argument.

Dependency Configuration
==========================

Dependencies between jobs are defined through *products*.
The products produced/required by jobs are configured by *produce* and *require*, respectively.
A job becomes ready to be executed when all products required by the job are available.
The products become available when all jobs which produce the product are finished.

To run jobs according to dependencies, the *strict* option should be passed to the execution tool.
(or use JobStore explained later)

::

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

Running workers with JobStore
================================

The JobStore has a role of managing dependency among jobs.
By using the JobStore, multiple jobs can be executed by workers in parallel and distributively (see :doc:`architecture <arch>`).

1. Configure database.

    The recommended implementation of JobStore uses MySQL to manage the dependency. So MySQL database and tables should be configured.
    The DDL file is included in this repository (in the `misc <https://github.com/CyberAgent/patriot-workflow-scheduler/tree/develop/misc>`_ directory).

    The below four variables have to be set by users.

    * PATRIOT\_DB : database which stores workflow information
    * PATRIOT\_DBHOST : host where database is located
    * PATRIOT\_USER : user for accessing the database
    * PATRIOT\_PASSWORD : password for accessing the database


    To configure the database, login to the PATRIOT\_DBHOST, then

    ::

      % mysql -u root -p
      > create database ${PATRIOT_DB};
      > grant all on ${PATRIOT_DB}.* to ${PATRIOT_USER}@'%' identified by '${PATRIOT_PASSWORD}';
      ( > grant all on ${PATRIOT_DB}.* to ${PATRIOT_USER}@'localhost' identified by '${PATRIOT_PASSWORD}'; # if case of localhost)
      > exit;
      % mysql -u ${PATRIOT_USER} -h ${PATRIOT_DBHOST} --password=${PATRIOT_PASSWORD} ${PATRIOT_DB} <  misc/mysql.sql

2. Install the DB adapter

    The DB adapter is included in the this repository and is implemented as a plugin.

    ::

      % cd ${CLONE_DIR}/plugins/patriot-mysql2-client
      % gem build patriot-mysql2-client.gemspec
      % sudo gem install patriot-mysql2-client-${VERSION}.gem

    then

    ::

      % cd ${INSTALL_DIR}
      % ./bin/patriot plugin install ${CLONE_DIR}/plugins/patriot-mysql2-client/patriot-mysql-client-${VERSION}.gem

    For more detail on the plugin tool, please refer to :ref:`the CLI page <cli_plugin>`.

3. Configure JobStore and workers.

    An example configuration is as below.
    See :doc:`system configuration <config>` for more detail.

    ::

      % cat ${INSTALL_DIR}/config/patriot.ini
      [common]
      plugins=patriot-mysql2-client
      jobstore.root.class=Patriot::JobStore::RDBJobStore
      jobstore.root.adapter=mysql2
      jobstore.root.database=${PATRIOT_DB}
      jobstore.root.host=${PATRIOT_DBHOST}
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

4. Start a worker

    A worker process for executing jobs stored in the JobStore can be started by :ref:`the worker tool <cli_worker>`.

    ::

      % mkdir ${LOG_DIR} # if necessary
      % sudo ./bin/patriot worker start

5. Register jobs

    Jobs defined in PBC files can be registered to the JobStore by :ref:`the register tool <cli_register>`.

    ::

      % ${INSTALL_DIR}/bin/patriot register YYYY-mm-DD ${batch config file}

    The jobs defined in the batch config file will be executed by the worker.
    See :doc:`batch config <pbc>` for more detail on batch config files.

    In addition, a job management web console is available at 'http://${HOST}:36104/jobs/'


