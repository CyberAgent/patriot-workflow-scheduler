PLUGIN_ROOT = File.expand_path(File.dirname(File.expand_path(__FILE__)))
$home = File.join(PLUGIN_ROOT, "..")
$: << File.join(PLUGIN_ROOT, "..", "lib")
SAMPLE_DIR = File.join(File.dirname(File.expand_path(__FILE__)), "sample")
require "rubygems"
require "patriot"
require "patriot_hadoop"
require "helper"
