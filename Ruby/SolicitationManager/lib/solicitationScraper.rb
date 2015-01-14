require "#{ROOT}/lib/log"
require 'open-uri'
require 'nokogiri'
require 'mechanize'


class Constants
    # first element is inclusive, anything after is exclusive
    # There MUST be a first element, even if the first element is ""
    # if the first element is "", everything will include that
    @@filters = {
        :OPPORTUNITIES  => ["Opportunities"],
        :OPEN_MARKET    => ["Open Market"],
        :VIPVBVSDVOSB   => ["VIP VetBiz Verified Service-Disabled Veteran-Owned Small Business"],
        :VIPVBVVOSB     => ["VIP VetBiz Verified Veteran-Owned Small Business"],
        :SDVOSB         => ["Service-Disabled Veteran-Owned Small Business", "VIP VetBiz Verified"],
        :VOSB           => ["Veteran-Owned Small Business", "VIP VetBiz Verified", "Service-Disabled"],
        :SB             => ["Small Business", "VIP VetBiz Verified", "Service-Disabled", "Veteran-Owned"]
    }
    
    @@outputRoot = '/home/mattitude/Dropbox/Dodson Construction/Office Management/Estimates'

    cattr_reader :filters, :outputRoot
end


class SolicitationScraper

    attr_accessor :log, :agent, :URL, :page, :form

	def initialize()
		begin
			@log = Log.new(STDOUT)
		    @log.info(2,"SolicitationScraper Initialized"){}
	    rescue Exception => e
            @log.fatal(0, 'Exception caught while initializing SolicitationScraper'){}
            @log.fatal(0, e.message){}
            @log.fatal(0, e.backtrace.inspect){}
        end
	end

	def login()

		@agent = Mechanize.new

		@URL = 'https://marketplace.fedbid.com/login.do'

		@page = @agent.get(@URL)

		@form = @page.form

		@form.checkbox_with(:name => 'termsCheck').check
		@form.username = 'jld.dcitampa@gmail.com'
		@form.password = '34er#$ER'

		@form.submit
	end

	def updateAll()
        
        time = time.now

        linksContaining(Constants.filters[:OPPORTUNITIES])[0].click
        linksContaining(Constants.filters[:OPEN_MARKET])[0].click
        linksContaining(Constants.filters[:VIPVBVSDVOSB])[0].click
        goThroughSearchPages(3, "VIPVBVSDVOSB", true)

        linksContaining(Constants.filters[:OPPORTUNITIES])[0].click
        linksContaining(Constants.filters[:OPEN_MARKET])[0].click
        linksContaining(Constants.filters[:VIPVBVVOSB])[0].click
        goThroughSearchPages(3, "VIPVBVVOSB", true)

        linksContaining(Constants.filters[:OPPORTUNITIES])[0].click
        linksContaining(Constants.filters[:OPEN_MARKET])[0].click
        linksContaining(Constants.filters[:SDVOSB])[0].click
        goThroughSearchPages(3, "SDVOSB", true)

        linksContaining(Constants.filters[:OPPORTUNITIES])[0].click
        linksContaining(Constants.filters[:OPEN_MARKET])[0].click
        linksContaining(Constants.filters[:VOSB])[0].click
        goThroughSearchPages(3, "VOSB", true)

        linksContaining(Constants.filters[:OPPORTUNITIES])[0].click
        linksContaining(Constants.filters[:OPEN_MARKET])[0].click
        linksContaining(Constants.filters[:SB])[0].click
        goThroughSearchPages(3, "SB", true)


        findListingsThatAreGone()


	end

	def goThroughSearchPages(numPages, setAsideReq, weShouldViewDetailsPage)
		if thisIsFinalPage
			opportunitiesPageOperation(setAsideReq, weShouldViewDetailsPage)
		else
			(1..numPages).each do |i|
				viewPageWithListings(i, 100)
				opportunitiesPageOperation(setAsideReq, weShouldViewDetailsPage)
				if thisIsFinalPage 
					break
				end
			end
		end
	end

	def opportunitiesPageOperation(setAsideReq, weShouldViewDetailsPage)

        # Print the number of items on the page out of the total number of items
		@log.info(1, @agent.page.at(".toolbartext").text.scan(/\d+/).join(':').to_s, :setAsideReq){}

		# For each listing
		(1..100).each do |i|
            row = opportunitiesPageRow(i)
			if(row == nil)
				break
			end
            extractSingleListing(setAsideReq, weShouldViewDetailsPage, row, i)
		end

		# Check for non-updated items

	end


    def extractSingleListing(setAsideReq, weShouldViewDetailsPage, row, i)
        begin
            # Grab the buy number and revision number
            idArray = clean(columnOfRow(2, row))[0].split("_")
            # Try to find an existing solicitation with that buy number
            existingSolicitation = Solicitation.where(:buy_num => idArray[0])

            # If the listing does not exist, create it
            if (existingSolicitation.empty?)
                solicitation = createSolicitationEntry(i, idArray)
            # Else, if the rev number has changed, update it
            elsif (existingSolicitation.where(:rev => idArray[1]).empty?)
                solicitation = updateSolicitationEntry(existingSolicitation, i, idArray)
                # Delete any existing database entries associated to avoid duplicates
            # If the listing hasn't changed since last time. mark that we saw it
            elsif weShouldViewDetailsPage && existingSolicitation.first.solicitation_num.nil?
                solicitation = existingSolicitation.first
            else
                verifySolicitationEntry(existingSolicitation, i, idArray)
                return
            end
            
            solicitation.set_aside_req = setAsideReq

            extractDataFromResultsPage(solicitation, row)

            if weShouldViewDetailsPage
                extractDataFromDetailsPage(solicitation, idArray)
            end

            solicitation.save
        rescue
            @log.error(1, "Error extracting buy number " + idArray[0]) {}
        end
    end


    def createSolicitationEntry(index, idArray)
        @log.info(2, "Creating Sol. Entry", :index, :idArray) {}
        solicitation = Solicitation.new
        solicitation.buy_num = idArray[0]
        solicitation.rev = idArray[1]
        return solicitation
    end

    def updateSolicitationEntry(existingSolicitation, index, idArray)
        @log.info(2, "Updating Sol. Entry", :index, :idArray) {}
        solicitation = existingSolicitation.first
        solicitation.rev = idArray[1]
        solicitation.revised_at = Time.now.utc
        return solicitation
    end
    
    def verifySolicitationEntry(existingSolicitation, index, idArray)
        @log.info(2, "Entry Verified", :index, :idArray) {}
        existingSolicitation.first.touch
        existingSolicitation.first.save
    end

    def linksContaining(filters)
        linkArray = []
        @agent.page.links.each do |link|
            # 
            if (link.text.include?(filters[0]) && 
                !filters[1..-1].any?{ |filter| link.text.include? filter } )
                linkArray << link
            end
        end
        return linkArray
    end

	def thisIsFinalPage()
		numArray = @agent.page.at(".toolbartext").text.scan(/\d+/)
		return numArray[1] == numArray[2]
	end

	def viewPageWithListings(pageNum, numOfListings)
		baseURL = @agent.page.uri.to_s
		if baseURL.index('?') != nil
			@URL = baseURL.slice(0..(baseURL.index('?')))
		else
			@URL = baseURL + '?'
		end
		@URL += 'filterBy=-1&maxRows=' + numOfListings.to_s +  
				'&BidAction=-1&tableBuys_tr_=true&tableBuys_p_=' + 
				 pageNum.to_s + '&tableBuys_mr_=' + numOfListings.to_s

		@agent.get(@URL)
	end

	def extractDataFromResultsPage(solicitation, row)
        solicitation.title = clean(columnOfRow(3, row))[0]
        solicitation.buyer = clean(columnOfRow(4, row)).join('-')
		timeString = clean(columnOfRow(5, row)).join(" ")
		solicitation.end_time = timeString.slice(0..(timeString.index('ET') - 2))
        return solicitation
	end

    def extractDataFromDetailsPage(solicitation, idArray)
        # Click on the link to the details page
        linksContaining([idArray[0]])[0].click
        
        @log.changeLogLevel(Logger::INFO)

        extractGeneralBuyInfo(solicitation)
        
        extractLineItems(solicitation.buy_num)

        extractRequirements(solicitation.buy_num)

        extractTerms(solicitation.buy_num)

        solicitation.location = cleanDetailsRow(getRow(getTable("Shipping Information", 1), 1))
        
        @log.changeLogLevelBack

        # Go back to results page
        @agent.back
    end

    def extractGeneralBuyInfo(solicitation)
        begin
            table = getTable("General Buy Information", 1)
            (0..15).each do |i|
                row = getRow(table, i)
                if row == nil
                    break
                end
                case clean(row.at("th").text).join
                    when "Buy #:"
                        # Already captured. Verify?
                    when "Solicitation #:"
                        solicitation.solicitation_num = clean(row.at("td").text).join
                    when "Buy Description:"
                        # Already captured. Verify?
                    when "Category:"
                        solicitation.category = clean(row.at("td").text).join
                    when "Subcategory:"
                        solicitation.subcategory = clean(row.at("td").text).join
                    when "NAICS:"
                        solicitation.naics = clean(row.at("td").text).join
                    when "FBO Solicitation:"
                        solicitation.fbo_solicitation = clean(row.at("td").text).join
                    when "Recovery Act:"
                        solicitation.recovery_act = clean(row.at("td").text).join
                    when "Set-Aside Requirement:"
                        # Already captured. Verify?
                    when "Buyer:"
                        # Already captured. Verify?
                    when "End Date:"
                        # Already captured. Verify?
                    when "End Time:"
                        # Already captured. Verify?
                    when "Delivery:"
                        solicitation.delivery = clean(row.at("td").text).join
                    when "Bid Delivery Days:"
                        solicitation.bid_delivery_days = clean(row.at("td").text).join
                    when "Repost Reason:"
                        solicitation.repost_reason = clean(row.at("td").text).join
                    else
                        @log.info(3, "New General Buy Info Type found: " + clean(row.at("th").text).join) {}
                end
            end
        rescue
            @log.error(3, "Error processing general buy info.", :buyNum) {}
        end
    end

    def extractLineItems(buyNum)
        
        tableCount = getNumberOfItemTables

        table = getTable("Line Item(s)", 1)
        if table != nil
            processLineItemsTable(table, buyNum, nil, nil)
        else
            @log.error(4, "Line Items Table not found(1)", :buyNum) {}
        end
        
        optionArray = clean(table.text).collect{|x| x.strip}

        if (tableCount == 1 && !(optionArray[0].include? ("Base")))
            
        elsif tableCount == 0
            @log.error(4, "Line Items Table not found(2)", :buyNum) {}
        else

            (0..tableCount-1).each do |i|
                
                table = getTable("Line Item(s)",(2*i+1))
                optionArray = clean(table.text).collect{|x| x.strip}

                option = optionArray[0]

                periodOfPerformance = optionArray[2]

                table = getTable("Line Item(s)", (2*i +2))
                if table != nil
                    processLineItemsTable(table, buyNum, option, periodOfPerformance)
                else
                    @log.error(4, "Line Items Table not found(1)", :buyNum) {}
                end
            end

        end
    end

    def processLineItemsTable(table, buyNum, option, periodOfPerformance)
        begin
            headerArray = clean(getRow(table, 0).text).collect{|x| x.strip}

            (1..100).each do |i|
                row = getRow(table, i)
                if row == nil
                    break
                end

                item = Item.new

                item.buy_num = buyNum

                detailsArray = []
                getRow(table, i).search("td").each do |detail|
                    detailsArray << detail.text.strip
                end

                (0..headerArray.count - 1).each do |j|
                    case headerArray[j]
                        when "Item No."
                            item.item_num = detailsArray[j]
                        when "Description"
                            item.description = detailsArray[j]
                        when "Qty"
                            item.qty = detailsArray[j]
                        when "Unit"
                            item.unit = detailsArray[j]
                        else
                            @log.info(3, "New Items Table Column found: " + headerArray[j]) {}
                    end
                end

                item.option = option
                item.period_of_performance = periodOfPerformance


                if Item.where("buy_num like ? and description like ?", buyNum, item.description).empty?
                    item.save
                    @log.dbug(4, "Item saved: " + item.description, :buyNum) {}
                else
                    @log.dbug(4, "Item already existed: " + item.description, :buyNum) {}
                end
            end 
        rescue
            @log.error(3, "Error processing line items.", :buyNum) {}
        end   
    end



    def extractTerms(buyNum)
        
        begin
            @log.dbug(3, "Extracting Terms", :buyNum) {}

            table = getTable("Buy Terms", 1)
            
            headerArray = clean(getRow(table, 0).text).collect{|x| x.strip}

            (1..100).each do |i|
                row = getRow(table, i)
                if row == nil
                    break
                end

                @log.dbug(4, "Term", :i, :buyNum) {}

                term = Term.new

                term.buy_num = buyNum

                detailsArray = []
                getRow(table, i).search("td").each do |detail|
                    detailsArray << detail.text.strip
                end

                (0..headerArray.count - 1).each do |j|
                    case headerArray[j]
                        when "Name"
                            @log.dbug(4, "Name: " + detailsArray[j]) {}
                            term.title = detailsArray[j]
                        when "Description"
                            @log.dbug(4, "Description: " + detailsArray[j]) {}
                            term.specification = detailsArray[j]
                        else
                            @log.info(5, "New Term Table Column found: " + headerArray[j]) {}
                    end
                end

                if Term.where("buy_num like ? and title like ?", buyNum, term.title).empty?
                    term.save
                    @log.dbug(5, "Term saved: " + term.title, :buyNum) {}
                else
                    @log.dbug(5, "Term already existed: " + term.title, :buyNum) {}
                end
            end  
        rescue
            @log.error(3, "Error processing terms.", :buyNum) {}
        end  
        
    end


    def extractRequirements(buyNum)
        
        begin
            @log.dbug(4, "Extracting Terms", :buyNum) {}
            table = getTable("Bidding Requirements", 1)

            rowCount = table.search(".biLabel").count

            (1..rowCount).each do |reqIndex|
                row = getRow(table, reqIndex)
                if row.nil?
                    break
                end

                requirement = Requirement.new
                requirement.buy_num = buyNum
                requirement.title = row.search("div")[0].text
                requirement.specification = row.search("div")[1].text

                if Requirement.where("buy_num like ? and title like ?", buyNum, requirement.title).empty?
                    requirement.save
                    @log.dbug(4, "Requirement saved: " + requirement.title, :buyNum) {}
                else
                    @log.dbug(4, "Requirement already existed: " + requirement.title, :buyNum) {}
                end
            end
        rescue
            @log.error(3, "Error processing requirements.", :buyNum) {}
        end 

    end


     #  Details Page Parsers
    ###########################################
    def getNumberOfItemTables
        return @agent.page.search("//*[contains(text(),'Line Item(s)')]").count
    end

    def getTable(title, offset)
        parseString = "//*[contains(text(),'#{title}')]" + "/following-sibling::table"*offset
        return @agent.page.at(parseString)
    end

    def getRow(table, rowNumber)
        return table.search('tr')[rowNumber]
    end

    def cleanDetailsRow(messyText)
        return messyText.text.split.collect{|x| x.strip}.reject {|s| s.blank?}.join(' ')
    end


    # => Results Page Parsers
    ###########################################
    def opportunitiesPageRow(rowNumber)
        return @agent.page.at("#tableBuys_row#{rowNumber}")
    end

    def columnOfRow(columnNumber, row)
        return row.at("td:nth-child(#{columnNumber})").text
    end

    def clean(messyText)
        return messyText.strip.split(/[\t\r\n]/).reject {|s| s.blank?}
    end


end





