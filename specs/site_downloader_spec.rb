require File.expand_path('../common', __FILE__)

EM.describe 'SiteDownloader' do
  before do
    # GetThemAll::SiteDownloader.any_instance.stubs(:debug)
    
    
    @downloader = GetThemAll::SiteDownloader.new(
        :folder_name => 'tmp',
        :base_url => 'http://www.google.fr',
        :storage => {
          :type => 'file',
          :params => { :root => '/tmp' }
        }
      )
  end
  
  it 'can check if two urls are from the same domain' do
    @downloader.same_domain?('www.test.com', 'test.com').should == true
    @downloader.same_domain?('test.com', 'test.com').should == true
    @downloader.same_domain?('test.com', 'test2.com').should == false
    
    done
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
