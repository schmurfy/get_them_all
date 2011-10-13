
require 'addressable/uri'
require 'active_support/hash_with_indifferent_access'

require 'em-http-request'
require 'em-priority-queue'
require 'v8'

class SiteDownloader
  include Notifier
  
  class_attribute :examiners_count, :downloaders_count
  class_attribute :config
  
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
  
  self.examiners_count = 1
  self.downloaders_count = 1
  
  self.history_tracking = :default
  
  attr_reader :base_url, :storage, :history
  
  def initialize(args)
    
    # @storage = args.delete(:storage)
    # raise "storage required" unless @storage
    
    @cookies = {}
    @history = []
    @connections = {}
    @examine_queue = EM::PriorityQueue.new
    @download_queue = EM::PriorityQueue.new
    
    
    @base_url= args.delete(:base_url)
    @folder_name= args.delete(:folder_name)
    @options = args.delete(:options) || {}
    
    storage_class = "#{SiteDownloader.config.storage.location.camelize}Storage"
    raise "unknown storage: #{storage_class}" unless defined?(storage_class)
    
    storage_class = Object.const_get(storage_class)
    
    storage_class = storage_class
    storage_options = ActiveSupport::HashWithIndifferentAccess.new( SiteDownloader.config.storage.params )
    # storage_options = args.delete(:storage_options) || {
    #     :root => File.join('/Users/Shared/Pics', @folder_name)
    #   }
      
    @storage = storage_class.new(storage_options.merge(:folder_name => @folder_name))
    
    @parsed_base_url = Addressable::URI.parse(@base_url)
    
    unless args.empty?
      raise "unknown parameters: #{args.inpsect}"
    end
    
    @extensions = [
        GraphBuilder.new,
        ActionLogger.new
      ]
    
    # start download
    start do
      yield() if block_given?
    end
    
    # unless verbose?
    #   # initialize terminal
    #   lines = self.class.examiners_count + self.class.downloaders_count
    #   lines.times{ print "\n" }
    #   Cursor::up(lines)
    # end
  end
  
  
  def start
    load_history()
    
    notify('downloader.started', self)
    
    EM::run do
      EM::add_periodic_timer(5) do
        if (EM::connection_count() == 0) && !@storage.working?
          debug("no connections, exiting")
          EM::stop_event_loop()
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
     
      # recipe will authenticate us if needed and start
      # queuing the first actions.
      # 
      yield() if block_given?
      
      # now that actions are queued, start handling them
      # start each "worker"
      # dequeuing is priority based, the download actions
      # first and then the higher the level the higher the
      # priority for examine actions
      # 
      1.upto(self.class.examiners_count) do |n|
        Worker.new("ex#{n}", self, @examine_queue)
      end
      
      1.upto(self.class.downloaders_count) do |n|
        Worker.new("dl#{n}", self, @download_queue)
      end

    end
   
    save_history()
    
    notify('downloader.completed', self)
  end
  private :start
  
  
  def verbose?
    @options[:verbose]
  end
  
  class AssertionFailed < RuntimeError; end
  
  def assert(cond, msg = "")
    unless cond
      raise AssertionFailed, msg
    end
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

    return ret
  end
  
  HISTORY_FILE_PATH = 'history.txt'.freeze
  
  # load already downloaded pictures from disk
  def load_history
    if @storage.exist?(HISTORY_FILE_PATH)
      @history = @storage.read(HISTORY_FILE_PATH).split("\n")
    end
  end
  
  def save_history
    @storage.write(HISTORY_FILE_PATH, @history.join("\n"))
  end


  
  
  # Plugin API
  def open_url(url, method = "GET", params = nil, referer = nil, deferrable = nil, &block)
    
    # if deferrable
    #   puts "Reusing deferrable for #{url}"
    # end
    
    deferrable ||= EM::DefaultDeferrable.new
    
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
          @cookies = req.cookies
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
      
      when 301, 302
        location = req.response_header.location
        if location
          debug("Following redirection: #{location}")
          # reuse the same deferrable object
          open_url(location, method, params, referer, deferrable, &block)
        end
        
      else
        puts "Status: #{req.response_header.status}"
        deferrable.set_deferred_status(:failed, req.response_header.http_reason)
      end
    end
    
    req.errback do
      deferrable.set_deferred_status(:failed, -1)
    end
    
    deferrable
  end
  
  def examine_url(url, level, destination_folder, referer = nil)
    @examine_queue.push(ExamineAction.new(self,
        :url => url,
        :level => level,
        :destination_folder => destination_folder,
        :referer => referer
      ), 0)
  end
  
  def download_url(url, level, destination_folder, referer = nil)
    @download_queue.push(DownloadAction.new(self,
        :url => url,
        :level => level,
        :destination_folder => destination_folder,
        :referer => referer
      ), 0)
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