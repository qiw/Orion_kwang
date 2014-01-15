# Copyright (c) 2011, 2012, Oracle and/or its affiliates. All rights reserved. 

#==============================================================================
# Class: Configurator
# The configuration manager for <Orion>.
#
# Class <Configurator> manages the configuration of the <Orion> tool. It reads
# the original configuration file and then provides that information to 
# other components.

class Configurator

  require_relative 'TextRect.rb'
  require_relative 'Utility.rb'
  require 'date'


  #============================================================================
  # Variable: @theName
  # The name of the configuration file.
  #
  # Variable <@theName> contains the text (that is, a *String*) of the name
  # of the file that contains the *Orion* configuration.

  #============================================================================
  # Variable: @thePairs
  # The configuration value pairs.
  #
  # Variable <@thePairs> is a *Hash* of the *Orion* configuration values. The
  # hash key is a *Symbol* giving the name of the value and the value itself
  # is a *String* (which, in almost all cases, represents an integer).
  

  #============================================================================
  # Method: initialize
  # Setup a new <Configurator>.
  #
  # Method <initialize> is *Ruby*'s mechanism for ensuring that a
  # <Configurator> is correctly initialized. The argument is the name of 
  # configuration file supplied by the calling environment. Initialization
  # will read and record the data from the file and take action on those
  # items which need global setup.
  #
  # Formal Parameters:
  #   theName - the text name of a configuration file supplied by the outside
  #             caller. The name must be sufficient to find, open, and read
  #             the file.
  #
  # Value:
  #   A new <Configurator> with the configuration information read and 
  #   analyzed. Basic configuration will always have initial values, regardless
  #   of whether they are explicitly specified in the configuration file.
  #
  # Notes:
  #   - A configuration key/value pair may appear more than once. The last one
  #     wins.

  def initialize(theName)

    # Set the absolutely necessary configuration values to their initial
    # values.

    today      = DateTime.now.to_date.to_s
    filePrefix = "#{today}_#{$$.to_s}_"
    consoleLog = filePrefix + 'ConsoleLog'
    traceLog   = filePrefix + 'TraceLog'
    weightsRpt = filePrefix + 'WeightsInRepeat'
    weightsOut = filePrefix + 'WeightsOut'
    badORAName = filePrefix + 'BadORACodes'
    allDims    = filePrefix + 'AllDimensions'
    oraOpsOut  = filePrefix + 'OraOpCodes'

    @thePairs = { 
                  :today         => today,
                  :uniqueID      => $$,
                  :filePrefix    => filePrefix,
                  :filebase      => '/tmp', 
                  :tracelevel    => 0, 
                  :seed          => '%d' % Time.new.to_i,
                  :consoleLog    => consoleLog,
                  :traceLog      => traceLog,
                  :weightsRpt    => weightsRpt,
                  :weightsOut    => weightsOut,
                  :badORAName    => badORAName,
                  :oraOpsOut     => oraOpsOut,
                  :allDims       => allDims,
                  :saveFiles     => false,
                  :scoreType     => :normalExemplarDimension,
                  :breedMutate   => :mutateNTAsGene,
                  :breedPassThru => :passThruRuleAsGene,
                  :breedMate     => :matchMakeNTAsGene,
                }

    # Remember the configuration file name. Get the Hash from the file and
    # evaluate it get the exterior configuration values. Then merge them
    # into the initial version.

    @theName = theName
    theFile = File.new(theName, 'r')
    outsideConfig = eval(theFile.read)
    theFile.close
    @thePairs.merge!(outsideConfig)

    # Now add all the interesting file names to the mix.

    fileBase = @thePairs[:filebase]
    @thePairs.merge!({ :consoleLogName  => "#{fileBase}/#{consoleLog}",
                       :traceLogName    => "#{fileBase}/#{traceLog}",
                       :weightsRptName  => "#{fileBase}/#{weightsRpt}",
                       :weightsOutName  => "#{fileBase}/#{weightsOut}",
                       :badORACodesName => "#{fileBase}/#{badORAName}",
                       :allDimsName     => "#{fileBase}/#{allDims}",
                       :oraOpsOutName   => "#{fileBase}/#{oraOpsOut}",
                     })

    # If there is a weights in file, read it into a hash in the configuration
    # and repeat it to the output.

    if @thePairs.has_key?(:weightsinfile)

      fileName    = @thePairs[:weightsinfile]
      weightsFile = File.new(fileName, 'r')
      theStr      = weightsFile.read
      weightsFile.close
      @thePairs[:weightsIn] = eval(theStr)

      repeatFile  = File.new(@thePairs[:weightsRptName], 'w')
      repeatFile.puts theStr
      repeatFile.close
      
    else
      @thePairs[:weightsIn] = Array.new
    end

    # Set up the formats for the probe file names if there are to be any.

    if @thePairs.has_key?(:rounds)
      r           = @thePairs[:rounds].to_i
      c           = @thePairs[:popcount].to_i
      roundsWidth = Utility.numWidth(r)
      countWidth  = Utility.numWidth(c*r)
      format = "#{@thePairs[:filePrefix]}%.#{roundsWidth}d_%.#{countWidth}d"
      @thePairs[:playerFormat] = format
    end

    # Provide an array of the "bad" Oracle SQL error codes.

    @thePairs[:specialCodes] = [ 'ORA-00600', 'ORA-00700', 
                                 'ORA-03113', 'ORA-07445',
                               ]

  end


  #============================================================================
  # Method: value
  # Project the value of an *Orion* configuration item.
  #
  # Method <value> projects the value of one *Orion* configuration item. The
  # input is a *Symbol* that names the item desired and the return value is a
  # *String* of the value of the item.
  #
  # Formal Parameters:
  #   name - a *Symbol* which names the configuration item desired.
  #
  # Value:
  #   A *String* that corresponds to the configuration item name.
  #
  # Errors:
  #   If there is no value for the requested name, an exception is raised.
  #
  # See Also:
  #   - <value?>

  def value(name)
    raise "No configuration for #{name}" unless @thePairs.has_key?(name)
    @thePairs[name]
  end


  #============================================================================
  # Method: value?
  # TRUE if there a value for an *Orion* configuration item.
  #
  # Predicate <value?> returns *TRUE* if and only if there is a value for a
  # particular *Orion* configuration item.
  #
  # Formal Parameters:
  #   name - a *Symbol* which names the configuration item desired.
  #
  # Value:
  #   *TRUE* if and only there is a configuation item for the *Symbol*.
  #
  # See Also:
  #   - <value>
  
  def value?(name)
    @thePairs.has_key?(name)
  end


  #============================================================================
  # Method: to_TR
  # Convert a <Configurator> to a <TextRect>.
  #
  # Method <to_s> converts a <Configurator> to a <TextRect> in a format that
  # makes it easy to understand the contents of the <Configurator>.
  #
  # Formal Parameters:
  #   self - the receiver <Configurator> that is to be converted.
  #
  # Value:
  #   A <TextRect> that represents the <Configurator>.

  def to_TR

    # We create TextRect for each of keys and values. The entries in the
    # <Configurator> are sorted before they are output.

    theSort = @thePairs.sort
    theSyms = TextRect.new
    theVals = TextRect.new

    # Now walk the elements of the sorted array and put each into its place.
    # Notice that the key is a Symbol and needs to be converted to a String.
    # We take the precaution of converting the value to a String as well
    # although the initial values are always Strings; this caters to the
    # possibility that the Configurator might someday accept configuration 
    # information from the running program. Also, if the string is very long,
    # we truncate it. That's because otherwise it will fold like made.

    theSort.each do |v|
      theSyms.below!(v[0].to_s);
      theVals.below!(v[1].to_s[0, 110]) 
    end
    
    return theSyms.join(theVals, ' ', ' => ')

  end

end # Configurator
