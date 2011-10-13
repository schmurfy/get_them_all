require File.expand_path('../common', __FILE__)

describe 'History' do
  before do
    @history = GetThemAll::History.new
  end
  
  should 'return empty string when dumped' do
    @history.dump.should == ""
  end
  
  should 'not include url1' do
    @history.should.not.include?('url1')
  end
  
  it 'can be loaded' do
    @history.load("url1\nurl2")
    @history.should.include?('url1')
  end
end
