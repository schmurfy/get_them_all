
guard 'bacon', :output => "BetterOutput", :backtrace => 4 do
  watch(%r{^lib/get_them_all/(.+)\.rb$})     { |m| "specs/#{m[1]}_spec.rb" }
  watch(%r{specs/.+\.rb$})
end
