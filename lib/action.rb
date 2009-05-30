class Action
  attr_accessor :url, :level, :destination_folder, :params
  
  def initialize(h)
    self.level= 0
    self.destination_folder= nil
    
    h.each do |key, val|
      if !val.nil? && respond_to?("#{key}=")
        send("#{key}=", val)
      end
    end
  end
end

class ExamineAction < Action

end

class DownloadAction < Action
  attr_accessor :parent_url
  
end