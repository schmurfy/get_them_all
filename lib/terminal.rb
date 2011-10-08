
module Cursor
  class << self
    def up(n)
      print "\e[#{n}A"
    end

    def down(n)
      print "\e[#{n}B"
    end

    def right(n)
      print "\e[#{n}C"
    end

    def left(n)
      print "\e[#{n}D"
    end
    
    # save / restore
    def save
      print "\e[s"
    end

    def restore
      print "\e[u"
    end
    
    # hide / show
    def hide_cursor
      print "\e[?25l"
    end

    def show_cursor
      print "\e[?25h"
    end
  end
end