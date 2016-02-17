=====================
REST API
=====================
Patriot Workflow Scheduler also provides REST API to manage jobs. The REST API works along with :doc:`'Web Console' <web>` at the moment.

.. contents:: 
   :local:
   :depth: 2

Authentication
===================================
Some APIs need Basic authentication. When calling these APIs, you should provide username and password which are written in the config file as `info_server.admin.username` and `info_server.admin.password` (See :doc:`'System Configuration' <config>`).

APIs
===================================
Described here are the APIs provided at the moment.


----


GET /api/v1/jobs
-----------------------------------
Retrieves jobs with conditions provided with the parameters below.

Parameters
++++++++++++
state (optional)
  | Filters jobs (default: 4, FAILED). The options are:
  |   -2: DISCARDED
  |   -1: INIT
  |   0: SUCCEEDED
  |   1: WAIT
  |   2: RUNNING
  |   3: SUSPEND
  |   4: FAILED
limit (optional)
  | Limits the number of jobs to get (default: 50).
offset (optional)
  | Adds offset (default: 0).
filter_exp (optional)
  | Filters jobs with the provided expression.
  | This expression will be given to a LIKE clause of SQL.


----


GET /api/v1/jobs/stats
-----------------------------------
A handy way to get status and its number of jobs respectively.

The responce would be like:

::

  [[-1, 3], [1, 100], [2, 10], [3, 0], [4, 20]]

It means that there are 3 jobs with status -1(INIT), 100 jobs with status 1(WAIT), and so on. Note that status -2(DISCARDED) and 0(SUCCEEDED) are not included in this API.


----


GET /api/v1/jobs/<job_id>
-----------------------------------
Retrives the detail of the job.

Parameters
++++++++++++
job_id (required*)
  | Indicates the job_id
include_dependency (optional)
  | Determines if the information of `consumers` and `producers` is included (default: true)


----


GET /api/v1/jobs/<job_id>/histories
-----------------------------------
Retrives the execution history of the job.

Parameters
++++++++++++
job_id (required*) 
  | Indicates the job_id
size (optional)
  | Sets the size of history (default: 3)


----


POST /api/v1/jobs
-----------------------------------
Registers a new job.

You should check what parameters the command requires and give them properly.

Parameters
++++++++++++
COMMAND_CLASS (required*)
  | Indicates a command class you want to create.
name (optional, but strongly recommended)
  | Indicates the job name. This parameter will be given to the command, and the command will generate a job_id accordingly.
requisites (optional)
  | Indicates products which will be required by the job before its execution.
produces (optional)
  | Indicates products which will be produced by the job after its execution.
priority (optional)
  | Sets the priority of the job (default: 1).
exec_date (optional)
  | Indicates the date when the job can start (default: the next day of the day when this API is called)
  | The format is supposed to be "YYYY-MM-DD".
start_after (optional)
  | Indicates the time when the job can start after.
  | The format is supposed to be "hh:mm:ss".
exec_node (optional)
  | Indicates a node (a group of hosts) where the job can be executed.
exec_host (optional)
  | Indicates a host where the job is executed.
(other parameters, optional)
  | If other parameters are given, they will be provided to the command which is created along with `COMMAND_CLASS`.

Example of parameters
++++++++++++

Following parameters can be provided in the JSON body of a POST request.

Here `name`, `name_suffix`, `connector`, `commands` are parameters for `Patriot.Command.ShCommand`.

::

  {
   "COMMAND_CLASS": "Patriot.Command.ShCommand",
   "name"         : "calculation_b"
   "name_suffix"  : "2016-01-01"
   "priority"     : 10,
   "exec_date"    : "2016-01-01",
   "start_after"  : "01:30:00",
   "connector"    : "&&",
   "commands"     : ["sudo -u hdfs hadoop fs -rmr /tmp/nbu_battleslot_slot/2013-07-06"]}],
   "exec_node"    : "calc_node",
   "requisites"   : ["calculation_a_2016-01-01", "master_data_2016-01-01],
   "produces"     : ["calculation_b_2016_01_01"],
  }

This request will return a JSON response like:

::

  {
   "job_id": "sh_calculation_b_2016-01-01",
   "state" : "INIT"
  }


----


PUT /api/v1/jobs/<job_id>
-----------------------------------
Modifies the state of the specified job.

Parameters
++++++++++++
job_id (required*)
  | Indicates the job_id
state(required*)
  | Indicates a new state.


----


DELETE /api/v1/jobs/<job_id>
-----------------------------------
Deletes the specified job and its relation.

Parameters
++++++++++++
job_id (required*)
  | Indicates the job_id
