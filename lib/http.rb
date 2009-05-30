module Httpclient2Ext
  
  def self.included(base)
    base.class_eval do
      alias_method :old_send_request, :send_request
      alias_method :send_request, :new_send_request
    end
  end
  
  def encode_cookies(cookies)
    cookies.map{|key,val| "#{key}=#{val}" }.join("; ")
  end
  
  # overwrite original method to allow body for post requests
  # add two parameters:
  # - body (POST)
  # - cookies: Hash
  #
  def new_send_request

    r = []
    r << "#{@args[:verb]} #{@args[:uri]} HTTP/#{@args[:version] || "1.1"}\r\n"
    r << "Host: #{@args[:host_header] || "_"}\r\n"
    
    r << "User-Agent: Mozilla/5.0 (Windows; U; Windows NT 6.0; en-GB; rv:1.9.0.10) Gecko/2009042316 (.NET CLR 3.5.30729)\r\n"
    r << "Accept: image/png/,image/*;q=0.8,*/*;q=0.5\r\n"
    r << "Accept-Language: en-gb,en;q=0.5\r\n"
    r << "Accept-Encoding: identity\r\n"
    # r << "Keep-Alive: 300\r\n"
    # r << "Connection: keep-alive\r\n"
    
    r << "Referer: #{@args[:referer]}\r\n" if @args[:referer]
    r << "Cookie: #{encode_cookies(@args[:cookies])}\r\n" if @args[:cookies] && @args[:cookies].size > 0
    
    r << "Content-Length: #{@args[:body].size}\r\n" if @args[:body]
    
    r << "Cache-Control: max-age=0\r\n"
    
    r << "Authorization: #{az}\r\n" if @args[:authorization]
    r << "\r\n"
    r << "#{@args[:body]}" if @args[:body]

    @conn.send_data r.join
  end
  
  def received_cookies
    tmp = Array(headers["set-cookie"]).map{|str| str.split(";").first.strip } # key=val
    
    tmp.inject({}) do |buff, str|
      tmp = str.split("=")
      buff[tmp.first] = tmp[1]
      buff
    end
  end
  private :received_cookies
  
  def added_cookies
    received_cookies.reject{|key, val| val == "deleted" }
  end
  
  def deleted_cookies
    received_cookies.reject{|key, val| val != "deleted" }
  end
  
end

EM::Protocols::HttpClient2::Request.send(:include, Httpclient2Ext)