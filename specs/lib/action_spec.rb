require File.expand_path('../../common', __FILE__)

describe 'Action' do
  before do
    @storage = stub('Storage')
    @downloader = stub('Downloader', :storage => @storage)
    @gzipped_hello = "\u001F\x8B\b\u0000^\u007F\x90N\u0000\u0003\xF3H\xCD\xC9\xC9\a\u0000\x82\x89\xD1\xF7\u0005\u0000\u0000\u0000"
  end
  
  should 'accept valid constructor parameters' do
    action = GetThemAll::Action.new(@downloader, :destination_folder => '/tmp')
    action.destination_folder.should == '/tmp'
  end
  
  should 'raise an error on unknown constructor parameter' do
    proc{
      GetThemAll::Action.new(@downloader, :unknown => 42)
    }.should.raise(RuntimeError)
  end
  
  describe 'with an exsiting action' do
    before do
      @action = GetThemAll::Action.new(@downloader, :destination_folder => '/tmp')
    end
    
    # it "can decompress gzipped data" do
    #   str = @action.gunzip( @gzipped_hello )
    #   str.should == "Hello"
    # end
    
    # it "can read uncompressed request content" do
    #   request = stub('Request',
    #       :headers => {'content-encoding' => ['text/html']},
    #       :content => "Some data"
    #     )
    #   
    #   @action.get_content(request).should == "Some data"
    # end
    
    # it "can read compressed request content" do
    #   request = stub('Request',
    #       :headers => {'content-encoding' => ['gzip']},
    #       :content => @gzipped_hello
    #     )
    #   
    #   @action.get_content(request).should == "Hello"
    # end
    
  end
    
end
