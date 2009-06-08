
class TreeNode
  attr_reader :text, :children
  
  def initialize(prefix, text)
    @prefix = prefix
    @text = text
    @children = []
  end
  
  def add_child(prefix, text)
    ret = TreeNode.new(prefix, text)
    @children << ret
    ret
  end
  
  def find_node(text)
    if @text == text
      self
    elsif !@children.empty?
      @children.map{|node| node.find_node(text) }.compact.first
    else
      nil
    end
  end
  
  def inspect
    "{#{@text}}"
  end
  
  def dump_to_file(path)
    File.open(path, 'w') do |f|
      f.write( dump_node(0) )
    end
  end
  
  def dump_node(level)
    ret = "#{level-1} #{'  ' * level}#{@prefix} #{@text}\n"
    @children.each do |node|
      ret << node.dump_node(level + 1)
    end
    ret
  end
  protected :dump_node

end

