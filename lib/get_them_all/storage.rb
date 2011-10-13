module GetThemAll
  class Storage
    
    class StorageError < RuntimeError; end
    class WriteError < StorageError; end
    class ReadError < StorageError; end
  
    def initialize(options = {})
      @root = options.delete(:root)
      @folder_name = options.delete(:folder_name)
      raise "missing required option: folder_name" unless @folder_name
      raise "missing required option: root" unless @root
    
      @root = File.join(@root, @folder_name)
      raise "missing required option: root" unless @root
    end
  
    def working?
      false
    end
  
    def build_destpath(path)
      File.join(@root, path)
    end
  
  end
end
