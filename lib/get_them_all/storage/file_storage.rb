module GetThemAll
  class FileStorage < Storage
  
    # def initialize(options = {})
    #   super
    # end
  
    def exist?(path)
      destpath = build_destpath(path)
      File.exist?(destpath)
    end
  
    def write(path, data)
      deferrable = EM::DefaultDeferrable.new
    
      destpath = build_destpath(path)
      FileUtils.mkdir_p( File.dirname(destpath) )
      open(destpath, "wb") do |f|
        f.write( data )
      end
    
      deferrable.succeed
      deferrable
    
    rescue Errno::EINVAL
      deferrable.fail
      raise Storage::WriteError("cannot write file")
    end
  
    def read(path)
      destpath = build_destpath(path)
      if File.readable?(destpath)
        File.read(destpath)
      else
        raise Storage::ReadError("cannot open file")
      end
    end
  
  end
end
