
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
    @actions_queue = EM::Queue.new
    
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
  

  def handle_action(action, n)
    # puts "Worker [#{n}] called for action #{action.class} on #{action.url}"
    
    action.when_done do
      # handle the next action in queue
      @actions_queue.pop{|act| handle_action(act, n) } unless @actions_queue.empty?
    end
    
    action.do_action()
    action.errback do
      # in cas of failure, try again
      # debugger
      @actions_queue.push(action)
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
     
      # recipe will euthnticate us if needed and start queuing the first
      # actions
      yield() if block_given?
      
      # now that actions are queued, start handling them
      # start each "worker"
      4.times do |n|
        @actions_queue.pop do |action|
          handle_action(action, n)
        end
      end
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
    if false
    # if @connections.has_key?(host_key) && !@connections[host_key].error?
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

  
  def examine_url(url, level, destination_folder, referer = nil)
    @actions_queue.push ExamineAction.new(self,
        :url => url,
        :level => level,
        :destination_folder => destination_folder,
        :referer => referer
      )
  end
  
  def download_url(url, level, destination_folder, referer = nil)
    @actions_queue.push DownloadAction.new(self,
        :url => url,
        :level => level,
        :destination_folder => destination_folder,
        :referer => referer
      )
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


  
  
  
  # to be redefine in subclasses
  def examine_page(doc, level)
    raise "Need to implement examine_page in #{self.class}"
  end
  
  def get_file_destpath_from_url(url, destination_folder)
    File.join(@base_path, destination_folder, url)
  end
end