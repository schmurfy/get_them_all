
require File.join(File.dirname(__FILE__), 'lib/init')

# CTRL+C
trap("INT") do
  EM::stop_event_loop()
end

extend Drydock

default 'show-commands'

global :v, :verbose, "Increase verbosity"
global :d, :debug, "Redirect logs to stdout"

before do
  FileUtils.mkdir_p( File.join(File.dirname(__FILE__), 'log') )
  SiteDownloader::logger= SiteDownloaderLogger.new(STDOUT)
  # SiteDownloader::logger= SiteDownloaderLogger.new(File.join(File.dirname(__FILE__), "log", "gta.log"))
  SiteDownloader::logger.level = Logger::INFO
end

# about "This help screen"
# command :help do |obj|
#   puts "Show command list with:"
#   puts "  #{$0} show-commands"
# end

usage "USAGE: #{$0} run [-g] -c file"
about "Execute a config file and start download"
option :c, :config, String, "Config file to use"
option :g, :graph, "Create a graph describing what was done"
command :run do |obj|
  config_path = File.join(File.dirname(__FILE__), 'sites', "#{obj.option.config}.rb")
  
  # we have a config file, check if we can open it
  # readable return false if file does not exists
  fail("Unable to open file: #{config_path}") unless File.readable?(config_path)
  
  # the file exist, open it
  require config_path
  
  # check that the class exist
  class_name = File.basename(config_path, ".rb").camelize + "Downloader"
  fail("file #{config_path} should define class #{class_name} !") unless Object.const_defined?( class_name.to_sym )
  
  info("Started with config file #{File.basename(config_path)}")
  
  # create the instance (and start download)
  obj = class_name.constantize.new(:options => {
    :verbose => obj.global.verbose,
    :graph => obj.option.graph
  })
end


Drydock.run!(ARGV)

