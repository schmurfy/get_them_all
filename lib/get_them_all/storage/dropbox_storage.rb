require 'stringio'
require 'dropbox'
require 'girl_friday'

module GetThemAll
  class DropboxStorage < Storage
  
  
    # def self.deserialize(data)
    #   consumer_key, consumer_secret, authorized, token, token_secret, ssl, mode = YAML.load(StringIO.new(data))
    #   raise ArgumentError, "Must provide a properly serialized #{self.to_s} instance" unless [ consumer_key, consumer_secret, token, token_secret ].all? and authorized == true or authorized == false
    # 
    #   session = self.new(consumer_key, consumer_secret, :ssl => ssl, :already_authorized => authorized)
    #   if authorized then
    #     session.set_access_token token, token_secret
    #   else
    #     session.set_request_token token, token_secret
    #   end
    #   session.mode = mode if mode
    # 
    #   return session
    # end
  
    def initialize(options = {})
      super
    
      session_data = options.delete(:session)
      raise "session missing" unless session_data
    
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
        destpath = build_destpath(path)
        filename, dirname = File.basename(destpath), File.dirname(destpath)
        @session.upload(StringIO.new(data), dirname, :as => filename)
        EM::next_tick{ deferrable.succeed }
      end
    
      deferrable
    rescue => err
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
      raise ReadError, "cannot read file: #{err}"
    end
  
  end
end
