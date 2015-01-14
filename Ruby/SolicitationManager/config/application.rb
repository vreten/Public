require File.expand_path('../boot', __FILE__)
ROOT = "#{File.dirname(__FILE__)}/.." unless defined?(ROOT)

require 'rails/all'
require "#{ROOT}/lib/log"
require "#{ROOT}/lib/solicitationScraper"
require "#{ROOT}/lib/excel"
# require "#{ROOT}/lib/executable"


# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module SolicitationManager

    MAX_PAGES = 5

    VIPVBVSDVOSB = "VIP VetBiz Verified Service-Disabled Veteran-Owned Small Business"
    VIPVBVVOSB = "VIP VetBiz Verified Veteran-Owned Small Business"
    SDVOSB = "Service-Disabled Veteran-Owned Small Business"
    VOSB = "Veteran-Owned Small Business"
    SB = "Small Business"

    class Application < Rails::Application  
        attr_accessor :log
        begin
            @log = Log.new(STDOUT)



            # Executable.new.run
        rescue Exception => e
            @log.fatal(0, 'Exception caught at Application layer'){}
            @log.fatal(0, e.message){}
            @log.fatal(0, e.backtrace.inspect){}
            system("pause")
        end
    end
end

