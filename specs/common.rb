
require 'bundler/setup'

require File.expand_path('../../lib/init', __FILE__)

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

