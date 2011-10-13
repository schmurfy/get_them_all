
require 'hpricot'

class ExamineAction < Action
  
  def priority
    @level
  end
  
  def action_succeeded()
    set_deferred_status(:succeeded)
  end
  
  def action_failed(status)
    notify('action.examine.failure', self, status)
    set_deferred_status(:failed)
  end
  
  
  def do_action()
    notify('action.examine.started', self)
    
    if already_visited?(@url)
      notify('action.examine.skipped', self)
      action_succeeded()
      
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
        
        notify('action.examine.success', self, actions)
        action_succeeded()
      end
      
      req.timeout(5)
      
      req.errback do |*args|
        status = (args.size == 1) ? args.first : 0
        action_failed(status)
      end
      
    end
  end
  
end
