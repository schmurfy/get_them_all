

require 'rubygems'

$LOAD_PATH.unshift( File.expand_path('../../lib', __FILE__) )
require "get_them_all"

require File.expand_path('../wallpaper', __FILE__)

# CTRL+C
trap("INT") do
  EM::stop_event_loop()
end

# These are the properties of the website
# base_url is the root, every other pass will be relative to it
# folder_name is the path in which downloaded files will be put (itself relative to the
#   configured root path)
#
crawler = WallpaperDownloader.new(    
    :storage => {
      :type => 'file',
      :params => {:root => "data"}
    },    
    :extensions => [
        GetThemAll::ActionLogger.new
        # GaugeDisplay.new
      ]
  )

crawler.start()

