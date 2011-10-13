module GetThemAll
  class Action
    include Notifier
  
    attr_accessor :url, :level, :destination_folder, :params, :referer
    attr_accessor :parent_url
  
    include EM::Deferrable
  
    def initialize(downloader, h, params = {})
      @downloader = downloader
    
      @storage = @downloader.storage
    
      @level= 0
      @params= h.delete(:params)
      @destination_folder= nil
    
      h.each do |key, val|
        raise ("unknown properties #{key} !") unless respond_to?("#{key}=")
        send("#{key}=", val) unless val.nil?
      end
    end
    
    def inspect
      "{#{self.class}[#{level}] #{url} }"
    end
  
    def uri
      URI.parse(@url)
    end
  
  
    def already_visited?(url)
      @downloader.history.include?(url)
    end
  
  
    # internals      
    def queue_action(action)
      action.parent_url = @url
      action.destination_folder ||= @destination_folder
    
      queue = action.is_a?(ExamineAction) ? "@examine_queue" : "@download_queue"
      @downloader.instance_variable_get(queue).push(action, action.priority)
    end
  
    # return a number between 0.1 and 1
    def retry_time
      0.1 * (rand(1000)+1)/100
    end
    protected :retry_time
  
  end
end
