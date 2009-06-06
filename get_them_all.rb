#!/usr/bin/ruby

require 'optparse'
require "logger"
require "rubygems"

gem "hpricot", ">= 0.8.1"; require "hpricot"
gem "eventmachine", ">= 0.12.6"; require "eventmachine"
gem "activesupport", ">= 2.3.2"; require "active_support"

require File.dirname(__FILE__) + '/lib/site_downloader.rb'
require File.dirname(__FILE__) + '/lib/worker.rb'
require File.dirname(__FILE__) + '/lib/action.rb'
require File.dirname(__FILE__) + '/lib/extensions.rb'
require File.dirname(__FILE__) + '/lib/http.rb'
require File.dirname(__FILE__) + '/lib/log.rb'

require "ruby-debug"
Debugger.start

trap("INT"){ EM::stop_event_loop() }

# command line arguments
options = {}
config_path = nil

ARGV.options do |opts|
  opts.banner = "Usage: scraper.rb [options]"

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
  
  opts.on("-c", "--config=PATH", String, "Which config to run") do |config_path|
    config_path = File.join(File.dirname(__FILE__), 'sites', "#{config_path}.rb")
  end
end.parse!

if config_path.nil?
  print ARGV.options 
  exit
end

# we have a config file, check if we can open it
# readable return false if file doaes not exists
fail("Unable to open file: #{config_path}") unless File.readable?(config_path)

# the file exist, open it
classes_defined = require config_path

# check that the class exist
class_name = File.basename(config_path, ".rb").camelize + "Downloader"
fail("should define class #{class_name}") unless classes_defined.include?(class_name)

# create the instance (and start download)
obj = class_name.constantize.new(:options => options)
