
require 'axlsx'

class Excel

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


def exportAllToExcel()

    solicitations = Solicitation.where("buy_num like ?", "%")

    solicitations.each do |solicitation|
      createDocument( solicitation.buy_num, 
                      solicitation.title,
                      solicitation.set_aside_req, 
                      solicitation.location)
    end

end


  def createDocument(buyNum, title, setAsideReq, location)

    @log.info(2,"Creating document", :buyNum){}

    directory = Constants.outputRoot
    filename = [setAsideReq.to_s, 
                location.to_s, 
                title.to_s, 
                buyNum.to_s].join(":") + '.xlsx'

    filename = filename.gsub('/', ', ')

    filename = filename[0, 20] + "..." + filename[-10,10]

    p = Axlsx::Package.new
    wb = p.workbook

    addGeneralWorksheet(buyNum, wb)

    addItemsWorksheet(buyNum, wb)

    addRequirementsWorkSheet(buyNum, wb)

    addTermsWorksheet(buyNum, wb)

    goToDirectory(directory)
    p.serialize(filename)
    returnToHomeDirectory()
  end


  def addGeneralWorksheet(buyNum, wb)
    
    solicitation = Solicitation.where(:buy_num => buyNum)

    if (solicitation.empty?)
        @log.warn(2,"No solicitation exists", :buyNum){}
        return
    elsif (solicitation.count != 1)
        @log.warn(2,"Duplicate solicitations exist", :buyNum){}
        return
    end
    
    solicitation = solicitation.first

    wb.add_worksheet(:name => "General") do |sheet|
      sheet.add_row ['Buy Number',  buyNum.to_s]
      sheet.add_row ['Revision',  solicitation.rev.to_s]
      sheet.add_row ['Title',  solicitation.title.to_s]
      sheet.add_row ['Buyer',  solicitation.buyer.to_s]
      sheet.add_row ['End Time',  solicitation.end_time.to_s]
      sheet.add_row ['Set Aside Requirement',  solicitation.set_aside_req.to_s]
      sheet.add_row ['Location',  solicitation.location.to_s]
      sheet.add_row ['Category',  solicitation.category.to_s]
      sheet.add_row ['Subcategory',  solicitation.subcategory.to_s]
      sheet.add_row ['NAICS',  solicitation.naics.to_s]
      sheet.add_row ['FBO Solicitation',  solicitation.fbo_solicitation.to_s]
      sheet.add_row ['Recovery Act',  solicitation.recovery_act.to_s]
      sheet.add_row ['Delivery',  solicitation.delivery.to_s]
      sheet.add_row ['Bid Delivery Days',  solicitation.bid_delivery_days.to_s]
      sheet.add_row ['Repost Reason',  solicitation.repost_reason.to_s]
      sheet.add_row ['Solicitation Number',  solicitation.solicitation_num.to_s]
      sheet.add_row ['Revised At',  solicitation.revised_at.to_s]
      sheet.add_row ['Removed At',  solicitation.removed_at.to_s]
      sheet.add_row ['Created At',  solicitation.created_at.to_s]
      sheet.add_row ['Last Observed At',  solicitation.updated_at.to_s]
    end
  end

  
  def addItemsWorksheet(buyNum, wb)
    
    items = Item.where(:buy_num => buyNum)

    if (items.empty?)
        @log.warn(2,"No Items exist", :buyNum){}
        return
    end
    
    wb.add_worksheet(:name => "Items") do |sheet|

      sheet.add_row [ 'Item Number', 
                      'Description', 
                      'Quantity', 
                      'Unit', 
                      "Option", 
                      'Period Of Performance']

      items.each do |item|
        sheet.add_row [ item.item_num, 
                        item.description, 
                        item.qty, 
                        item.unit, 
                        item.option, 
                        item.period_of_performance]
      end

    end
  end


  def addRequirementsWorkSheet(buyNum, wb)
    
    requirements = Requirement.where(:buy_num => buyNum)

    if (requirements.empty?)
        @log.warn(2,"No Requirements exist", :buyNum){}
        return
    end
    
    wb.add_worksheet(:name => "Requirements") do |sheet|

      sheet.add_row [ 'Title', 
                      'Specification']

      requirements.each do |requirement|
        sheet.add_row [ requirement.title, 
                        requirement.specification]
      end
      
    end
  end


  def addTermsWorksheet(buyNum, wb)
    
    terms = Term.where(:buy_num => buyNum)

    if (terms.empty?)
        @log.warn(2,"No Terms exist", :buyNum){}
        return
    end
    
    wb.add_worksheet(:name => "Terms") do |sheet|

      sheet.add_row [ 'Title', 
                      'Specification']

      terms.each do |term|
        sheet.add_row [ term.title, 
                        term.specification]
      end
      
    end
  end



  def addFilterTable(wb)

    wb.add_worksheet(:name => "Table") do |sheet|
      sheet.add_row ["Build Matrix"]
      sheet.add_row ["Build", "Duration", "Finished", "Rvm"]
      sheet.add_row ["19.1", "1 min 32 sec", "about 10 hours ago", "1.8.7"]
      sheet.add_row ["19.2", "1 min 28 sec", "about 10 hours ago", "1.9.2"]
      sheet.add_row ["19.3", "1 min 35 sec", "about 10 hours ago", "1.9.3"]
      sheet.add_table "A2:D5", :name => 'Build Matrix', :style_info => { :name => "TableStyleMedium23" }
    end
  end


  def goToDirectory(directory)
    if !(Dir.exist?(directory))
      Dir.mkdir(directory)
    end
    Dir.chdir(directory)
  end

  def returnToHomeDirectory()
    Dir.chdir('/home/mattitude/rails/SolicitationManager/')
  end

end

