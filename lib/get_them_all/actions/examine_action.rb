
require 'hpricot'

module GetThemAll
  class ExamineAction < Action
  
    def priority
      @level
    end  
  
    def do_action(worker = nil)
      notify('action.examine.started', worker, self)
    
      if already_visited?(@url)
        notify('action.examine.skipped', worker, self)
        set_deferred_status(:succeeded)
      
      else
        req = @downloader.open_url(@url, "GET", nil, @referer)
        req.callback do |req|
          doc = Hpricot( req.response )
      
          actions = @downloader.examine_page(doc, @level, self)
          actions.each do |action|
            action.level = @level + 1
            # action.params = @params.merge(action.params)
            queue_action(action)
          end
        
          notify('action.examine.success', worker, self, actions)
          set_deferred_status(:succeeded)
        end
      
        req.timeout(5)
      
        req.errback do |*args|
          status = (args.size == 1) ? args.first : 0
          notify('action.examine.failure', worker, self, status)
          set_deferred_status(:failed)
        
        end
      
      end
    end
  
  end
end
