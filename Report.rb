# Copyright (c) 2010, 2011, Oracle and/or its affiliates. All rights reserved. 

#==============================================================================
# Module: Report
# Reporting services for *Orion*.
#
# Module <Report> provides reporting services for the *Orion* project.

module Report

  require 'Utility.rb'
  include Utility


  #============================================================================
  #
  # Variables
  #
  #============================================================================

  #============================================================================
  # Variable: @startTime
  # The time when <Utility> first executed.
  #
  # Variable <@startTime> is used throughout <Utility> to compute elapsed time
  # for reports.
  #
  # Notes:
  #   - To work correctly, <@startTime> must be an instance variable (HACK:
  #     why?) and must initialized in the body of the module, not in the 
  #     <setup> method.

  @startTime = @startTime.nil? ? Time.new : @startTime

  #============================================================================
  # Variable: @@configuration
  # The *Orion* active <Configurator>.
  #
  # Variable <@@configuration> contains the active <Configurator> for this
  # execution of *Orion*. The configuration is available not just to <Report>
  # but also to any class that includes it through the method <configuration>.

  #============================================================================
  # Variable: @@traceLevel
  # The current tracing level.
  #
  # Variable <@@traceLevel> records, for convenience, the current trace level.
  # It is used in several methods and this saves pulling it from the 
  # <Configurator> each time.

  #============================================================================
  # Variable: @@console
  # A *File* for console writes.
  #
  # Variable <@@console> is a *File* that is the proper target for normal
  # user oriented writes. It is specifically one target for the <console>
  # method.

  #============================================================================
  # Variable: @@consoleLog
  # A *File* for the console log.
  #
  # Variable <@@consoleLog> is a *File* that is the proper target for writes to
  # logging console file. It is specifically one target for the <console>
  # menhod.

  #============================================================================
  # Variable: @@traceLog
  # A *File* for the trace log.
  #
  # Variable <@@traceLog> is a *File* that is the target for trace writes. It
  # only exists if <@@traceLevel> is high enough to warrant tracing.


  #============================================================================
  #
  # Instance methods
  #
  # These methods will be available as instance methods to any class that
  # includes <Report>.
  #
  #============================================================================

  #============================================================================
  # Method: configuration
  # Return the *Orion* <Configurator> object.
  #
  # Method <configuration> returns the *Orion* <Configurator> object that 
  # directs all operations. This is an instance method and is available to any
  # class that includes <Utility>.
  #
  # Value:
  #   The <Configurator> that manages all objects.
  #
  # Notes:
  #   - Method <configuration> looks like an ordinary variable in any class
  #     that includes <Utility>. Thus, each class does *not* have to be 
  #     initialized with the <Configurator>.

  def configuration
    @@configuration
  end


  #============================================================================
  # Method: tracing
  # Generate tracing output.
  #
  # Method <tracing> writes messages to the trace and console logs if and only
  # if the tracing level supplied here is no higher than the overall tracing
  # level. For example, if the overall level is 2, a specific trace at the
  # level of 3 will not appear. If the overall trace level is zero, no traces
  # will appear. The overall trace level appears in the <Configurator>. Traces
  # are written to the trace log interspersed with normal output.
  #
  # Formal Parameters:
  #   level    - a strictly positive integer. This is requested trace level.
  #              The trace will appear if and only if
  #                 0 < level <= <@@traceLevel>.
  #   caption  - an optional *String* used as a caption for the trace report
  #              box.
  #   reporter - a _block_ which provides a value to put in the trace. The 
  #              value must be something acceptable to *puts* (such as a 
  #              *String* or a <TextRect>).
  #
  # Effects:
  #   If the level is appropriate, a message is written to the trace log.
  #
  # Notes:
  #   - Notice that the _block_ is used as if it were a parameterless function.
  #     If it does not return a value, who knows what will happen?
  #   - Method <tracing> is an instance method in any class that includes
  #     <Utility>.

  def tracing(level, caption = nil, &reporter)
    return if (level <= 0) or (level > @@traceLevel)
    theReport = Report.buildReport(caption, yield)
    @@traceLog.puts theReport
    @@traceLog.flush
  end


  #============================================================================
  # Method: console
  # Write to the user console.
  #
  # Method <console> writes text to the console, the device the human user is
  # expected to read. Normally, the console is standard output so that the
  # user will see this text scroll by the screen. The text is also written to
  # the console log and to the trace log if tracing is turned on.
  #
  # Formal Parameters:
  #   caption  - an optional *String* used as a caption for the console report
  #              box.
  #   reporter - a _block_ which provides a value to put on the console. The 
  #              value must be something acceptable to *puts* (such as a 
  #              *String* or a <TextRect>).
  #
  # Effects:
  #   - The text is formatted into a nice block and written to the console, to
  #     the console log, and to the trace log if appropriate.
  #   - Method <console> is an instance method in any class which includes
  #     <Report>.

  def console(caption = nil, &reporter)
    theReport = Report.buildReport(caption, yield)
    @@console.puts    theReport
    @@consoleLog.puts theReport
    @@traceLog.puts   theReport unless @@traceLog.nil?
    @@traceLog.flush
  end


  #============================================================================
  # Method: errorExit
  # Report an *Orion* error and exit.
  #
  # Method <errorExit> has the same description as the <Report> class method
  # <reportError>.
  #
  # Notes:
  #   - Method <console> is an instance method in any class which includes
  #     <Report>.

  def errorExit(theMessage = nil, theExcp = nil)
    Report.reportError(theMessage, theExcp)
  end


  #============================================================================
  #
  # Module methods
  #
  #============================================================================

  #============================================================================
  # Method: setup
  # Setup the <Report> and *Orion* for use.
  #
  # Method <setup> makes sure the <Report> module is ready to operate before
  # anything else happens.
  #
  # Formal Parameters:
  #   theConfig - a <Configurator> that provides context for everybody.
  #
  # Value:
  #   The <Configurator> created that was passed in.
  #
  # Effects:
  #   - The <Configurator> is made available to all classes through the 
  #     method <configuration>.
  #   - The files used for communication and tracing are opened.

  def Report.setup(theConfig)

    # Begin by remembering the configuration.

    @@configuration = theConfig

    # Find the trace level.

    @@traceLevel = @@configuration.value(:tracelevel).to_i

    # Setup the recording files that are going to be used throughout. There
    # are several:
    #
    #   The main console: everything that goes to the human user.
    #   The main console log: a log of what the user saw.
    #   The trace log: the console log and traces intermixed.

    @@console    = STDOUT    
    @@consoleLog = File.open(@@configuration.value(:consoleLogName), 'w')

    if @@traceLevel > 0 then
      @@traceLog = File.open(@@configuration.value(:traceLogName), 'w')
    else
      @@traceLog = nil
    end

    # Return the configuration.

    return @@configuration

  end


  #============================================================================
  # Method: buildReport
  # Build a report.
  #
  # Method <buildReport> constructs a standardized *Orion* report. The inputs
  # are a caption line and a body of text lines; the output is a <TextRect>
  # that is the completed report.
  #
  # Formal Parameters:
  #   caption - a single *String* that will appear as the caption of the 
  #             the report. This may be explicitly *NIL* if no caption is
  #             desired.
  #   body    - text lines for the body of the report. This may be a single
  #             *String*, an *Array* of *String*s, or a <TextRect>.
  # Value:
  #   A captioned <TextRect> that is in the standarized *Orion* report format.

  def Report.buildReport(caption, body)
    time   = Time.now
    diff   = time - @startTime
    bodyTR = TextRect.new("#{time.asctime}; Elapsed: #{diff.to_i}")
    bodyTR.below!(body);
    bodyTR.box(caption).below!(' ')
  end


  #============================================================================
  # Method: reportError
  # Report an error and stop.
  #
  # Method <reportError> reports a problem to standard error and then
  # terminates the program. The error can arise from either or both of a user
  # problem or a system exception. If either source is *NIL*, that source
  # is ignored. An attractive report is written to standard error and the
  # program is terminated.
  #
  # Formal Parameters:
  #   theMessage - a *String* provided by the caller that describes the cause.
  #                If this is *NIL*, it is simply ignored.
  #   theExcp    - an *Exception* (presumbably caught by something) and passed 
  #                here. The message from the exception will be used as part
  #                of the error report and its stack backtrace to locate the
  #                problem. If this is *NIL*, the possibility of an exception
  #                is simply ignored.
  #
  # Effects:
  #   An error summary is written on standard errof. The error is located
  #   either from the exception argument or from the caller. Messages from the
  #   arguments are in the report. Once the report has been written, the
  #   program is terminated.
  #
  # Notes:
  #   - The method <errorExit> has the same effect as <report>. The difference
  #     is that <reportError> can be called from a module and <errorExit>
  #     looks like an instance method of any class that includes <Report>.
  #   - In effect, <errorExit> is a wrapper for <reportError>.
  #
  # See Also:
  #   - <errorExit>

  def Report.reportError(theMessage=nil, theExcp=nil)

    theBody = TextRect.new
    theBody.below!("User msg = |#{theMessage}|")      unless theMessage.nil?
    theBody.below!("Excp msg = |#{theExcp.message}|") unless theExcp.nil?
    theBody.below!(TextRect.new(theExcp.nil? ? caller : theExcp.backtrace))
    theReport = buildReport('!!! FATAL error: Quitting now.', theBody)

    @@console.puts    theReport
    @@consoleLog.puts theReport
    @@traceLog.puts   theReport unless @@traceLog.nil?

    exit # No return from an error exit.

  end 

end
