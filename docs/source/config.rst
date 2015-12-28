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

  * - property name
    - description
  * - info_server.port
    - port number used by the management web console
  * - info_server.admin.username
    - admin user name of the web console
  * - info_server.admin.username
    - admin user name of the web console
  * - info_server.admin.username
    - admin user name of the web console
  * - info_server.admin.username
    - admin user name of the web console
  * - info_server.admin.password
    - admin user password of the web console
  * - worker_hosts
    - a comma-separated-list of workers managed by the _worker_admin_ CLI tool
  * - admin_user
    - user name used in the _worker_admin tool.  The tool accesses remote servers as this user name by ssh, each of worker server should be accessible without password in case of this user.
  * - plugins
    - a comma-separated-list of plugins
  * - jobstore.root.class
    - JobStore implementation class name. The default is Patriot::JobStore::InMemoryStore. Set to Patriot::JobStore::RDBJobStore to use RDB as the JobStore
  * - jobstore.root.adapter
    - a DB adapter name for RDBJobStore. (mysql2 or sqlite3)
  * - jobstore.root.database
    - the database name of RDBJobStore
  * - jobstore.root.username
    - the user name to access the DB for the JobStore
  * - jobstore.root.password
    - the password to access the DB for the JobStore
  * - jobstore.root.host
    - the location of the DBMS where JobStore is hosted
  * - jobstore.root.port
    - the port number used by the DBMS where JobStore is hosted
  * - jobstore.root.encoding
    - the encoding used in communicating the DBMS
  * - log_factory
    - an implementation of Patriot::Util::Logger::Factory
  * - log_level
    - Log level (e.g., DEBUG, INFO)
  * - log_format
    - Log format
  * - log_outputters
    - a comma-separated-list of log outputters
  * - log_outputter.$outputer.class
    - an implementation of each outputter ($outputter should be replaced with one of the outputter specified in _log_outputters_.
  * - fetch_cycle
    - an interval in which the worker fetches executable jobs from JobStore
  * - fetch_limit
    -  the max number of jobs fetched at once
  * - nodes
    - a comma-separated-list of nodes hosted on the worker
  * - node.$node.type
    - type of node (_any_ or _own_). $node should be replaces one of the nodes specified in the _nodes_. With type any, the node executes jobs without nodes or jobs with the same node. With type own, the node only executes jobs with the same node.
  * - node.$node.threads
    - the number of threads for the node ($node should be replaced with one of the _nodes_).


