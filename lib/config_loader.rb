require 'dead_simple_conf'

# logger:
#   level: info
#   output: stdout
# 
# storage:
#   location: filesystem
#   path: data
# 

module ConfigLoader
  
  class LoggerBlock < DeadSimpleConf::ConfigBlock
    attr_accessor :level, :output
  end
  
  class StorageBlock < DeadSimpleConf::ConfigBlock
    attr_accessor :location, :params
  end
  
  class MainBlock < DeadSimpleConf::ConfigBlock
    sub_section :logger, LoggerBlock
    sub_section :storage, StorageBlock  
  end
  
  def self.load(path)
    yaml_data = YAML.load_file(path)
    MainBlock.new(yaml_data)
  end
end


SiteDownloader.config = ConfigLoader.load(
    File.expand_path('../../config.yml', __FILE__)
  )
