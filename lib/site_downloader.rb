
class SiteDownloader
  
  def initialize(args)
    
    @cookies = {}
    @base_url= args.delete(:base_url)
    @parsed_base_url = URI.parse(@base_url)
    
    @folder_name= args.delete(:folder_name)
    @base_path = File.join(File.dirname(__FILE__), '..', 'data', @folder_name)

    @history = []
    @options = args.delete(:options)
    @connections = {}
    @download_queue = []
    
    # stats
    @skipped_files = 0
    @download_files = 0
    
    # create base folder
    FileUtils.mkdir_p( @base_path )
    
    # start download
    start do
      yield() if block_given?
    end
  end
  
  def start
    load_history()

    EM::run do
      EM::add_periodic_timer(5) do
        if EM::connection_count() == 0
          debug("no connections, exiting")
          EM::stop_event_loop()
        end
      end
     
      yield() if block_given?
    end
   
    save_history()
    
    puts ""
    puts "Downloaded #{@download_files} files"
    puts "Skipped: #{@skipped_files}"
  end
  private :start
  
  
  def verbose?
    @options[:verbose]
  end
  
  def assert(cond, msg = "")
    error("assertion failed: #{msg}", true) unless cond
  end
  
  # toto.com
  # sub.toto.com
  def same_domain?(host1, host2)

    host1_parts = host1.split(".")
    host2_parts = host2.split(".")

    size = [host1_parts.size, host2_parts.size].min # => 2

    host1_parts= host1_parts[-size..-1] if host1_parts.size > size
    host2_parts= host2_parts[-size..-1] if host2_parts.size > size

    ret = host1_parts.join(".") == host2_parts.join(".")
    debugger if ret == false

    return ret
  end
  
  def open_url(url, method = "GET", params = nil, referer = nil, &block)

    if url[0...4] != "http" # partial url
      url = URI.join(@base_url, url)
    else
      url = URI.parse(url)
    end
    
    external = !same_domain?(@parsed_base_url.host, url.host)
    
    if external
      debug("Opening external page: #{url}")
    else
      debug("#{method.upcase} #{url}")
    end
    
    # find a connection for this host
    host_key = "#{url.host}:#{url.port}"
    if @connections.has_key?(host_key) && !@connections[host_key].error?
      http = @connections[host_key]
    else
      # debug("New connection to #{url.host}", "C")
      http = EM::Protocols::HttpClient2.connect( url.host, url.port )
      @connections[host_key] = http
    end
    
    req = http.request(:verb => method.upcase, :uri => url.path, :cookies => @cookies, :body => params, :referer => referer)
    # req.timeout(10)
    # req.errback do
    #   error("error while opening #{url} :(")
    # end
    
    req.callback do
      if [200].include? req.status
        # handle cookies
        unless external
          req.added_cookies.each{|key,val| @cookies[key] = val }
          req.deleted_cookies.each{|key, _| @cookies.delete(key) }
        end
        
        # debug("page loaded succesfully: #{url}")
        block.call(req)
      else
        error("failed to get url #{url.path} , status: #{req.status}")
      end
    end
    
    req
  end
  
  # return a number between 0.1 and 1
  def retry_time
    0.1 * (rand(1000)+1)/100
  end

  
  def examine_url(url, level, destination_folder, referer = nil, &block)
    
    unless @history.include?(url)
      req = open_url(url, "GET", nil, referer) do |req|
        debug("    examining #{url}")
        doc = Hpricot( req.content )
        actions = examine_page(doc, level + 1)
        actions.each do |action|
          action.destination_folder ||= destination_folder
          if action.is_a?(ExamineAction)
            examine_url(action.url, action.level, action.destination_folder, url)
          else
            # picture has been downloaded, keep this information (@history)
            r = download_url(action.url, action.level, action.destination_folder){ @history << url }
          end
        end
      end
      
      req.timeout(5)
      req.errback do
         # on error retry
         EM::add_timer(retry_time()){ examine_url(url, level, destination_folder, referer, &block) }
         debug("Retrying examine...", "E")
       end
      
    else
      @skipped_files+= 1
      debug("Skipping #{url}", "S")
    end
    
  end
  
  def download_url(url, level, destination_folder, referer = nil, &block)
    req = open_url(url, "GET", nil, referer) do |req|
      debug("    downloading #{url}", "D")
      destpath= get_file_destpath_from_url(url, destination_folder)

      # create folders if non existant
      begin
        FileUtils.mkdir_p( File.dirname(destpath) )
      rescue Errno::EINVAL
        error("Invalid path: #{destpath}")
      end
      
      # find an unused filename
      while File.exists?(destpath)        
        path, filename= File.dirname(destpath), File.basename(destpath).split(".")
        filename= "#{filename[0]}_#{random_string(2)}.#{filename[1]}"
        destpath= File.join(path, filename)
        debug("Renamed as #{filename}", "R")
      end
      
      # save in file
      begin
        open(destpath, "wb") do |bin_out|
          bin_out.write( req.content )
          @download_files+= 1
        end
      rescue Errno::EINVAL
        error("Save error for url: '#{action.url}' ")
        raise
      end
      
      # add metadat (source url)
      # open(destpath + ":source_url", "w") do |f|
      #   f.puts File.join(@base_url, action.parent_url)
      # end
    end
    
    req.callback{ block.call(req) }
    req.timeout(5)
    req.errback do
      # on error retry
      EM::add_timer(retry_time()){ download_url(url, level, destination_folder, referer, &block) }
      debug("Retrying download...", "T")
    end
  end
  
  
  # load already downloaded pictures from disk
  def load_history
    path= File.join(@base_path, "history.txt" )
    if File.exists?(path)
      File.open(path, "r") do |f|
        f.each_line do |line|
          @history<< line.strip
        end
      end
    end
  end
  
  def save_history
    File.open( File.join(@base_path, "history.txt" ), "w") do |f|
      @history.each do |url|
        f.puts(url)
      end
    end
  end

  def random_string(len=5)
    ret= ""
    chars= ("0".."9").to_a + ("a".."z").to_a
    1.upto(len) { |i| ret<< chars[rand(chars.size-1)] }
    ret
  end
  
  
  
  # to be redefine in subclasses
  def examine_page(doc, level)
    raise "Need to implement examine_page in #{self.class}"
  end
  
  def get_file_destpath_from_url(url, destination_folder)
    File.join(@base_path, destination_folder, url)
  end
end