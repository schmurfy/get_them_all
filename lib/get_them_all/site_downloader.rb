
require 'fiber'

require 'addressable/uri'
require 'active_support/hash_with_indifferent_access'

require 'em-http-request'
require 'em-priority-queue'

module GetThemAll
  
  ##
  # The main class, all your crawlers will derive from this class
  # see examples/standalone.rb file for an example.
  # 
  class SiteDownloader
    include Notifier
    
    # number of worker for each tasks
    class_attribute :examiners_count, :downloaders_count
    
    # delay between each action for one worker
    class_attribute :examiners_delay, :downloaders_delay
    
    
    self.examiners_count = 1
    self.downloaders_count = 1
    
    # default: 100 to 200ms between actions
    self.downloaders_delay = [100, 200]
    self.examiners_delay = [100, 200]
    
    ##
    # Determine what will be stored in the history file,
    # the default is to store the last url before the download
    # so we can ignore it sooner next time.
    # 
    # The other mode is :download, in this mode the download
    # url itself will be stored, it is meant for special cases as
    # the default should work better most of the time.
    # 
    class_attribute :history_tracking
  
    self.history_tracking = :default
  
    attr_reader :base_url, :storage, :history
    
    ##
    # If true a new filename will be generated for every file
    # for which the destination already exists
    attr_reader :rename_duplicates
    
    ##
    # Create and start the crawler.
    # 
    # @param [Hash] args arguments
    # @option args [String] :base_url The root url, every other
    #   url will be relative to this.
    # @option args [String] :start_url What is the very first url
    #   to examine (level 0) relative to base_url, default is "/"
    # @option args [String] :folder_name The root path where
    #   downloaded files will be saved (appended to the storage root).
    # @option args [Array] :extensions Array of Extension object.
    # @option args [Boolean] :rename_duplicates If true a new name will be
    #   generated if the file exists.
    # 
    # @option args [Hash] :storage Configure storage backend
    #   :type is the backend name
    #   :params is a hash with backend specific options
    # 
    def initialize(args)
      @cookies = []
      @history = []
      @connections = {}
      @examine_queue = EM::PriorityQueue.new
      @download_queue = EM::PriorityQueue.new
      @history = History.new
      
      @base_url= args.delete(:base_url)
      @start_url = args.delete(:start_url) || '/'
      @folder_name= args.delete(:folder_name)
      @login_request = args.delete(:login_request)
      @rename_duplicates = args.delete(:rename_duplicates)
      
      # keep a pointer to each extension
      @extensions = args.delete(:extensions) || [ActionLogger]
      
      storage_options = args.delete(:storage)
      raise "storage required" unless storage_options
      raise "storage type required" unless storage_options[:type]
      raise "storage params required" unless storage_options[:params]
      
      storage_class = "#{storage_options[:type].camelize}Storage"
      raise "unknown storage: #{storage_class}" unless defined?(storage_class)

      storage_class = GetThemAll.const_get(storage_class)
    
      storage_class = storage_class
      storage_options = ActiveSupport::HashWithIndifferentAccess.new( storage_options[:params] )
      
      @storage = storage_class.new(storage_options.merge(:folder_name => @folder_name))
    
      @parsed_base_url = Addressable::URI.parse(@base_url)
      
      # start_url is relative to base_url
      @start_url = File.join(@base_url, @start_url)
      
      # if any unknown option was passed, do not silently walk away
      # tell the user !
      unless args.empty?
        raise "unknown parameters: #{args.inspect}"
      end
      
    end
  
    ##
    # Start the crawler, if you pass a block it
    # will be called after the engine is iniailized, you can
    # queue the level 0 urls here and handle authenticating if needed.
    # 
    def start
      load_history()
    
      notify('downloader.started', self)
    
      EM::run do
        @exit_timer = EM::add_periodic_timer(2) do
          # if all workers are idle
          # and there is nothing in queue
          # then stop the engine
          # 
          if @examiners.all?(&:idle?) && @downloaders.all?(&:idle?) &&
             @examine_queue.empty? && @download_queue.empty?
            self.stop()
          end
        end
      
        EM::error_handler do |err|
          if err.is_a?(AssertionFailed)
            error("Assertion failed: #{err.message}")
          else
            error("#{err.class}: #{err.message}")
            err.backtrace.each do |line|
              error(line)
            end
          end
        end
        
        # authenticate connection if required
        if @login_request
          open_url(*@login_request) do |req, doc|
            after_login()
          end
        else
          after_login()
        end
        
      end
      
      notify('downloader.completed', self)
    end
    
    def after_login
      # queue the first action to start crawling
      #  
      @examine_queue.push(ExamineAction.new(self,
          :url => @start_url,
          :destination_folder => '/',
          :level => 0,
        ), 0)
      
    
      # now that actions are queued, start handling them
      # start each "worker"
      # dequeuing is priority based, the download actions
      # first and then the higher the level the higher the
      # priority for examine actions, this is done this way
      # to give work to the download workers asap.
      # 
      
      @examiners = []
      @downloaders = []
      
      1.upto(self.class.examiners_count) do |n|
        @examiners << Worker.new(:examiner, n - 1, @examine_queue, self.class.examiners_delay)
      end
    
      1.upto(self.class.downloaders_count) do |n|
        @downloaders << Worker.new(:downloader, n - 1, @download_queue, self.class.downloaders_delay)
      end
    end
    
    ##
    # Cleanly stop the engine and ensure the history file is
    # written.
    # 
    def stop
      return if @stopping
      
      # first stop the exit timer, no longer needed once we are here
      @exit_timer.cancel()
      @stopping = true
      
      Fiber.new do
        fiber = Fiber.current
      
        notify('downloader.stopping', self)
      
        # first ask every workers to stop their work
        # starting with examiners
        @examiners.each do |worker|
          debug "Stopping Examiner #{worker.index}..."
          worker.request_stop { fiber.resume }
          Fiber.yield
          debug "Stopped Examiner #{worker.index}"
        end
      
        @downloaders.each do |worker|
          debug "Stopping Downloader #{worker.index}..."
          worker.request_stop { fiber.resume }
          Fiber.yield
          debug "Stopped Downloader #{worker.index}"
        end
        
        # now that every worker is stopped, write the history
        deferrable = save_history()
        deferrable.callback{ fiber.resume }
        Fiber.yield
        
        notify('downloader.stopped', self)
        
        # and stop the reactor
        EM::stop_event_loop()
      end.resume
    end
    
    class AssertionFailed < RuntimeError; end
  
    def assert(cond, msg = "")
      unless cond
        raise AssertionFailed, msg
      end
    end
  
    # toto.com
    # sub.toto.com
    
    ##
    # Check if two urls are from the same domain.
    # 
    # @return [Boolean] true if same domain
    # 
    def same_domain?(host1, host2)

      host1_parts = host1.split(".")
      host2_parts = host2.split(".")

      size = [host1_parts.size, host2_parts.size].min # => 2

      host1_parts= host1_parts[-size..-1] if host1_parts.size > size
      host2_parts= host2_parts[-size..-1] if host2_parts.size > size

      ret = host1_parts.join(".") == host2_parts.join(".")

      return ret
    end
  
    HISTORY_FILE_PATH = 'history.txt'.freeze
  
    # load already downloaded pictures from disk
    def load_history
      if @storage.exist?(HISTORY_FILE_PATH)
        data = @storage.read(HISTORY_FILE_PATH)
        @history.load(data)
      else
        debug "History file not found: #{HISTORY_FILE_PATH}"
      end
    end
  
    def save_history
      @storage.write(HISTORY_FILE_PATH, @history.dump)
    end


  
  
    # Plugin API
    def open_url(url, method = "GET", params = nil, referer = nil, deferrable = nil, &block)    
      deferrable ||= EM::DefaultDeferrable.new
      referer ||= @base_url
    
      url = Addressable::URI.parse( (url[0...4] == "http") ? url : URI.join(@base_url, url) )

      # url = (url[0...4] == "http") ? URI.parse(url) : URI.join(@base_url, url)
      # url_path = url.path
    
      # get queries with params
      # if method == "GET" && url.query
      #   url_path << "?#{url.query}"
      # end

      external = !same_domain?(@parsed_base_url.host, url.host)
    
      if external
        debug("Opening external page: #{url}")
      else
        # debugger if url.to_s == "http://fan tasti.cc/user/pussylover75/images/image/367771"
        debug("#{method.upcase} #{url}")
      end
    
    
      # find a connection for this host
      host_key = "#{url.host}:#{url.port}"
      if false
      # if @connections.has_key?(host_key) && !@connections[host_key].error?
        http = @connections[host_key]
      else
        # debug("New connection to http://#{url.host}:#{url.port}", "C")
        http = EM::HttpRequest.new("http://#{url.host}:#{url.port}")
      
        @connections[host_key] = http
      end
      
      req = http.setup_request(method.downcase.to_sym,
          :path => url.path,
          :query => url.query,
          # :redirects => 2,
          :head => {
              :cookie => @cookies,
              :referer => referer,
              # "accept-encoding" => "gzip, compressed",
              'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_1) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/14.0.835.202 Safari/535.1'
            }
        )
    
      # req.timeout(10)
      # req.errback do
      #   error("error while opening #{url} :(")
      # end
    
      req.callback do
        case req.response_header.status
        when 200
          # handle cookies
          unless external
            # [["a=42", "PHPSESSID2=u0ctlbfrlrnus1qv8425uv4p42"], ["PHPSESSID=2jek8d61dlt134e0djft4hnn54; path=/", "OAGEO=FR%7C%7C%7C%7C%7C%7C%7C%7C%7C%7C; path=/", "OAID=924ff65ed90c7834d8b37b29bdffc831; expires=Sun, 14-Oct-2012 12:22:22 GMT; path=/", "OAID=924ff65ed90c7834d8b37b29bdffc831; expires=Sun, 14-Oct-2012 12:22:22 GMT; path=/", "OAID=924ff65ed90c7834d8b37b29bdffc831; expires=Sun, 14-Oct-2012 12:22:22 GMT; path=/"]]
            # [["a=42"], "PHPSESSID=p12aet71oemrfb3olffqaptss3; path=/"]
            added_cookies = Array(req.cookies[1])
            
            added_cookies.each do |str|
              @cookies << str.split(';').first
            end
            
            # remove duplicates
            @cookies.uniq!
            
            # req.added_cookies.each{|key,val| @cookies[key] = val }
            # req.deleted_cookies.each{|key, _| @cookies.delete(key) }
          end
        
          # debug("page loaded succesfully: #{url}")
          deferrable.set_deferred_status(:succeeded, req)
          if block
            if block.arity == 2
              doc = Hpricot(req.response)
              block.call(req, doc)
            else
              block.call(req)
            end
          end
        
        # em-http-request does not handle redirection between hosts
        # so handle them ourselves
        when 301, 302
          location = req.response_header.location
          if location
            debug("Following redirection: #{location}")
            # reuse the same deferrable object
            open_url(location, method, params, referer, deferrable, &block)
          end
        
        else
          puts "#{method} #{url} => Status: #{req.response_header.status}"
          deferrable.set_deferred_status(:failed, req.response_header.http_reason)
        end
      end
    
      req.errback do
        deferrable.set_deferred_status(:failed, -1)
      end
    
      deferrable
    end
  
    def eval_javascript(data)
      JavascriptLoader.new(data)
    end
  
  
  
    # to be redefine in subclasses
    def examine_page(doc, level)
      raise "Need to implement examine_page in #{self.class}"
    end
  
    def get_file_destpath_from_action(action)
      url_folder = action.uri.path
      File.join(action.destination_folder, url_folder)
    end
  end
end
