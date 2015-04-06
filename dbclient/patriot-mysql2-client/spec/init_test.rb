PLUGIN_ROOT = File.expand_path(File.dirname(File.expand_path(__FILE__)))
$home = File.join(PLUGIN_ROOT, "..")
$: << File.join(PLUGIN_ROOT, "..", "lib")
$: << File.join(PLUGIN_ROOT, "..", "..", "patriot-rdb-adapter", "lib")
$: << File.join(PLUGIN_ROOT, "spec")
require "patriot"
require "patriot/util/db_client"
require "patriot/util/db_client/mysql2_client"

require "helper"
