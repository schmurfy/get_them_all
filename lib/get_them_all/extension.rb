require 'active_support/notifications'

module GetThemAll
  class Extension
  
    ##
    # Register a handler to call when this notification
    # is sent
    # 
    # @param [String] name notification identifier
    # 
    def register_handler(name, &block)
      ActiveSupport::Notifications.subscribe(name, &block)
    end
  
  end
end