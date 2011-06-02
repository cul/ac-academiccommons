require 'logger'

class StdOutLogger < Logger
  
  attr_reader :logger
  
  def initialize(file, stdout)
    super(file, shift_age = 0, shift_size = 1048576)
    @stdout = stdout || raise(ArgumentError, "You must include stdout in the arguments for StdOutLogger instance")
  end

  def add(severity, message = nil, progname = nil, &block)
    severity ||= UNKNOWN
    progname ||= @progname
    if message.nil?
      if block_given?
        message = yield
      else
        message = progname
        progname = @progname
      end
    end
    @stdout.puts format_message(format_severity(severity), Time.now, progname, message)
    super(severity, message, progname, &block)
  end
  
end 
