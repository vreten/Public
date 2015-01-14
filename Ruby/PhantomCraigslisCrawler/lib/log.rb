

class Log

	attr_accessor :logger, :logLevelHolder
	
	def initialize(outputStream)

        # Turn this annoyance off
        ActiveRecord::Base.logger = nil

		@logLevelHolder = Logger::DEBUG

        @logger = Logger.new(outputStream)
        
        @logger.level = Logger::DEBUG
        
        @logger.debug("Logger Initialized")
    end

    def changeLogLevel(level)
    	@logLevelHolder = @logger.level
    	@logger.level = level
    end

    def changeLogLevelBack()
    	@logger.level = @logLevelHolder
    end


	def dbug(depth, message, *s, &b)
	    string = '  ' * depth + message + ": "
	    s.each do |item|
	        v = eval(item.to_s, b.binding)
	        string += "#{item}(#{v.class})=|#{v}|, "
	    end
	    @logger.debug(string)
	end

	def info(depth, message, *s, &b)
	    string = '  ' * depth + message + ": "
	    s.each do |item|
	        v = eval(item.to_s, b.binding)
	        string += "#{item}(#{v.class})=|#{v}|, ".gsub("\n", "\n\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t")
	    end
	    @logger.info(string)
	end

	def warn(depth, message, *s, &b)
	    string = '  ' * depth + message + ": "
	    s.each do |item|
	        v = eval(item.to_s, b.binding)
	        string += "#{item}(#{v.class})=|#{v}|, "
	    end
	    @logger.warn(string)
	end

	def error(depth, message, *s, &b)
	    string = '  ' * depth + message + ": "
	    s.each do |item|
	        v = eval(item.to_s, b.binding)
	        string += "#{item}(#{v.class})=|#{v}|, "
	    end
	    @logger.error(string)
	end

	def fatal(depth, message, *s, &b)
	    string = '  ' * depth + message + ": "
	    s.each do |item|
	        v = eval(item.to_s, b.binding)
	        string += "#{item}(#{v.class})=|#{v}|, "
	    end
	    @logger.fatal(string)
	end

end

