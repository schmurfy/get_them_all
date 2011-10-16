module GetThemAll
  # 
  # workers are created to follow a queue
  # each time an action is put in the queue it will handle it
  #
  class Worker
    include Notifier
    
    attr_reader :type, :index
  
    def initialize(type, index, queue)
      @type = type
      @index = index
    
      @queue = queue
      @idle = true
      

      @stop_requested = false
      
      notify('worker.started', self)
      
      @queue.pop do |action|
        handle_action(action)
      end
    
    end
    
    ##
    # when called the worker will
    # finish the current job and then stop taking
    # new jobs.
    #
    # if a block is given it will be called when
    # the worker is no longer taking actions.
    # 
    def request_stop(&block)
      @stop_requested = true
      notify('worker.stop_requested', self)
      
      if @idle
        # we are already stopped, just call the block
        EM::next_tick{ block.call }
      else
        @stop_requested_block = block
      end
    end
    
    def idle?
      @idle
    end
    
    ##
    # Take the next action in queue
    # 
    def take_next_job
      @idle = true
      
      if @stop_requested
        # do not take new jobs and call
        # the passed block is any
        @stop_requested_block.call if @stop_requested_block
        notify('worker.stopped', self)
      else
        EM::next_tick do
          @queue.pop do |act|
            handle_action(act)
          end
        end
        
      end
    end
  
  
    def handle_action(action)
      @idle = false
      @current_action = action
      
      # register callbacks
      action.callback( &method(:action_succeeded) )
      action.errback( &method(:action_failed) )
      
      # and start the action
      action.do_action(self)
    end
  
  private
    def action_failed
      # in case of failure, try again later (with slightly lower priority)
      @queue.push(@current_action, [@current_action.level - 1, 0].max)
    
      # and take the next job
      take_next_job()
    end
    
    def action_succeeded
      take_next_job()
    end
    
  end
end
