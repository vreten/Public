require File.expand_path('../boot', __FILE__)
ROOT = "#{File.dirname(__FILE__)}/.." unless defined?(ROOT)

require 'rails/all'
require "#{ROOT}/lib/log"
require "#{ROOT}/lib/executable"


# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module MattsList
    class Application < Rails::Application  
        attr_accessor :log
        begin
            @log = Log.new(STDOUT)
            Executable.new.run
        rescue Exception => e
            @log.fatal(0, 'Exception caught at Application layer'){}
            @log.fatal(0, e.message){}
            @log.fatal(0, e.backtrace.inspect){}
            system("pause")
        end
    end
end


