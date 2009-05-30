class Hash
  def check_args!(*list)
    list = list.map{|s| s.to_sym }
    
    # check that all required fields are defined
    missing_required_keys = []
    list.each do |key|
      missing_required_keys << key unless self.has_key?(key)
    end
    
    # and war on unknown key
    unknown_keys = []
    self.keys.select{|k| !list.include?(k) }.each do |key|
      unknown_keys << key
    end
    
    if missing_required_keys.size > 0
      fail "missing required key(s): #{missing_required_keys.join(', ')}"
    end
    
    if unknown_keys.size > 0
      puts "unknown key(s): #{unknown_keys.join(', ')}"
    end

  end
end