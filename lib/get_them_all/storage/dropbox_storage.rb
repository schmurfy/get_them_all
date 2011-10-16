require 'stringio'
require 'dropbox'
require 'girl_friday'

module GetThemAll
  class DropboxStorage < Storage
    
    ##
    # Constructor
    # 
    # @param [Hash] options options
    # @option options [Array] :session The session array
    # @option options [Integer] :timeout The timeout for
    #   dropbox requests.
    # 
    def initialize(options = {})
      super
    
      session_data = options.delete(:session)
      raise "session missing" unless session_data
      
      # default to 30s timeout
      @timeout = options.delete(:timeout) || 30
    
      consumer_key, consumer_secret, authorized, token, token_secret, ssl, mode = session_data
    
      @session = Dropbox::Session.new(consumer_key, consumer_secret, :ssl => ssl, :already_authorized => authorized)
      @session.set_access_token(token, token_secret)
      @session.mode = mode.to_sym
    
      @queue = GirlFriday::WorkQueue.new(:dropbox_upload, :size => 1) do |msg|
        # puts "Uploading file #{msg[:path]}..."
        write(msg[:path], msg[:data], false, msg[:deferrable])
        # puts "Upload ok."
      end
    end
  
    ##
    # Can we exit or is there still some work to do ?
    # 
    # @return [Boolean]
    # 
    def working?
      s = @queue.status['dropbox_upload']
      (s[:backlog] > 0) || (s[:busy] > 0)
    end
  
    ##
    # Check if the remote file/folder exists,
    # there may be a better way but it works.
    # 
    # @return [Boolean] true if the remote path exists
    # 
    def exist?(path)
      destpath = build_destpath(path)
    
      metadata = @session.metadata(destpath)
      if metadata.respond_to?(:is_deleted) && metadata.is_deleted
        false
      else
        true
      end
      
    rescue Dropbox::FileNotFoundError
      false
    rescue => err
      show_error(err)
      false
    end
  
    ##
    # Write data in a remote file.
    # Folders in the path will be automatically created as
    # needed.
    # 
    def write(path, data, delay = true, deferrable = EM::DefaultDeferrable.new)
      retries = 0
    
      if delay
        @queue.push(:path => path, :data => data, :deferrable => deferrable)
      else
        deferrable.timeout(@timeout)
        
        destpath = build_destpath(path)
        filename, dirname = File.basename(destpath), File.dirname(destpath)
        @session.upload(StringIO.new(data), dirname, :as => filename)
        EM::next_tick{ deferrable.succeed }
      end
      
      deferrable
    rescue => err
      show_error(err)
      if retries < 4
        # puts "[#{retries}] Upload error, retrying: #{err}"
        retries += 1
        retry
      else
        EM::next_tick{ deferrable.fail }
        raise WriteError, "cannot write file: #{err}"
      end
    end
  
    ##
    # Read file's content and return it.
    # 
    # @return [String] file's content
    # 
    def read(path)
      destpath = build_destpath(path)
      @session.download(destpath)
    rescue => err
      show_error(err)
      raise ReadError, "cannot read file: #{err}"
    end
  
  end
end
