class DownloadAction < Action
  def priority
    10
  end
  
  def do_action()
    notify('action.download.started', self)
    
    if already_visited?(@url)
      notify('action.download.skipped', self)
      set_deferred_status(:succeeded)
    else
    
      req = @downloader.open_url(@url, "GET", nil, @referer)
      req.callback do |req|
      
        destpath = compute_filename()
        download = @storage.write(destpath, req.response)
      
        download.callback do      
          add_to_history()
          set_deferred_status(:succeeded)
      
          notify('action.download.success', self, destpath)
        end
      
        download.errback do
          notify('action.download.failure', self)
        end
      
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
      end
    end
    
  end
  
private
  def random_string(len=5)
    ret= ""
    chars= ("a".."z").to_a
    1.upto(len) { |i| ret<< chars[rand(chars.size-1)] }
    ret
  end
  
  def add_to_history()
    if @downloader.class.history_tracking == :default
      @downloader.history.push(@parent_url)
    else
      @downloader.history.push(@url)
    end
  end
  
  def compute_filename
    destpath= @downloader.get_file_destpath_from_action(self)
        
    # find an unused filename
    while @storage.exist?(destpath)        
      path, filename= File.dirname(destpath), File.basename(destpath).split(".")
      filename= "#{filename[0]}_#{random_string(2)}.#{filename[1]}"
      destpath= File.join(path, filename)
      notify('action.download.renamed', self, destpath)
    end
    
    destpath
  end
end
