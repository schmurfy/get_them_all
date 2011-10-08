require 'logger'

class SiteDownloaderLogger < Logger
  def format_message(level, time, progname, msg)
    "[#{level} -- #{time.strftime("%Y/%m/%d %H:%M:%S")}] #{msg}\n"
  end
end

class SiteDownloader
  cattr_accessor :logger
  
end


# helpers
def debug(msg, short_msg = nil)
  SiteDownloader::logger.debug(msg)
end

def info(msg)
  SiteDownloader::logger.info(msg)
end

def warn(msg)
  SiteDownloader::logger.warn(msg)
end

def error(msg, fatal = false)
  SiteDownloader::logger.error(msg)
  exit(1) if fatal
end