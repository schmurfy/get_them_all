$:.push File.expand_path("../lib", __FILE__)
require "get_them_all/version"

Gem::Specification.new do |s|
  s.name        = "get_them_all"
  s.version     = GetThemAll::VERSION
  s.authors     = ["Julien Ammous"]
  s.email       = []
  s.homepage    = ""
  s.summary     = %q{Mass downloader}
  s.description = %q{Mass downloader useable as standalone or as a library}

  s.rubyforge_project = "get_them_all"

  s.files         = `git ls-files lib/* *.gemspec README.* LICENSE`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_runtime_dependency 'thor'
  s.add_runtime_dependency 'em-http-request',    '~> 1.0.0'
  s.add_runtime_dependency 'em-priority-queue',  '~> 0.0.2'
  s.add_runtime_dependency 'hpricot',            '~> 0.8.1'
  s.add_runtime_dependency 'i18n'
  s.add_runtime_dependency 'activesupport',      '~> 3.1.0'
  s.add_runtime_dependency 'therubyracer',       '~> 0.9.8'
  s.add_runtime_dependency 'dropbox'
  s.add_runtime_dependency 'girl_friday'
end
