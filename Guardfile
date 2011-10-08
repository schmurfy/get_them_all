
guard 'bacon', :output => "BetterOutput", :backtrace => 4 do
  watch(%r{^lib/(.+)\.rb$})     { |m| "specs/lib/#{m[1]}_spec.rb" }
  watch(%r{specs/.+\.rb$})
end

