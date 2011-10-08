class JavascriptLoader
    
  ##
  # The goal is just to have something acting like a dom
  # from the outside
  class DOM
    def search; self; end
    def substr(*); ""; end
    def protocol; 'http'; end
    
    def location; self; end
    def appendChild(*); self; end
    def createElement(*); self; end
    def window; self; end
    
    def getElementsByTagName(*); [self]; end
    
    def ready(f)
      f.call()
    end
    
    def click(*); end
    def change(*); end
    def keydown(*); end
    def keyup(*); end
    def setInterval(*); end
    def setTimeout(*); end
    def attr(*); self; end
    def text(*); self; end
    def animate(*); self; end
    def empty(*); self; end
    def hide(*); self; end
    def show(*); self; end
    def focus(*); self; end
  end
  
  class JQuery
    
  end
  
  def initialize(source)
    @context = V8::Context.new do |ctx|
      ctx[:document] = DOM.new()
      ctx[:window] = DOM.new()
      ctx[:jQuery] = JQuery.new
      ctx['setInterval'] = ctx[:window].method(:setInterval)
      ctx['setTimeout'] = ctx[:window].method(:setTimeout)
    end
    
    @context.eval(%{
      $ = function(){
        return document;
      };
      
      $.cookie = function(){};
      $.each = function(){};
      
      // hash method cannot be defined on ruby side...
      window.location.hash = window;
    })
    
    @context.eval(source)
  end
  
  def eval(str)
    @context.eval(str)
  end
  
end

