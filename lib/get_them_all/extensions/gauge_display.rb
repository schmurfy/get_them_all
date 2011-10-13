
module GetThemAll
  ##
  # This extension will show you a progress bar for each worker
  # showing its current state:
  # ~ = working
  # D = url downloaded
  # E = url examined
  # . = url skipped
  # x = url download failed
  # 
  # The extension knowns how to handle the terminal width nicely, if
  # it reachs the right end of the terminal the line will scroll
  # (characters will disappear on the left while new appear on the right)
  # 
  class GaugeDisplay < Extension
    module Cursor
      class << self
        def up(n);        print "\e[#{n}A" if n > 0; end
        def down(n);      print "\e[#{n}B" if n > 0; end
        def right(n);     print "\e[#{n}C" if n > 0; end
        def left(n);      print "\e[#{n}D" if n > 0; end

        def col(n);       print "\e[#{n}G"; end
        def clear_line;   print "\e[0K";    end

        # save / restore
        def save;         print "\e[s";     end
        def restore;      print "\e[u";     end

        # hide / show
        def hide_cursor;  print "\e[?25l";  end
        def show_cursor;  print "\e[?25h";  end

        def screen_width
          `tput cols`.strip.to_i
        end
      end
    end
  
    def initialize
      register_handler('downloader.started', &method(:downloader_started))
      # examine actions
      register_handler('action.examine.started', &method(:work_started))
      register_handler('action.examine.success', &method(:work_completed))
      register_handler('action.examine.failure', &method(:work_failed))
      register_handler('action.examine.skipped', &method(:work_skipped))
    
      # download actions
      register_handler('action.download.started', &method(:work_started))
      register_handler('action.download.success', &method(:work_completed))
      register_handler('action.download.failure', &method(:work_failed))
      register_handler('action.download.skipped', &method(:work_skipped))
    end
  

    def downloader_started(event_name, downloader)
      # initialize the screen
      @examiners = downloader.examiners_count
      @downloaders = downloader.downloaders_count
    
      # save cursor position before doing anything
      Cursor.save()
    
      # store screen state
      @state = []
      (@examiners + @downloaders).times do |n|
        puts "#{n} "
        @state[n] = "#{n} "
      end
    end
  
    def work_started(event_name, worker, action, *args)
      Cursor.restore()
      line = worker_line(worker)
    
      # move to the correct line
      Cursor.down( line )
    
      # and column
      Cursor.right(@state[line].size)
    
      print "~"
    end
  
    def update_line(line, added_str)
      # update internal state
      state = @state[line]
      state << added_str
    
      # resize line if required
      if state.size > Cursor.screen_width
        header = state[0,2]
        size = Cursor.screen_width - header.size
        state = header + state[-size..-1]
      end
    
      # move to column 0
      Cursor.col(0)
      # erase entire line
      Cursor.clear_line()
    
      print state
    end
  
  
    def work_completed(event_name, worker, action, *args)
      Cursor.restore()
      line = worker_line(worker)
    
      Cursor.down( line )
      #Cursor.right(@state[line].size)
    
      if worker.type == :examiner
        update_line(line, "E")
      else
        update_line(line, "D")
      end
    end
  
  
    def work_failed(event_name, worker, action, *args)
      Cursor.restore()
      line = worker_line(worker)
    
      # move to the correct line
      Cursor.down( line )
    
      # and column
      # Cursor.right(2 + @state[line].size)
    
      update_line(line, "x")
    end
  
  
    def work_skipped(event_name, worker, action, *args)
      Cursor.restore()
      line = worker_line(worker)
    
      # move to the correct line
      Cursor.down( line )
    
      # and column
      # Cursor.right(2 + @state[line].size)
    
      update_line(line, ".")
    end
  
  private
    def worker_line(worker)
      base_index = (worker.type == :examiner) ? 0 : @examiners
      base_index + worker.index
    end
  end
end
