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
  
  
  
  def handle_action(action)
    # puts "Worker [#{@name}] called for action #{action.class} on #{action.url}"
    
    action.when_done do
      # handle the next action in queue
      @queue.pop{|act| handle_action(act) }
    end
    
    action.errback do
      # in case of failure, try again later
      EM::add_timer(50){ @queue.push(action) }
    end
    
    action.do_action()
  end
  
end