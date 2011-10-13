require 'logger'

module GetThemAll
  class SiteDownloaderLogger < Logger
    def format_message(level, time, progname, msg)
      "[#{level} -- #{time.strftime("%Y/%m/%d %H:%M:%S")}] #{msg}\n"
    end
  end

  class SiteDownloader
    cattr_accessor :logger
  
    self.logger= SiteDownloaderLogger.new(STDOUT)
    self.logger.level = Logger::ERROR
  end
end

# helpers
def debug(msg, short_msg = nil)
  GetThemAll::SiteDownloader::logger.debug(msg)
end

def info(msg)
  GetThemAll::SiteDownloader::logger.info(msg)
end

def warn(msg)
  GetThemAll::SiteDownloader::logger.warn(msg)
end

def error(msg, fatal = false)
  GetThemAll::SiteDownloader::logger.error(msg)
  exit(1) if fatal
end

