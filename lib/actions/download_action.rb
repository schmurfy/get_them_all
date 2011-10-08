class DownloadAction < Action
  def priority
    10
  end
  
  def do_action()
    notify('action.download.started', self)
    
    req = @downloader.open_url(@url, "GET", nil, @referer)
    req.callback do |req|
      
      destpath = compute_filename()
      
      # save in file
      begin
        open(destpath, "wb") do |bin_out|
          bin_out.write( req.response )
        end
      rescue Errno::EINVAL
        error("Save error for url: '#{action.url}' ")
        raise
      end
      
      add_to_history()
      set_deferred_status(:succeeded)
      @when_done.set_deferred_status(:succeeded)
      
      notify('action.download.success', self, destpath)
      
      # add metadata (source url)
      # open(destpath + ":source_url", "w") do |f|
      #   f.puts File.join(@base_url, action.parent_url)
      # end
    end
    
    req.timeout(5)
    
    req.errback do |*args|
      status = (args.size == 1) ? args.first : 0
      
      # remove file if created
      File.delete( compute_filename() ) if File.exist?(compute_filename())
      
      notify('action.download.failure', self)
      
      set_deferred_status(:failed)
      @when_done.set_deferred_status(:succeeded)
    end
    
  end
  
private
  def random_string(len=5)
    ret= ""
    chars= ("0".."9").to_a + ("a".."z").to_a
    1.upto(len) { |i| ret<< chars[rand(chars.size-1)] }
    ret
  end
  
  def add_to_history()
    @downloader.instance_variable_get("@history").push(@parent_url)
  end
  
  def compute_filename
    destpath= @downloader.get_file_destpath_from_action(self)
    
    # create folders if non existant
    begin
      FileUtils.mkdir_p( File.dirname(destpath) )
    rescue Errno::EINVAL
      error("Invalid path: #{destpath}")
    end
    
    # find an unused filename
    while File.exists?(destpath)        
      path, filename= File.dirname(destpath), File.basename(destpath).split(".")
      filename= "#{filename[0]}_#{random_string(2)}.#{filename[1]}"
      destpath= File.join(path, filename)
      notify('action.download.renamed', self, destpath)
    end
    
    destpath
  end
end
