class GraphBuilder < Extension
  def initialize
    register_handler('downloader.started') do |name, downloader|
      @graph = TreeNode.new("", downloader.base_url)
    end
    
    register_handler('downloader.completed') do |name, downloader|
      @graph.dump_to_file('/tmp/tree.txt')
    end
    
    register_handler('action.download.success') do |name, action|
      add_to_graph("D", action.url, action.parent_url)
    end
    
    register_handler('action.examine.success') do |name, action, returned_actions|
      add_to_graph("E[ret:#{returned_actions.size}]", action.url, action.parent_url)
    end
    
    register_handler('action.examine.failure') do |name, action, error_status|
      add_to_graph(error_status, action.url, action.referer)
    end
    
  end
  
private

  def add_to_graph(prefix, url, referer)
    if referer.nil?
      @graph.add_child(prefix, url)
    else
      # find referer
      parent = @graph.find_node(referer) or fail("node not found: #{referer}")
      parent.add_child(prefix, url)
    end
  end
  
end
