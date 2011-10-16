require File.expand_path('../../common', __FILE__)

describe 'JavascriptLoader' do
  before do
    @source = File.read(File.expand_path('../../data/specimen.js', __FILE__))
  end
  
  should 'load real javascript script' do
    @source.gsub!("var data", "data")
    loader = GetThemAll::JavascriptLoader.new(@source)
    loader.eval('data.meta.dir').should == 'manga/a/angelyardchapter2_e/'
  end
  
end
