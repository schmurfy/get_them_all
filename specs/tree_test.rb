require File.expand_path('../common', __FILE__)

describe 'Tree' do
  before do
    @tree = GetThemAll::GraphBuilder::TreeNode.new("", "root")
    @child1 = @tree.add_child("-", "child1")
    @child2 = @tree.add_child("-", "child2")
    @child3 = @child2.add_child("-", "child3")
    @child4 = @child3.add_child("-", "child4")
  end
  
  should 'find leaves' do
    @child4.find_node("toto").should == nil
    @child2.find_node("child2").should == @child2
    
    @child2.find_node("child3").should == @child3
    @child2.find_node("child4").should == @child4
  end
  
  should 'find deeply nested leaves' do
    @tree.find_node("child4").should == @child4
  end
  
  should 'dump result' do
    expected = "-1  root\n0   - child1\n0   - child2\n1     - child3\n2       - child4\n"
    @tree.send(:dump_node, 0).should == expected
  end

end

