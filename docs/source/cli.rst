=====================
CLI tools
=====================

::

  % ./bin/patriot
  Commands:
    patriot execute [options] <yyyy-mm-dd[,yyyy-mm-dd]> <files/paths>+       # execute patriot jobs directly
    patriot help [COMMAND]                                                   # Describe available commands or one specific command
    patriot job [delete|show_dependency] job_id [job_id ..]                  # manage job(s) in job store
    patriot plugin [options] install <path to plugin>                        # manage plugins
    patriot register [OPTIONS] yyyy-mm-dd[,yyyy-mm-dd] path [path file ...]  # register jobs
    patriot validate [OPTIONS] path [path file ...]                          # validate pbc files
    patriot worker [options] [start|stop]                                    # controll worker
    patriot worker_admin [options] [start|stop|restart|sleep|wake|status]    # controll remote workers

  Options:
    -c, [--config=CONFIG]  # path to configuration file

.. _cli_register:

Register
===================================


By using this tool, jobs described in given PBC files can be
registered to JobStore so that workers can execute the jobs according to their dependency.

This tool requires two arguments, date (or date range) and files (or a directory) to be parsed.
The date should be formatted in yyyy-MM-dd (e.g., 2014-12-31) and be comma-separated in case of range (e.g., 2015-01-01,2015-01-31).

Specifying Execution Interval
-----------------------------------------------------------

Jobs may have different execution intervals (e.g., daily and monthly).
The interval can be specified by using pre processor at the top of each PBC file.
For instance,

.. code-block:: ruby

  #interval 0 0 1 * *
  sh{
    name 'monthly'
    commands 'echo monthly'
  }

the above job would be executed for the 1st day of every month.
The default interval is set to daily (i.e., '0 0 \* \* \*'), and therefore, you can ignore the pro processor for daily jobs.

In addition, the interval can accept key works ('end_of_every_month') for jobs which should be executed for the end of every month.
The below is an example of such job.

.. code-block:: ruby

  #interval end_of_every_month
  sh{
    name 'end_of_month'
    commands 'echo end of month'
  }
  ```


Specifying Execution Interval by Directories (deprecated)
-----------------------------------------------------------

The interval can be also determined by directory names.
If the pass to a PBC file contains a directory named *'daily'*, the jobs in the PBC files are treated as daily jobs.
PBC files located in a sub directory of *'monthly'* directory, the PBC files are regarded as ones of monthly jobs and processed on only the end of each month.
For weekly jobs, PBC files should be stored in the directory *'weekly/${wday}'* where the *wday* is a number for the day of week (0 is Sunday).



::

  % ./bin/patriot help register
  Usage:
    patriot register [OPTIONS] yyyy-mm-dd[,yyyy-mm-dd] path [path file ...]

  Options:
    -f, [--filter=FILTER]                  # regular expression for Ruby
    -d, [--debug], [--no-debug]            # debug mode flag
    -p, [--priority=N]                     # job priority
                                           # Default: 1
    -s, [--state=N]                        # register as specified state
        [--keep-state], [--no-keep-state]  # don't change current state of jobs (only change definition)
        [--retry-dep], [--no-retry-dep]    # set states of dependent jobs to WAIT
        [--update-id=UPDATE_ID]            # default value is current unixtime
                                           # Default: Time.now.to_i
    -c, [--config=CONFIG]                  # path to configuration file

.. _cli_execute:

Execute
===============================
This tool executes jobs defined in given PBC files directory.

This tool is developed for testing before registering the jobs to JobStore.
Two additional modes can be defined for this tool, *debug* and *test*.
In the debug mode, this tool only outputs description for the jobs without executing the jobs.
The test mode is for implementing command-specific behavior for inspecting problems.

This tool also handle the interval in the same way as the register tool.

::

  ./bin/patriot help execute
  Usage:
    patriot execute [options] <yyyy-mm-dd[,yyyy-mm-dd]> <files/paths>+

  Options:
    -f, [--filter=FILTER]          # regular expression for job_id
    -d, [--debug], [--no-debug]    # run in debug mode
    -t, [--test], [--no-test]      # run in test mode
        [--strict], [--no-strict]  # run in strict mode (according to dependency)
    -c, [--config=CONFIG]          # path to configuration file

.. _cli_validate:

Validate
=================================

This tool just validate PBC files so that

* they do not include grammatical errors.
* their identifiers are not duplicated.

::

  % ./bin/patriot help validate
  Usage:
    patriot validate [OPTIONS] path [path file ...]

  Options:
    -s, [--stop-on-detection], [--no-stop-on-detection]  # stop immediately when invalid config detected
        [--date=DATE]                                    # date passed to parser
    -c, [--config=CONFIG]                                # path to configuration file

.. _cli_worker:

Worker
===============================

This tool just starts or stops a worker.
In stopping the worker, this tool sends a SIGNAL to the worker to terminate after the completion of the jobs currently executed by the worker.
Therefore, the worker would not stop immediately.

::

  Usage:
    patriot worker [options] [start|stop]

  Options:
        [--foreground], [--no-foreground]  # run as a foreground job
    -c, [--config=CONFIG]                  # path to configuration file

  controll worker

.. _cli_worker_admin:

Worker\_Admin
===========================================

This tool administrates one or all of remote workers.
The remote worker should be configured in the _worker_hosts_ in the configuration file.
The tool supoorts below operations.

* start/stop/restart workers
* sleep/wake up workers (in the sleep state, workers do not execute any jobs)
* monitor status of workers

::

  Usage:
    patriot worker_admin [options] [start|stop|restart|sleep|wake|status]

  Options:
    -a, [--all], [--no-all]  # target all worker hosts
    -h, [--host=HOST]        # target host
    -c, [--config=CONFIG]    # path to configuration file

.. _cli_job:

Job
===========================

This tool manage jobs in JobStore.

::

  % ./bin/patriot help job
  Usage:
    patriot job [delete|show_dependency] job_id [job_id ..]

  Options:
    -c, [--config=CONFIG]  # path to configuration file

.. _cli_plugin:

Plugin
==============================

This tool is used for installing plugins build as gem packages.

::

  % ./bin/patriot help plugin
  Usage:
    patriot plugin [options] install <path to plugin>

  Options:
    -f, [--force]                  # force operation
        [--unpack], [--no-unpack]  # unpack gem into plugin dir
    -c, [--config=CONFIG]          # path to configuration file

