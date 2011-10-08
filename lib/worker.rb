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
      # puts "Worker [#{@name}] completed its job"
      # handle the next action in queue
      EM::next_tick do
        @queue.pop{|act| handle_action(act) }
      end
    end
    
    action.errback do
      # in case of failure, try again later (with slightly lower priority)
      EM::add_timer(50) do
        @queue.push(action, [action.level - 1, 0].max)
      end
    end
    
    action.do_action()
  end
  
end