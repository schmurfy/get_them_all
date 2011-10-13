
module GetThemAll
  ##
  # This extension can be considered as a verbose mode, it
  # logs nearly every everything that happens.
  # 
  class ActionLogger < Extension
    def initialize
      register_handler('downloader.started') do |name, downloader|
        @skipped_files = 0
        @download_files = 0
      end
    
      register_handler('action.examine.started') do |name, worker, action|
        log("Examining[#{action.level}] #{action.url}")
      end
    
      register_handler('action.examine.skipped') do |name, worker, action|
        @skipped_files += 1
        log("Skipping #{action.url}")
      end
    
      register_handler('action.examine.success') do |name, worker, action|
        # do nothing
      end
    
    
      register_handler('action.download.started') do |name, worker, action|
        log("Downloading #{action.url}")
      end
    
      register_handler('action.download.renamed') do |name, worker, action, new_path|
        log("Renamed as #{File.basename(new_path)}")
      end
    
      register_handler('action.download.skipped') do |name, worker, action|
        log("url Skipped: #{action.url}")
      end
    
      register_handler('action.download.success') do |name, worker, action, destpath|
        @download_files += 1
        log("File downloaded: #{destpath}")
      end
    
      register_handler('downloader.completed') do |name, worker, downloader|
        log ""
        log "Downloaded #{@download_files} files"
        log "Skipped: #{@skipped_files}"
      end
    
    end
  
    def log(str)
      puts "[log] #{str}"
    end
  
  end
end
