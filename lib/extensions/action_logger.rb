class ActionLogger < Extension
  def initialize
    register_handler('downloader.started') do |name, downloader|
      @skipped_files = 0
      @download_files = 0
    end
    
    register_handler('action.examine.started') do |name, action|
      debug("    examining[#{action.level}] #{action.url}", '.')
    end
    
    register_handler('action.examine.skipped') do |name, action|
      @skipped_files += 1
      debug("Skipping #{action.url}", "S")
    end
    
    register_handler('action.download.started') do |name, action|
      debug("    downloading #{action.url}", "D")
    end
    
    register_handler('action.download.renamed') do |name, action, new_path|
      debug("Renamed as #{File.basename(new_path)}", "R")
    end
    
    register_handler('action.download.success') do |name, action, destpath|
      @download_files += 1
      info("file downloaded: #{destpath}")
    end
    
    register_handler('downloader.completed') do |name, downloader|
      puts ""
      puts "Downloaded #{@download_files} files"
      puts "Skipped: #{@skipped_files}"
    end
    
  end
end
