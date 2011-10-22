require File.expand_path('../get_them_all/version', __FILE__)

# system libraries
require 'logger'
require 'fileutils'
require 'zlib'

# gems
require 'eventmachine'
require 'active_support/core_ext/object/duplicable'
require 'active_support/core_ext/class'
require 'active_support/core_ext/string'
require 'active_support/core_ext/array'

# local files
Dir.chdir( File.join(File.dirname(__FILE__), "get_them_all") ) do
  require './logger'
  
  # libraries
  require './notifier'
  require './history'
  
  begin
    require './javascript_loader'
  rescue LoadError => err
    # therubyracer not available
  end
  
  # Storage
  require './storage'
  require './storage/file_storage'
  require './storage/dropbox_storage'
  
  # extensions
  require './extension'
  require './extensions/graph_builder'
  require './extensions/action_logger'
  require './extensions/gauge_display'
  
  # main files
  require './site_downloader'
  require './worker'
  require './action'
  require './actions/examine_action'
  require './actions/download_action'
end



module GetThemAll

end
