class Action
  attr_accessor :url, :level, :destination_folder, :params, :referer
  attr_accessor :parent_url
  
  include EM::Deferrable
  
  def initialize(downloader, h)
    @downloader = downloader
    
    @level= 0
    @destination_folder= nil
    @when_done = EM::DefaultDeferrable.new
    
    h.each do |key, val|
      fail("unknown properties #{key} !") unless respond_to?("#{key}=")
      send("#{key}=", val) unless val.nil?
    end
  end
  
  # call this block when the action is done whether it was a success or failure
  def when_done(&block)
    @when_done.callback(&block)
  end
  
  
  # internals
  def history
    @downloader.instance_variable_get("@history")
  end
  
  def add_downloaded_file
    tmp = @downloader.instance_variable_get("@download_files")
    @downloader.instance_variable_set("@download_files", tmp + 1)
  end
  
  def add_skipped_file
    tmp = @downloader.instance_variable_get("@skipped_files")
    @downloader.instance_variable_set("@skipped_files", tmp + 1)
  end
  
  def queue_action(action)
    action.parent_url = @url
    action.destination_folder ||= @destination_folder
    @downloader.instance_variable_get("@actions_queue").push(action)
  end
  
  # return a number between 0.1 and 1
  def retry_time
    0.1 * (rand(1000)+1)/100
  end
  protected :retry_time
  
end

class ExamineAction < Action
  
  def do_action()
    unless history.include?(@url)
      req = @downloader.open_url(@url, "GET", nil, @referer) do |req|
        debug("    examining #{@url}", '.')
        doc = Hpricot( req.content )
        actions = @downloader.examine_page(doc, @level + 1)
        actions.each do |action|
          queue_action(action)
        end
      end
      
      req.timeout(5)
      
      req.errback do
        set_deferred_status(:failed)
        @when_done.set_deferred_status(:succeeded)
      end
      
      req.callback do
        set_deferred_status(:succeeded)
        @when_done.set_deferred_status(:succeeded)
      end
      
    else
      add_skipped_file
      debug("Skipping #{url}", "S")
      @when_done.set_deferred_status(:succeeded)
    end
    
  end
end

class DownloadAction < Action
  
  def do_action()
    req = @downloader.open_url(@url, "GET", nil, @referer) do |req|
      debug("    downloading #{@url}", "D")
      
      destpath = compute_filename()
      
      # save in file
      begin
        open(destpath, "wb") do |bin_out|
          bin_out.write( req.content )
          add_downloaded_file
        end
      rescue Errno::EINVAL
        error("Save error for url: '#{action.url}' ")
        raise
      end
      
      
      add_to_history()
      set_deferred_status(:succeeded)
      @when_done.set_deferred_status(:succeeded)
      
      # add metadata (source url)
      # open(destpath + ":source_url", "w") do |f|
      #   f.puts File.join(@base_url, action.parent_url)
      # end
    end
    
    req.timeout(5)
    
    req.errback do
      
      # remove file if created
      File.delete( compute_filename() ) if File.exist?(compute_filename())
      
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
    destpath= @downloader.get_file_destpath_from_url(@url, @destination_folder)
    
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
      debug("Renamed as #{filename}", "R")
    end
    
    destpath
  end
end