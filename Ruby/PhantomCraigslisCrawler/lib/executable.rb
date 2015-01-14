
require "#{ROOT}/lib/log"
require "#{ROOT}/lib/mailMan"
require "#{ROOT}/lib/listingSearch"


class Executable
    
    attr_accessor :log

    def initialize
        @log = Log.new(STDOUT)
        @log.info(0, "Executable Initialized"){}
    end

    def run
        Thread.new do
            begin
                mailman = MailMan.new
                listingSearch = ListingSearch.new mailman
                sleep 5
                while(true)
                    mailman.handleAllCommands()
                    @log.info(1, "Finised All Commands!"){}
                    sleep 7
                
                    listingSearch.handleAllSearches
                    @log.info(1, "Finised Searching for New Items!"){}
                    sleep 7

                end
            rescue Exception => e
                @log.fatal(1, 'Exception caught at top of thread.'){}
                @log.fatal(1, e.message){}
                @log.fatal(1, e.backtrace.inspect){}
                system("pause")
            end    
        end
    end
end

