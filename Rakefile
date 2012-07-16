require "bundler/gem_tasks"

require "dropbox-api/tasks"
Dropbox::API::Tasks.install


task :default => :test

task :test do
  # system "COVERAGE=1 bundle exec bacon specs/**/*_spec.rb specs/**/**/*_spec.rb"
  require 'bacon'
  ENV['COVERAGE'] = "1"
  Dir[File.expand_path('../specs/**/*_spec.rb', __FILE__)].each do |file|
    load(file)
  end

end

