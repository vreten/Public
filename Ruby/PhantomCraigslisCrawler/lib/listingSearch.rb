
require "#{ROOT}/lib/log"
require 'open-uri'
require 'nokogiri'

class ListingSearch

    attr_accessor :mlMan, :log

	def initialize(mmn)
		begin
			@log = Log.new(STDOUT)
			@mlMan = mmn
		    @log.info(2,"ListingSearch Initialized"){}
	    rescue Exception => e
            @log.fatal(0, 'Exception caught while initializing ListingSearch'){}
            @log.fatal(0, e.message){}
            @log.fatal(0, e.backtrace.inspect){}
        end
	end

	def initialListingSearch(srch, usr)
		begin
			url = getURL(srch)
			html = Nokogiri::HTML(open('http://' + url))

			resultCount = html.css('.row').count

			if(resultCount == 0)
				msg =   "No results found for " + 
                        srch.minPrice.to_s + ', ' + 
                        srch.maxPrice.to_s + ', ' + 
                        srch.keywords.to_s

                @log.warn(6,'Sending no results notice to ' + usr.firstName, :msg ){}

                @mlMan.sendEmail(usr.email,  msg)
                return
            end

			@log.info(6, resultCount.to_s + ' listings found for ' +  srch.keywords ){}

			@log.changeLogLevel(Logger::WARN)

			listings = []
			for currentWeekAgeLimit in 1..52
				break if (listings.count >= 3 || listings.count >= resultCount)

				@log.dbug(6, "", :currentWeekAgeLimit) {}
				html.css('.row').each do |row|
					
					title  = row.at_css('.pl').at_css('a').text.strip
					@log.dbug(7, "New Row", :title) {}
					
					dateString = row.at_css('.date').text.strip
					@log.dbug(7, "", :dateString) {}
					date = Date.parse(dateString)
					daysPast = (Date.today - date).to_i
					weeksPast = daysPast/7
					@log.dbug(7, "", :weeksPast) {}

					if (weeksPast < currentWeekAgeLimit)
						@log.dbug(8, "Found potential send candidate") {}
						listingNumber = updateListingTable(row, srch, usr)
						if(!listingNumber.nil?)
							@log.dbug(9, "Adding ", :listingNumber, :listings) {}
							listings << listingNumber
							break if (listings.count >= 3 || listings.count >= resultCount)
						end
					end
				end
			end

			@log.changeLogLevelBack()

			if(listings.count == 0)
				msg =   "No new listings found for " + 
                        srch.minPrice.to_s + ', ' + 
                        srch.maxPrice.to_s + ', ' + 
                        srch.keywords.to_s

                @log.warn(6,'Sending No new listings notice to ' + usr.firstName, :msg ){}

                @mlMan.sendEmail(usr.email,  msg)
            else
				@mlMan.sendListings(usr, srch, listings, resultCount)
				updateListingIDList(html, srch)
			end

				
		rescue Exception => e
            @log.error(5, 'Exception caught inside of', :__method__){}
            @log.error(5, e.message){}
            @log.error(5, e.backtrace.inspect){}
            return nil
        end
	end

	def initialFreeSearch(srch, usr)
		begin
			url = getURL(srch)
			html = Nokogiri::HTML(open('http://' + url))

			resultCount = html.css('.row').count

			if(resultCount == 0)
				msg =   "No results found for " + 
                        srch.minPrice.to_s + ', ' + 
                        srch.maxPrice.to_s + ', ' + 
                        srch.keywords.to_s

                @log.warn(6,'Sending no results notice to ' + usr.firstName, :msg ){}

                @mlMan.sendEmail(usr.email,  msg)
                return
            end

			@log.changeLogLevel(Logger::WARN)

			listings = []
			html.css('.row').each do |row|
				
				title  = row.at_css('.pl').at_css('a').text.strip
				@log.dbug(6, "Free search: New Row, and potential send candidate: ", :title) {}
					
				listingNumber = updateListingTable(row, srch)
				if(!listingNumber.nil?)
					@log.dbug(7, "Free search: Adding ", :listingNumber, :listings) {}
					listings << listingNumber
					break if (listings.count >= 3 || listings.count >= resultCount)
				end
			end

			@log.changeLogLevelBack()

			if(listings.count == 0)
				msg =   "No new listings found for " + 
                        srch.minPrice.to_s + ', ' + 
                        srch.maxPrice.to_s + ', ' + 
                        srch.keywords.to_s

                @log.warn(6,'Sending No new listings notice to ' + usr.firstName, :msg ){}

                @mlMan.sendEmail(usr.email,  msg)
            else
				@mlMan.sendListings(usr, srch, listings, resultCount)
				updateListingIDList(html, srch)
			end

		rescue Exception => e
            @log.error(5, 'Exception caught inside of', :__method__){}
            @log.error(5, e.message){}
            @log.error(5, e.backtrace.inspect){}
            return nil
        end
	end

	def handleAllSearches()
		begin
			Search.find_each do |srch| 
	            @log.dbug(3, "Searching for" + srch.keywords){}
	            handleSingleSearch(srch) 
	        end
        rescue Exception => e
            @log.error(3, 'Exception caught inside of', :__method__){}
            @log.error(3, e.message){}
            @log.error(3, e.backtrace.inspect){}
            return nil
        end
	end

	def handleSingleSearch(srch)
		begin
			url = getURL(srch)
			html = Nokogiri::HTML(open('http://' + url))

			resultCount = html.css('.row').count

			if(resultCount == 0)
                @log.warn(4,'No results found for ' + srch.keywords){}
                return
            end


			listings = []
			html.css('.row').each do |row|
				if(srch.listingIDs.include? row["data-pid"])
					break
				else
					@log.info(4, 'New item discovered @ ', :url){}
					listingNumber = updateListingTable(row, srch)
					listings << listingNumber
					break if (listings.count >= 3 || listings.count >= resultCount)
				end
			end
			
			if (listings.count != 0)
				# Send results to each user who has this search
				usersWhoHaveThisSearch = srch.userIDs.split('|').reject {|s| s.empty?}
				usersWhoHaveThisSearch.each do |usrID|

					@mlMan.sendListings(User.find(usrID), srch, listings, resultCount)
				end
			end

			updateListingIDList(html, srch)
		rescue Exception => e
            @log.error(4, 'Exception caught inside of', :__method__){}
            @log.error(4, e.message){}
            @log.error(4, e.backtrace.inspect){}
            return nil
        end
	end

	def updateListingTable(row, srch, usr = nil)
		begin
            if(Listing.where(:cListNumber => row["data-pid"]).empty?)
            	# If the listing doesn't already exist
				newListing = Listing.new
				newListing.cListNumber = row["data-pid"]
				newListing.title  = row.at_css('.pl').at_css('a').text.strip
				newListing.price = getPrice(row, srch)
				newListing.location = removeParenthases(row.at_css('.pnr').xpath('small/text()').text.strip)
				newListing.date = getDate(row, srch)
				newListing.descriptionURL = row.at_css('a')['href']
				# If this is a user specific search
            	if(!usr.nil?)
					newListing.userIDs = '|' + usr.id.to_s + '|'
				else
					newListing.userIDs = srch.userIDs
				end

				newListing.save
				@log.info(9,  'User ' + usr.id.to_s + ' generated a new listing: ' + [newListing.id.to_s, newListing.cListNumber, newListing.title, newListing.price, newListing.location, newListing.date].join(', ')){}
				return newListing.id
            else
            	# if the listing does already exist, get the listing
            	lstng = Listing.where(:cListNumber => row["data-pid"]).first
            	
            	# If this is a user specific search
            	if(!usr.nil?)

	            	# if the listing belonged to the same person doing the search
	            	if(lstng.userIDs.split('|').reject {|s| s.empty?}.member? usr.id.to_s)
	            		@log.dbug(9, 'User ' + usr.id.to_s + ' has already received the following listing: ' + [lstng.id.to_s, lstng.cListNumber, lstng.title, lstng.price, lstng.location, lstng.date].join(', ')){}
	            		return nil
	            	else # if the listing existed, but it belonged to someone else
						lstng.userIDs += usr.id.to_s + '|'
	            		lstng.save
	            		@log.info(9, 'User ' + usr.id.to_s + ' generated a listing which existed from a different user: ' + [lstng.id.to_s, lstng.cListNumber, lstng.title, lstng.price, lstng.location, lstng.date].join(', ')){}
	            		return lstng.id
	            	end

            	end

            end
		rescue Exception => e
            @log.error(9, 'Exception caught inside of', :__method__){}
            @log.error(9, e.message){}
            @log.error(9, e.backtrace.inspect){}
            return nil
        end
	end

	def removeParenthases(str)
		begin
			if(str[0] == '(' && str[-1] == ')')
				return str[1..-2] 
			end
			@log.warn(10, 'For some reason, there were no parenthases on', :str){}
			return str
		rescue Exception => e
            @log.error(10, 'Exception caught inside of', :__method__){}
            @log.error(10, e.message){}
            @log.error(10, e.backtrace.inspect){}
            return nil
        end
	end

	def getPrice(row, srch)
		begin
			if (srch.categoryURL.include? "zip")
				return "Free"
			else
				return row.at_css('.pp').text.strip
			end
		rescue Exception => e
            @log.error(10, 'Exception caught inside of', :__method__){}
            @log.error(10, e.message){}
            @log.error(10, e.backtrace.inspect){}
            return nil
        end
	end

	def getDate(row, srch)
		begin
			if (srch.categoryURL.include? "zip")
				@log.warn(10, 'Cannot get date on free listings yet'){}
				return ""
			else
				return row.at_css('.date').text.strip
			end
		rescue Exception => e
            @log.error(10, 'Exception caught inside of', :__method__){}
            @log.error(10, e.message){}
            @log.error(10, e.backtrace.inspect){}
            return nil
        end
	end


	def updateListingIDList(html, srch)
		begin
			newListingIDList = ''
			html.css('.row').each do |row|
				newListingIDList += row["data-pid"] + ','
			end
			srch.listingIDs = newListingIDList
			# Turn this annoyance off
        	ActiveRecord::Base.logger = nil
			srch.save
			
		rescue Exception => e
			@log.error(6, 'Unable to update ID list for srch = ' + srch.keywords){}
			@log.error(6, e.message){}
            @log.error(6, e.backtrace.inspect){}
		end
	end

	def getURL(srch)
		begin
			usersWhoHaveThisSearch = srch.userIDs.split('|').reject {|s| s.empty?}
			
			# Turn this annoyance off
        	ActiveRecord::Base.logger = nil
			usr = User.find(usersWhoHaveThisSearch.first)
			
			url = [usr.homeURL, 'search', srch.categoryURL, usr.subURL].join('/')+'?sort=priceasc&srchType=A&query=' + srch.keywords
			if(srch.minPrice != nil)
				url += '&minAsk=' + srch.minPrice
			end
			if(srch.maxPrice != nil) 
				url += '&maxAsk=' + srch.maxPrice
			end
			@log.info(6, 'URL for ' + usr.firstName, :url){}
			return url
		rescue Exception => e
            @log.fatal(0, 'Exception caught inside of', :__method__){}
            @log.fatal(0, e.message){}
            @log.fatal(0, e.backtrace.inspect){}
            return nil
        end
	end

	def getListingBody(lstng, usr)
		begin
			url = usr.homeURL + lstng.descriptionURL
			@log.info(6, 'Viewing Listing for ' + usr.firstName, :url){}

			html = Nokogiri::HTML(open('http://' + url))

			return html.at_css('.userbody').xpath('section[@id="postingbody"]/text()').text.strip

		rescue Exception => e
            @log.fatal(0, 'Exception caught inside of', :__method__){}
            @log.fatal(0, e.message){}
            @log.fatal(0, e.backtrace.inspect){}
            return nil
        end
	end


	def extractSellerEmail(lstng, usr)
		begin
			url = usr.homeURL + lstng.descriptionURL
			@log.info(7, 'Responding to listing for ' + usr.firstName, :url){}

			html = Nokogiri::HTML(open('http://' + url))

			email = html.at_css('.dateReplyBar').xpath('a/text()').text.strip

			if(email.empty?)
				return false
			else

			end
		rescue Exception => e
            @log.fatal(0, 'Exception caught inside of', :__method__){}
            @log.fatal(0, e.message){}
            @log.fatal(0, e.backtrace.inspect){}
            return nil
        end
	end

end


