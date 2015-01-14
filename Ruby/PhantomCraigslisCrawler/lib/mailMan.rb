
require "#{ROOT}/lib/log"
require 'gmail'

class MailMan

    attr_accessor :lstngSrch, :log

    def initialize
        begin
            @log = Log.new(STDOUT)
            @gmail = Gmail.new('dooodily@gmail.com', 'mattnificent')
            @log.info(1, "Gmail Initialized"){}
            @lstngSrch = ListingSearch.new self
            @log.info(1, "MailMan Initialized"){}
        rescue Exception => e
            @log.fatal(0, 'Exception caught while initializing MailMan'){}
            @log.fatal(0, e.message){}
            @log.fatal(0, e.backtrace.inspect){}
        end
    end


    def handleAllCommands
        begin
            User.find_each do |usr| 
                @log.dbug(2, 'Handling Commands for ' + usr.firstName + ' ' + usr.lastName){}
                handleUserCommands(usr) 
            end
        rescue Exception => e
            @log.error(1, 'Exception caught inside of', :__method__){}
            @log.error(1, e.message){}
            @log.error(1, e.backtrace.inspect){}
        end
    end

    def handleUserCommands(usr)
        begin
            emails = @gmail.inbox.emails(:unread, :from => usr[:email])
            @log.dbug(3, emails.count.to_s + ' emails from ' + usr.firstName){}
            emails.each_with_index do |email, index|
                if(email!=nil)
                    email_body_split = email.body.to_s.downcase.split
                    @log.dbug(4, "", :index, :email_body_split){}
                    if(email_body_split.index('-----original') == nil)
                        @log.warn(5, '"-----original" is missing from', :email_body_split){}
                        cmnd = email_body_split[0..-1]
                    else
                        cmnd = email_body_split[0..(email_body_split.index('-----original') - 1)]
                    end
                    @log.info(4, "Command Received from " + usr.firstName, :cmnd){}
                    handleSingleUserCommand(usr, cmnd)
                end
            end
        rescue Exception => e
            begin
                @gmail = Gmail.new('dooodily@gmail.com', 'mattnificent')
            rescue Exception => e                    
                @log.error(4, 'Error restarting gmail', :__method__){}
                @log.error(4, e.message){}
                @log.error(4, e.backtrace.inspect){}
            end
            
            @log.error(3, 'Exception caught inside of', :__method__){}
            @log.error(3, e.message){}
            @log.error(3, e.backtrace.inspect){}
        end
    end

    def simulateEmail(usr, str)
        begin
            email_body_split = str.downcase.split
            if(email_body_split.index('-----original') == nil)
                @log.warn(2, '"-----original" is missing from', :email_body_split){}
                cmnd = email_body_split[0..-1]
            else
                cmnd = email_body_split[0..(email_body_split.index('-----original') - 1)]
            end
            @log.info(2, "Command Received from " + usr.firstName, :cmnd){}
            handleSingleUserCommand(usr, cmnd)
        rescue Exception => e
            @log.error(2, 'Exception caught inside of', :__method__){}
            @log.error(2, e.message){}
            @log.error(2, e.backtrace.inspect){}
        end
    end


    def handleSingleUserCommand(usr, command)
        begin
            case command[0]
            when 'a'
                addKeywords(usr, command[1..-1])        # Examples:
            when 'f'
                addFreeKeywords(usr, command[1..-1])        # Examples:
            when 'n'
                viewNextThree(usr, command[1..-1])
            when 'e'
                viewEntirePost(usr, command[1..-1])
            when 'i'
                viewImages(usr, command[1..-1])
            when 'r'
                sendResponse(usr, command[1..-1])
            when 's'
                viewAllMySearches(usr, command[1..-1])
            when 'l'
                viewAllMyListings(usr, command[1..-1])
            when 'p'
                purgeSearches(usr, command[1..-1])
            else
                invalidCommand(usr)
            end
        rescue Exception => e
            @log.error(4, 'Exception caught inside of', :__method__){}
            @log.error(4, e.message){}
            @log.error(4, e.backtrace.inspect){}
        end
    end


    def addKeywords(usr, command)
        begin            
            @log.dbug(5, "Creating New Search for " + usr.firstName + ' with', :command){}

            newSearch = Search.new

            newSearch.userIDs = '|' + usr.id.to_s + '|'

            var = checkForPrice(command)
            newSearch.minPrice = var[0]
            newSearch.maxPrice = var[1]
            newSearch.keywords = var[2].join('+')

            newSearch.categoryURL = 'sss'

            doesSearchExist?(usr, newSearch)

        rescue Exception => e
            @log.error(5, 'Exception caught inside of', :__method__){}
            @log.error(5, e.message){}
            @log.error(5, e.backtrace.inspect){}
        end
    end

    def checkForPrice(command)
        begin
            if (command[0].to_f != 0)
                minPrice = command[0]

                if (command[1].to_f != 0)
                    maxPrice = command[1]
                    keywords = command[2..-1]
                else
                    maxPrice = nil
                    keywords = command[1..-1]
                end
            else
                minPrice = nil
                maxPrice = nil
                keywords = command[0..-1]
            end
        rescue Exception => e
            @log.error(6, 'Exception caught inside of', :__method__){}
            @log.error(6, e.message){}
            @log.error(6, e.backtrace.inspect){}
            return [ '', '', '']
        end

        return [ minPrice, maxPrice, keywords]
    end

    def doesSearchExist?(usr, srch)
        begin
            existingSearch = Search.where(  :minPrice   => srch.minPrice, 
                                            :maxPrice   => srch.maxPrice,
                                            :keywords   => srch.keywords,
                                            :categoryURL=> srch.categoryURL
                                            )

            if(existingSearch.empty?)
                @log.dbug(6, 'New unique search: ' + [srch.userIDs, srch.minPrice.to_s, srch.maxPrice, srch.keywords, srch.categoryURL].join(', ') ){}
                
                srch.save
                
                @lstngSrch.initialListingSearch(srch, usr)

            else
                existingSelfSearch = existingSearch.where("userIDs LIKE '%" + srch.userIDs + "%'")
                if(existingSelfSearch.empty?)
                    @log.warn(6, 'Adding new userIDs to an existing search: ' + [srch.userIDs, srch.minPrice.to_s, srch.maxPrice, srch.keywords, srch.categoryURL].join(', ') ){}
                    
                    existingSearch.first.userIDs += srch.userIDs.gsub("|", '') + '|'

                    @lstngSrch.initialListingSearch(existingSearch.first, usr)

                else
                    bod  = 'The search ' + 
                            srch.minPrice.to_s + ', ' +  
                            srch.maxPrice.to_s + ', ' + 
                            srch.keywords.to_s + 
                            ' already exists.'

                    @log.warn(6, 'Sending Existing Search notice to ' + usr.firstName, :bod ){}

                    bod += ' Send "n ' + 
                            existingSearch.first.id.to_s +
                            '" to view 3 moar results!'

                    sendEmail(usr.email, bod)

                end

                return existingSearch.first
            end
        rescue Exception => e
            @log.error(6, 'Exception caught inside of', :__method__){}
            @log.error(6, e.message){}
            @log.error(6, e.backtrace.inspect){}
            return nil
        end
    end

    def addFreeKeywords(usr, command)
        begin
            
            @log.dbug(5, "New Free listing Search for " + usr.firstName + ' with', :command){}

            newSearch = Search.new

            newSearch.userIDs = '|' + usr.id.to_s + '|'

            newSearch.keywords = command.join('+')

            newSearch.categoryURL = 'zip'

            doesSearchExist?(usr, newSearch)

        rescue Exception => e
            @log.error(5, 'Exception caught inside of', :__method__){}
            @log.error(5, e.message){}
            @log.error(5, e.backtrace.inspect){}
            return nil
        end
    end
    

    def viewNextThree(usr, command)
        begin
            srch = findSearch(usr, command, __method__.to_s)

            if(srch.class == String)
                @log.warn(6, srch, :usr){}
                sendEmail(User.find(usr.id).email, srch + ". No action taken.")
            else
                if (srch.categoryURL.include? "zip")
                    @log.dbug(6, "Sending next three free searches for keywords: " + srch.keywords.to_s){}
                    @lstngSrch.initialFreeSearch(srch, usr)
                else
                    @log.dbug(6, "Sending next three searches for keywords: " + srch.keywords.to_s){}
                    @lstngSrch.initialListingSearch(srch, usr)
                end 
            end
        rescue Exception => e
            @log.error(5, 'Exception caught inside of', :__method__){}
            @log.error(5, e.message){}
            @log.error(5, e.backtrace.inspect){}
            return nil
        end
    end

    def viewEntirePost(usr, command)
       begin
            lstng = findListing(usr, command, __method__.to_s)

            if(lstng.class == String)
                @log.warn(6, lstng, :usr){}
                sendEmail(User.find(usr.id).email,  lstng + ". No action taken.")
            else
                @log.dbug(6, "Sending listing body of: " + lstng.title.to_s, :usr){}
                body = @lstngSrch.getListingBody(lstng, usr)
                sendEmail(User.find(usr.id).email, 'L#' + lstng.id.to_s + '-' + body)
            end
        rescue Exception => e
            @log.error(5, 'Exception caught inside of', :__method__){}
            @log.error(5, e.message){}
            @log.error(5, e.backtrace.inspect){}
            return nil
        end
    end

    # Return listing if command is correct, a String otherwise
    def findListing(usr, command, methodName)
        begin
            if (command.count != 1)
                return 'To run ' + methodName + ', you must indicate the listing number.'
            elsif (command[0].to_i == 0)
                return "In " + methodName + ": couldn't make a number out of " + command[0].to_s
            elsif (Listing.find(command[0]) == nil)
                if(command[0] < Listing.maximum("id"))
                    return "In " + methodName + ": L#" + command[0].to_s + " has been removed."
                else
                    return "In " + methodName + ": There has never been a Listing with ID: " + command[0].to_s
                end
            else
                if(Listing.find(command[0]).userIDs.split('|').reject {|s| s.empty?}.member? usr.id.to_s)
                    @log.info(6, "Found listing id belonging to user", :usr, :command, :methodName){}
                    return Listing.find(command[0])
                else
                    return "In " + methodName + ": L#" + command[0] + " does not belong to you, " + usr.firstName
                end
            end
        rescue Exception => e
            @log.error(6, 'Exception caught inside of', :__method__){}
            @log.error(6, e.message){}
            @log.error(6, e.backtrace.inspect){}
            return nil
        end
    end

    # Return search if command is correct, nil otherwise
    def findSearch(usr, command, methodName)
        begin
            if (command.count == 0)
                if(methodName == 'purgeSearches')
                    return 0
                else
                    return methodName + ' requires you to indicate a search number. Send "S" to view all of your searches.'
                end
            elsif (command.count != 1)
                return 'To run ' + methodName + ', you must indicate only the search number.'
            elsif (command[0].to_i == 0)
                return "In " + methodName + ": couldn't make a number out of " + command[0].to_s
            elsif (Search.find(command[0]) == nil)
                if(command[0] < Search.maximum("id"))
                    return "In " + methodName + ": S#" + command[0].to_s + " has been removed."
                else
                    return "In " + methodName + ": There has never been a Search with ID: " + command[0].to_s
                end
            else
                if(Search.find(command[0]).userIDs.split('|').reject {|s| s.empty?}.member? usr.id.to_s)
                    @log.info(6, "Found search id belonging to user", :usr, :command, :methodName){}
                    return Search.find(command[0])
                else
                    return "In " + methodName + ": S#" + command[0] + " does not belong to you, " + usr.firstName
                end
            end
        rescue Exception => e
            @log.error(6, 'Exception caught inside of', :__method__){}
            @log.error(6, e.message){}
            @log.error(6, e.backtrace.inspect){}
            return nil
        end
    end

    def viewImages(command)
        begin


        rescue Exception => e
            @log.error(6, 'Exception caught inside of', :__method__){}
            @log.error(6, e.message){}
            @log.error(6, e.backtrace.inspect){}
            return nil
        end
    end

    def sendResponse(usr, command)
       begin
            lstng = findListing(usr, command[0..0], __method__.to_s)
            # Make sure the command was good
            if(lstng.class == String)
                @log.warn(6, lstng, :usr){}
                sendEmail(User.find(usr.id).email, lstng + ". No action taken.")
                return
            end

            # Get the seller's email
            sellerEmail = @lstngSrch.extractSellerEmail(lstng, usr)
            if (sellerEmail == false)
                @log.dbug(6, "No seller email address for " + lstng.title.to_s + '. Sending listing body instead.', :usr){}
                body = @lstngSrch.viewPost(lstng, usr)
                sendEmail(User.find(usr.id).email, 'L#' + lstng.id.to_s + '-' + body)
                return
            end

            if (command.count > 1) # Custom Response
                bod =   command[1..-1].join(" ")
            else # Default Response
                bod =   "Hello,\n" + 
                        "My name is " + usr.firstName.to_s + ". I am interested in the " + lstng.title.to_s + " you posted on Craigslist;\n" + 
                        "Send an email to my phone:\n" + 
                        usr.email + 
                        "\nor just call the number right before the @ symbol." +
                        "\n\nThanks!!!\n"
            end

            sendEmail(sellerEmail, lstng.title.to_s, bod)

        rescue Exception => e
            @log.error(6, 'Exception caught inside of', :__method__){}
            @log.error(6, e.message){}
            @log.error(6, e.backtrace.inspect){}
            return nil
        end
    end

    def viewAllMySearches(usr, command)
        begin
            msg = ''
            Search.where("userIDs LIKE '%|" + usr.id.to_s + "|%'").each do |srch|
                msg += "\nS#" + srch.id.to_s + ':' + [srch.minPrice.to_s, srch.maxPrice.to_s, srch.keywords.to_s].join(', ')
            end

            sendEmail(User.find(usr.id).email, msg)

        rescue Exception => e
            @log.error(6, 'Exception caught inside of', :__method__){}
            @log.error(6, e.message){}
            @log.error(6, e.backtrace.inspect){}
            return nil
        end
    end

    def viewAllMyListings(usr, command)
        begin
            msg = ''
            Listing.where("userIDs LIKE '%|" + usr.id.to_s + "|%'").each do |lstng|
                msg += "\nL#" + lstng.id.to_s + ':' + [lstng.title, lstng.price, lstng.location].join(', ')
            end

            sendEmail(User.find(usr.id).email, msg)

        rescue Exception => e
            @log.error(6, 'Exception caught inside of', :__method__){}
            @log.error(6, e.message){}
            @log.error(6, e.backtrace.inspect){}
            return nil
        end
    end

    def purgeSearches(usr, command)
        begin
            srch = findSearch(usr, command, __method__.to_s)

            if(srch.class == String)
                @log.warn(6, srch, :usr){}
                sendEmail(User.find(usr.id).email, srch + ". No action taken.")
            else
                if (srch == 0)
                    purgeAllSearchesForUser(usr)
                else
                    purgeSingleSearcheForUser(usr, srch)
                end 
            end
            sendEmail(User.find(usr.id).email, msg)
        rescue Exception => e
            @log.error(6, 'Exception caught inside of', :__method__){}
            @log.error(6, e.message){}
            @log.error(6, e.backtrace.inspect){}
            return nil
        end
    end
    

    def purgeAllSearchesForUser(usr)
        begin
            @log.dbug(7, "Purging All Searches for " + usr.firstName){}
            Search.where("userIDs LIKE '%|" + usr.id.to_s + "|%'").each do |srch|
                purgeSingleSearcheForUser(usr, srch)
            end
        rescue Exception => e
            @log.error(7, 'Exception caught inside of', :__method__){}
            @log.error(7, e.message){}
            @log.error(7, e.backtrace.inspect){}
            return nil
        end
    end

    def purgeSingleSearcheForUser(usr, srch)
        begin
            a = srch.userIDs.split('|').reject {|s| s.empty?}
            a.delete(usr.id.to_s)

            if(a.empty?)
                @log.dbug(8, "Deleting S#" + srch.id.to_s + " for " + usr.firstName){}
                srch.destroy
            else
                @log.dbug(8, "Removing " + usr.firstName + " from S#" + srch.id.to_s){}
                srch.userIDs = '|' + a.join('|') + '|'
            end
        rescue Exception => e
            @log.error(8, 'Exception caught inside of', :__method__){}
            @log.error(8, e.message){}
            @log.error(8, e.backtrace.inspect){}
            return nil
        end
    end



    def invalidCommand(command)
        begin


        rescue Exception => e
            @log.error(6, 'Exception caught inside of', :__method__){}
            @log.error(6, e.message){}
            @log.error(6, e.backtrace.inspect){}
            return nil
        end
    end

    def sendListings(usr, srch, listingNumberList, resultCount)
        begin
            
            msg = "S#" + srch.id.to_s + ":" + resultCount.to_s
            listingNumberList.each do |listingNum|
                lstng = Listing.find(listingNum)
                msg += "\nL#" + listingNum.to_s + '-' + lstng.title + ', ' + lstng.price + ', ' + lstng.location
            end
            
            sendEmail(usr.email,  msg)

        rescue Exception => e
            @log.error(6, 'Exception caught inside of', :__method__){}
            @log.error(6, e.message){}
            @log.error(6, e.backtrace.inspect){}
            return nil
        end
    end

    def sendEmail(emailAddress, subj = nil, bod)
        begin
            @log.info(8, 'Sending Email', :emailAddress, :bod){}
            @gmail.deliver do
                to emailAddress
                subject subj
                text_part do
                    body bod
                end
            end
        rescue Exception => e
            @log.error(8, 'Exception caught inside of', :__method__){}
            @log.error(8, e.message){}
            @log.error(8, e.backtrace.inspect){}
            return nil
        end
    end
end

