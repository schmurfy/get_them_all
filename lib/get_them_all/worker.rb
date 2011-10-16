module GetThemAll
  # 
  # workers are created to follow a queue
  # each time an action is put in the queue it will handle it
  #
  class Worker
    include Notifier
    
    attr_reader :type, :index
    
    ##
    # Create a worker.
    # 
    # @param [StringSymbol] type Name assigned to the worker
    #   the only real use is to identify the worker.
    # @param [Integer] index additional way to indetify the worker.
    # @param [EM::Queue] queue the queue from which this worker
    #   will take its jobs.
    # @param [Integer,Array] delay Number of milliseconds between two
    #   actions, if an array is provided the value will be randomized
    #   between the two first values in the array.
    # 
    def initialize(type, index, queue, delay = 0)
      @type = type
      @index = index
      @delay = delay
      
      # ensure delay is valid
      unless @delay.is_a?(Integer) || (@delay.is_a?(Array) && @delay.size >= 2)
        raise "invalid value for delay: #{@delay}"
      end
    
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
        delay = delay_before_next_action()
        EM::add_timer(delay / 1000) do
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
    
    
    ##
    # Compute the delay before the next action can
    # take place.
    # 
    # @return [Integer] Number of milliseconds to wait
    # 
    def delay_before_next_action
      case @delay
      when Integer then  @delay
      when Array  then  rand(@delay[1] - @delay[0]) + @delay[0]
      else
        0
      end
    end
    
  end
end
