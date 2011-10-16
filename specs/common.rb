
require 'bundler/setup'

if (RUBY_VERSION >= "1.9") && ENV['COVERAGE']
  require 'simplecov'
  ROOT = File.expand_path('../../lib/get_them_all', __FILE__)
  
  puts "[[  SimpleCov enabled  ]]"
  
  SimpleCov.start do    
    add_filter '/specs'
    
    root(ROOT)
  end
end


$LOAD_PATH.unshift( File.expand_path('../../lib', __FILE__) )
require "get_them_all"

require 'bacon'
require 'mocha'
require 'factory_girl'
require 'em-spec/bacon'
EM.spec_backend = EventMachine::Spec::Bacon

Bacon.summary_on_exit()



# Mocha integration, move this in mocha gem
module Bacon
  module MochaRequirementsCounter
    def self.increment
      Counter[:requirements] += 1
    end
  end
  
  class Context
    include Mocha::API
    
    alias_method :it_before_mocha, :it
    
    def it(description)
      it_before_mocha(description) do
        begin
          mocha_setup
          yield
          mocha_verify(MochaRequirementsCounter)
        rescue Mocha::ExpectationError => e
          raise Error.new(:failed, "#{e.message}\n#{e.backtrace[0...10].join("\n")}")
        ensure
          mocha_teardown
        end
      end
    end
  end
end

