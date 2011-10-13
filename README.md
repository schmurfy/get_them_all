= What is it ?

Get Them All is my personal try at building a versatile and powerful web downloader, its goal is pretty simple:
download all the targets and keep up to date with new content by remembering what was downloaded.

It should be able to download ay file type and try as much as possible to not make any assumptions on how the
targeted website is built.

EventMachine is used to power the core, hpricot is used to parse the html.

# Why ?

I simply never found any tool fulfilling my needs so I made mine ;)


# What can it do for you

First let's start by what is currently supported:

- authentication
- the referer is passed from one page to another so any leeched detection
  by referer will fail
- cookies are passed too
- parallel download, you decide how many parallel tasks are executed
  you can go as high as you want but don't be stupid !
- multiple storage backend, currently the files can be saved in:
  - local disk
  - dropbox

Any website is considered as a pytamid, let's take a gallery website as an example:

- the first level would be the page containing all the thumbnails
- the second level would be a page showing the picture
- the third level would be the link to the picture itself

I decided on this model after some testing and until now I never found a
website where this cannot be applied


# Current state

The application is already ready for my needs and may be for someone else.
Currently all the connections errors may not be correctly handled especially if
the web server really has trouble keeping connections alive to serve the clients
(like for the example above).


# Usage

The application looks for recipes in the sites folder, a simple recipe looks like:
(I took a useless ad loaded website so it will not hurt anyone)

```ruby
#
# example recipe
#
class WallpapersDownloader < SiteDownloader
  
  def initialize(args)
    args.merge!(:base_url => "http://wallpapers.diq.com/", :folder_name => "walpapers_ru")
    super(args) do
      # Here you need to tell the engine what are your level 0 urls
      # this can be as many url as you want
      examine_url("/wp/30.html", 0, "images")
    end
  end
  
  # This method will be called by the engine each time an "examine"
  # action is executed, you are responsible for telling it what
  # to do next.
  #
  def examine_page(doc, level, action)
    ret= []
    case level
      
      when 0 # first level: thumbnails list
      
        # You need to find a css expressions matching all the links,
        # this can be done in one or mote searches.
        #
        doc.search('td[@valign="top"][@height="102"] a') do |el|
          unless el.search('img[@width="128"][@height="96"][@border="0"]').empty?
            # We found an interesting link, each examine action created will
            # have its level just above the current one, in this
            # case it will be a level 1 action.
            #
            ret << ExamineAction.new(self, :url => el.attributes['href'])
          end
        end
        
        # The assert instruction is provided to ensure the recipe is still valid.
        # The idea is that if an assert fails you need to update your css expressions
        # since the website probably changed.
        #
        assert(ret.size <= 15, "too many entries: #{ret.size}")
        assert(ret.size > 0, "cannot be empty: #{ret.size}")
      
      when 1 # second level: the picture page
        
        # like above we need a css expression to isolate the link but
        # this time this is the picture url
        #
        doc.search('td[@valign="top"][@height="390"] img[@width="512"][@height="384"]') do |el|
          ret << DownloadAction.new(self, :url => el.attributes['src'])
        end

        assert(ret.size == 1, "should contain one picture")
    end
      
    ret
  end
    
end
```
