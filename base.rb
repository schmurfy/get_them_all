require "rubygems"
require "hpricot"
require "mechanize"
require "open-uri"
require "fileutils"
require "monitor"
require 'gtk2'
require 'gnomecanvas2'

require "logger"

#require "ruby-debug"
#Debugger.start

#require "memory_profiler"
#MemoryProfiler.start

class SiteDownloader
  
  @@verbose= true
  
  # format: [<url>, <action>, <level>, <parent_url>, destination_folder]
  # url is the target url
  # action is :examine, :download
  # level is the current path depth
  # parent_url is the parent's url for action :download
  # destination_folder is the sub folder where files will be saved if specified  
  # params are used by user script, not by core
  #
  class Action
    attr_accessor :url, :level, :destination_folder, :params
    
    def initialize(h)
      self.level= 0
      self.destination_folder= nil
      
      h.each do |key, val|
        if !val.nil? && respond_to?("#{key}=")
          send("#{key}=", val)
        end
      end
    end
  end
  
  class ExamineAction < Action

  end
  
  class DownloadAction < Action
    attr_accessor :parent_url
    
  end


  def initialize(root_url, folder_name)
    #@multithred_queue= {}.extend(MonitorMixin)
    # @multithred_queue.synchronize { do something with @multithred_queue }
    
    @error_counter= 0
    @galleries= []
    @base_url= root_url
    @folder_name= folder_name
    # Array of ActionToDo structures
    @actions_to_do= []
    @gallery_class= "Gallery"

    @window= Gtk::Window.new("Site Downloader")
    @window.signal_connect("destroy") do
      Gtk.main_quit()
    end
    
    @agent= WWW::Mechanize.new do |a|
      a.log = Logger.new("mechanize.log") if @@verbose
    end
    
    @agent.max_history= 1
    dummy= @agent.get(@base_url)
    
    FileUtils.mkdir_p( File.join(File.dirname(__FILE__), folder_name) )
  end
  
  def add_url_to_examine(url, destination_folder= nil)
    puts "will examine #{url} => #{destination_folder}" if @@verbose
    @actions_to_do<< ExamineAction.new({
      :url => url, 
      :destination_folder => destination_folder
    })
  end
  
  def examine_all_pages
    load_history
        
    # the main loop
    while !@actions_to_do.empty?  
      # takes first element in the array since << add the element at the end
      action= @actions_to_do.pop()
      # remove host from url if present
      if action.url.is_a?(String) && action.url[0...@base_url.size] == @base_url
        #url= url[@base_url.size .. action.url.size]
        action.url.slice!(0...@base_url.size)
      end
      
      case action
        when ExamineAction
          if @@verbose
            print "#{action.level} - Examining #{action.url}... " if action.url.is_a?(String)
          else
            print "."
          end
          
          doc= action.url.is_a?(WWW::Mechanize::Page) ? action.url :  open_url(action.url)
          
          if self.method(:examine_page).arity == 2
            new_actions= examine_page(doc, action.level)
          else
            new_actions= examine_page(doc, action.level, action.params)
          end
          
          puts new_actions.size if @@verbose
          
          new_actions.each do |new_action|
            if new_action.url.is_a?(String) && new_action.url[0...@base_url.size] == @base_url
              new_action.url.slice!(0...@base_url.size)
            #  new_action.url= new_action.url[@base_url.size..new_action.url.size]
            end
            new_action.destination_folder||= action.destination_folder
            new_action.level= action.level + 1
            
            if new_action.destination_folder.nil? and action.level == 1
              puts "FROM URL: #{action.url}"
            end
            
            #arr= [new_url, action, level + 1]
            # keep the url of the page juste before the download link
            if new_action.is_a?(DownloadAction)
              new_action.parent_url= ((action.level==0) ? new_action.url : action.url)
            end
            
            if @history.include?(new_action.url)
              if @@verbose
                puts "Skipping #{new_action.url}"
              else
                print "S"
              end
            else
              @actions_to_do<< new_action
            end
          end
         
        when DownloadAction
          if action.destination_folder.nil?
            raise "empty destination_folder for: #{action.url} , level #{action.level}"
          end
          
          destpath= get_file_destpath_from_url(action.url, action.destination_folder, action.params)
  
          
          # create folders if non existant
          begin
            FileUtils.mkdir_p( File.dirname(destpath) )
          rescue Errno::EINVAL
            puts"Invalid path: #{destpath}"
          end
          
          # find an unused filename
          while File.exists?(destpath)
            if @@verbose
              print "Renaming #{destpath}... "
            else
              print "R"
            end
            
            path, filename= File.dirname(destpath), File.basename(destpath).split(".")
            filename= "#{filename[0]}_#{random_string(2)}.#{filename[1]}"
            destpath= File.join(path, filename)
            puts destpath if @@verbose
          end
          
          
          # save the picture
          if action.url[0...4] != "http"
            action.url= File.join(@base_url, action.url)
          end
          
          print "Downloading: #{action.url}... " if @@verbose
          
          begin
            data= @agent.get_file(action.url)
          rescue WWW::Mechanize::ResponseCodeError => e
            puts "err #{e.response_code} for url '#{action.url}' "
            raise
            
          rescue Errno::EBADF
            print "E"
            sleep(0.5)
            retry
            
          rescue URI::InvalidURIError
            if @@verbose
              puts "Invalid URL: #{action.url}"
            else
              print "X"
            end
            
            next
          end
        
          begin
            open(destpath, "wb") do |bin_out|
              bin_out.write( data )
            end
          rescue Errno::EINVAL
            puts "Save error for url: '#{action.url}' "
            raise
          end
          
          # add metadat (source url)
          open(destpath + ":source_url", "w") do |f|
            f.puts File.join(@base_url, action.parent_url)
          end
          
          #bin_in.close
          #bin_out.close
          
          if @@verbose
            puts "ok"
          else
            print "D"
          end

          
          # picture has been downloaded, keep this information
          @history<< action.parent_url
        end
      Thread.pass  
    end
  
  ensure
    save_history
  end
  
  def get_file_destpath_from_url(url, destination_folder, params)
    File.join(File.dirname(__FILE__) , @folder_name, destination_folder, url)
  end
  
  # load already downloaded pictures from disk
  def load_history
    @history= []
    path= File.join(File.dirname(__FILE__), @folder_name, "history.txt" )
    if File.exists?(path)
      File.open(path, "r") do |f|
        f.each_line do |line|
          @history<< line.strip
        end
      end
    end
  end
  
  def save_history
    File.open( File.join(File.dirname(__FILE__), @folder_name, "history.txt" ), "w") do |f|
      @history.each do |url|
        f.puts(url)
      end
    end
  end
  
  def open_url(url)
    ret= nil
    if url[0...4] != "http"
      url= File.join(@base_url, url)  
    end
    timeout(10){ ret= @agent.get({
      :url => url, 
      :referer => WWW::Mechanize::Page.new(nil, {'content-type'=>'text/html'})
    })}
    @error_counter= 0
    ret
  rescue WWW::Mechanize::ResponseCodeError
    puts "Error(#{$!.response_code}): '#{url}' "
    raise
    
  rescue Timeout::Error, Net::HTTPBadResponse
    if @error_counter <= 5
      @error_counter+= 1
      
      if @@verbose
        puts "Connection error: #{$!}"
      else
        print "E"
      end
      
      sleep(0.5)
      retry
    else
      raise
    end
  end
  
  def run
    Gtk.init_add do
      examine_all_pages
    end
    
    width= @galleries.map{|g| g.pages_count }.max
    @drawing_area= Gnome::Canvas.new(true)
    @drawing_area.show
    
    @window.add(@drawing_area)
    @window.show
    @drawing_area.set_size_request(width, @galleries.size)
    Gnome::CanvasRect.new(@drawing_area.root, {
      :x1 => 0,
      :x2 => width,
      :y1 => 0,
      :y2 => @galleries.size,
      :fill_color_rgba => 0x00FFFF00
    })
    @drawing_area.update_now
    Gtk.main  
  end
  
protected
  def remove_from_start(url, host)
    if url[0...host.size] == host
      url= url[host.size..url.size]
    end   
  end

  def random_string(len=5)
    ret= ""
    chars= ("0".."9").to_a + ("a".."z").to_a
    1.upto(len) { |i| ret<< chars[rand(chars.size-1)] }
    ret
  end
end