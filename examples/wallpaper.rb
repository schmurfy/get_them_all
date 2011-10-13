
# 
# example recipe
# This example does not show everything the engine can do but I tried
# to show most of them.
#
class WallpaperDownloader < GetThemAll::SiteDownloader
  
  self.examiners_count= 3
  self.downloaders_count= 2
  
  def initialize(args)
    super(args.merge(
        :base_url => "http://wallpapers-diq.com/",
        :start_url => "/", # default
        :folder_name => "walpapers_ru/images",
      ))
  end
  
  # This method will be called by the engine each time an "examine"
  # action is executed, you are responsible for telling it what
  # to do next.
  #
  def examine_page(doc, level, action)
    ret= []
    case level
      when 0 # base_url
        pages = find_pages_count(doc)
        info "#{pages} pages found !"
        
        # examine this page again but as a level 1
        ret << GetThemAll::ExamineAction.new(self, :url => "/wp/30.html")
        
        # and the other pages
        1.upto( pages ) do |n|
          ret << GetThemAll::ExamineAction.new(self, :url => "/wp/30_#{n}.html")
        end
        
      when 1 # first level: thumbnails list
      
        # You need to find a css expressions matching all the links,
        # this can be done in one or mote searches.
        #
        doc.search('td[@valign="top"][@height="100"] a') do |el|
          unless el.search('img[@width="128"][@height="96"][@border="0"]').empty?
            # We found an interesting link, each examine action created will
            # have its level just above the current one, in this
            # case it will be a level 1 action.
            #
            ret << GetThemAll::ExamineAction.new(self, :url => el.attributes['href'])
          end
        end
        
        # The assert instruction is provided to ensure the recipe is still valid.
        # The idea is that if an assert fails you need to update your css expressions
        # since the website probably changed.
        #
        assert(ret.size <= 15, "too many entries: #{ret.size}")
        assert(ret.size > 0, "cannot be empty: #{ret.size}")
      
      when 2 # second level: the picture page
        
        # like above we need a css expression to isolate the link but
        # this time this is the picture url
        #
        doc.search('a#link img[@width="512"][@height="384"]') do |el|
          ret << GetThemAll::DownloadAction.new(self, :url => el.attributes['src'])
        end
        
        assert(ret.size == 1, "should contain one picture")
    end
      
    ret
  end
  
private
  ##
  # Extract the number of pages from the page.
  # 
  def find_pages_count(doc)
    elements = doc.search('td[@colspan] a[@href^="http://wallpapers-diq.com/wp/"]:not([@rel])')
    assert(elements.size > 0, "Unable to find pages count")
    
    elements.last.inner_text.to_i
    
    # TODO: remove
    1
  end
    
end
