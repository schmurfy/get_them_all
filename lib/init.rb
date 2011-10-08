
# system libraries
require 'logger'
require 'fileutils'
require 'zlib'

require 'bundler/setup'

# gems
require 'drydock'
require 'eventmachine'
require 'active_support/core_ext/object/duplicable'
require 'active_support/core_ext/class'
require 'active_support/core_ext/string'
require 'active_support/core_ext/array'
# require 'active_support/core_ext/class/attribute_accessors'

# local files
Dir.chdir(File.dirname(__FILE__)) do
  require './logger'
  
  # libraries
  require './tree'
  require './terminal'
  require './notifier'
  require './javascript_loader'
  
  # extensions
  require './extension'
  require './extensions/graph_builder'
  require './extensions/action_logger'
  
  # main files
  require './site_downloader'
  require './worker'
  require './action'
  require './actions/examine_action'
  require './actions/download_action'
end

