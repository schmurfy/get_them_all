
module GetThemAll
  ##
  # This extension will generate a textfile showing
  # he hierarchy of the site which may be considered
  # as a map.
  # 
  # Its main purpose as a debugging tool to have a
  # better view of what was going on inside.
  # 
  # It was also capable of generating a dot file but this code
  # is not up to date.
  # 
  class GraphBuilder < Extension
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




      def dump_to_dot_file(path)
        File.open(path, 'w') do |f|
          f.write(<<-EOF)
    digraph toto {
      node [shape=box];
      #{dump_node_dot()}
    }      
          EOF
        end
      end

      def dump_node_dot(prefix = nil)
        # ret = "#{level-1} #{'  ' * level}#{@prefix} #{@text}\n"
        if prefix.nil?
          prefix = "\"#{@text}\""
        else
          prefix = " #{prefix} -> \"#{@text}\""
        end

        ret = [prefix]

        @children.each do |node|
          ret << node.dump_node("\"#{@text}\"")
        end

        ret.join("\n")
      end
      protected :dump_node_dot

    end




    ##
    # @param [String] path where the resulting file will be written.
    # 
    def initialize(path)
      @path = path
    
      register_handler('downloader.started') do |name, downloader|
        @graph = TreeNode.new("", downloader.base_url)
      end
    
      register_handler('downloader.completed') do |name, worker, downloader|
        @graph.dump_to_file(@path)
        # @graph.dump_to_dot_file(@path)
      end
    
      register_handler('action.download.success') do |name, worker, action|
        add_to_graph("D", action.url, action.parent_url)
      end
    
      register_handler('action.examine.success') do |name, worker, action, returned_actions|
        add_to_graph("E[ret:#{returned_actions.size}]", action.url, action.parent_url)
      end
    
      register_handler('action.examine.failure') do |name, worker, action, error_status|
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
end
