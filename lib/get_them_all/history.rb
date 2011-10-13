module GetThemAll
  class History
    def initialize(data = [])
      @data = data
    end
    
    def load(data)
      @data = data.split("\n")
    end
  
    def dump
      @data.join("\n")
    end
    
    def include?(line)
      @data.include?(line)
    end
    
    def add(url)
      @data << url
    end
  end
end
