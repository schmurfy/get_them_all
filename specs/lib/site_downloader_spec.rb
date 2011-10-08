require File.expand_path('../../common', __FILE__)

EM.describe 'SiteDownloader' do
  before do
    FileUtils.expects(:mkdir_p).once
    
    SiteDownloader.any_instance.stubs(:start)
    SiteDownloader.any_instance.stubs(:debug)
    
    
    @downloader = SiteDownloader.new(
        :folder_name => 'tmp',
        :base_url => 'http://www.google.fr'
      )
  end
  
  describe 'open_url' do
    should 'issue GET Requests' do
      timeout(2)
      
      @downloader.open_url('http://twitter.com/about') do |req, doc|
        doc.search('title').inner_text.should == "Twitter"
        done
      end
    end
  end
  
end
