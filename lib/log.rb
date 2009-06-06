class SiteDownloader
  def debug(str, no_debug_str = nil)
    if verbose?
      puts "[dbg] #{str}"
    else
      print(no_debug_str) unless no_debug_str.nil?
    end
  end
  
  def error(str, fatal = false)
    if fatal
      fail(str)
    else
      puts "[err] #{str}"
    end
  end
end

class Action
  def debug(*args)
    @downloader.debug(*args)
  end
  
  def error(*args)
    @downloader.error(*args)
  end
end
