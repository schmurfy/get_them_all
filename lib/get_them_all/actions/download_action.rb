module GetThemAll
  class DownloadAction < Action
    def priority
      10
    end
  
    def do_action(worker = nil)
      notify('action.download.started', worker, self)
    
      if already_visited?(@url)
        notify('action.download.skipped', worker, self)
        set_deferred_status(:succeeded)
      else
    
        req = @downloader.open_url(@url, "GET", nil, @referer)
        req.callback do |req|
          
          destpath= @downloader.get_file_destpath_from_action(self)
          
          file_exists = @storage.exist?(destpath)
          
          # if the destination path does not already exists
          # or if it does exists but we were asked to rename
          # the file.
          # 
          if !file_exists || @downloader.rename_duplicates
            
            if file_exists
              destpath = compute_unique_filename(destpath)
              notify('action.download.renamed', worker, self, destpath)
            end
            
            download = @storage.write(destpath, req.response)

            download.callback do      
              add_to_history()
              set_deferred_status(:succeeded)

              notify('action.download.success', worker, self, destpath)
            end

            download.errback do
              notify('action.download.failure', worker, self)
            end
            
          else
            # if we arrive here the destination exists
            # and we don't want to rename it
            add_to_history()
            set_deferred_status(:succeeded)
            notify('action.download.already_exists', worker, self, destpath)
          end
          
        end
    
        req.timeout(5)
    
        req.errback do |*args|
          status = (args.size == 1) ? args.first : 0
      
          # # remove file if created
          # path = compute_unique_filename(worker)
          # File.delete(path) if File.exist?(path)
      
          notify('action.download.failure', worker, self)
      
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
        @downloader.history.add(@parent_url)
      else
        @downloader.history.add(@url)
      end
    end
  
    def compute_unique_filename(destpath)
      # find an unused filename
      begin
        path, filename= File.dirname(destpath), File.basename(destpath).split(".")
        filename= "#{filename[0]}_#{random_string(2)}.#{filename[1]}"
        destpath= File.join(path, filename)
      end while @storage.exist?(destpath)
    
      destpath
    end
  end
end
