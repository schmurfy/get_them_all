#
# workers are created to follow a queue
# each time an action is put in the queue it will handle it
#
class Worker
  def initialize(name, downloader, queue)
    @downloader = downloader
    @queue = queue
    @name = name
    
    @queue.pop do |action|
      handle_action(action)
    end
    
  end
  
  ##
  # Take the next action in queue
  # 
  def take_next_job
    EM::next_tick do
      @queue.pop{|act| handle_action(act) }
    end
  end
  
  
  def handle_action(action)
    action.callback( &method(:take_next_job) )
    action.errback do
      # in case of failure, try again later (with slightly lower priority)
      EM::add_timer(50) do
        @queue.push(action, [action.level - 1, 0].max)
      end
      
      # and take the next job
      take_next_job()
    end
    
    action.do_action()
  end
  
end