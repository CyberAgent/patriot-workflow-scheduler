========================
System Configuration
========================

The patriot-workflow-scheduler can be configured in an INI file.
By using sections, the configuration can be switched by the tool of the command line interface (CLI tool).
The default configuration defined in the 'common' section will be overwritten by the section of the CLI command.

The List of Configuration Properties
=======================================

.. list-table::
  :header-rows: 1
  :widths: 3,7

info_server.port
  | A port number used by the management web console
info_server.admin.username
  | An admin user name of the web console
info_server.admin.password
  | An admin user password of the web console
worker_hosts
  | A comma-separated list of workers managed by the _worker_admin_ CLI tool
admin_user
  | A user name used in the _worker_admin tool.
  | Since it accesses remote servers with this user name by SSH, Every workers should be accessible without password for this user.
plugins
  | A comma-separated list of plugins
jobstore.root.class
  | JobStore implementation class name (default is Patriot::JobStore::InMemoryStore).
  | Set it to Patriot::JobStore::RDBJobStore to use RDB as JobStore
jobstore.root.adapter
  | The DB adapter name for RDBJobStore. (mysql2 or sqlite3)
jobstore.root.database
  | The DB name of RDBJobStore
jobstore.root.username
  | The user name to access the DB for JobStore
jobstore.root.password
  | The password to access the DB for JobStore
jobstore.root.host
  | The location of the DB where JobStore is hosted
jobstore.root.port
  | The port number used by the DB where JobStore is hosted
jobstore.root.encoding
  | The encoding used in communicating the DB
log_factory
  | Implementation of Patriot::Util::Logger::Factory
log_level
  | Log level (e.g., DEBUG, INFO)
log_format
  | Log format
log_outputters
  | A comma-separated-list of log outputters
log_outputter.$outputer.class
  | Implementation of each outputter ($outputter should be replaced with one of the outputters specified in *log_outputters*).
fetch_cycle
  | Interval in which the worker fetches executable jobs from JobStore
fetch_limit
  | The max number of jobs fetched at once
nodes
  | A comma-separated-list of nodes hosted on the worker
node.$node.type
  | Type of node (*any* or *own*). $node should be replaced one of the nodes specified in the *nodes*.
  | With type any, the node executes jobs without nodes or jobs with the same node.
  | With type own, the node only executes jobs with the same node.
node.$node.threads
  | A number of threads for the node ($node should be replaced with one of the *nodes*).

