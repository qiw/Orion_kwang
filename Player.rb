# Copyright (c) 2011, 2012, Oracle and/or its affiliates. All rights reserved. 

#==============================================================================
# Class: Player
# Implementation of a individual *Orion* player
#
# Class <Player> implements a single player for the *Orion* genetic algorithm
# tournament. Each <Player> is capable of constructing sets of *SQL* probes.

class Player

  require 'OrionGrammar.rb'
  require 'Report.rb'
  require 'fileutils'
  include Report


  #============================================================================
  #
  # Variables
  #
  #============================================================================

  #============================================================================
  # Variable: @@idCntr
  # Serial counter for <Players>.
  #
  # Class variable <@@idCntr> maintains the serial identification counter for
  # the <Players> as they are created.

  @@idCntr = 1

  #============================================================================
  # Variable: @score
  # The score from an execution run.
  #
  # Variable <@score> is the score from an execution run.

  attr_accessor :score

  #============================================================================
  # Variable: @id
  # A unique serial identifier.
  #
  # Each <Player> gets a unique serial identifier when created. Variable <@id>
  # holds that value.

  attr_accessor :id

  #============================================================================
  # Variable: @grammar
  # The <Grammar> to be used for generation.
  #
  # Variable <@grammar> contains the <Grammar> to be used by the <Player> for
  # generation.

  attr_reader :grammar

  #============================================================================
  # Variable: @startSym
  # The starting <GramSym> for generation.
  #
  # Variable <@startSym> contains the starting symbol for grammar probe set
  # generation.

  #============================================================================
  # Variable: @probeSetName
  # File name for *SQL* probes.
  #
  # Variable <@probeSetName> is the name of the *SQL* probe set file generated
  # by this <Player>.

  attr_reader :probeSetName

  #============================================================================
  # Variable: @resultsName
  # File name for the execution result set.
  #
  # Variable <@resultsName> is the name of the results set name used for the
  # execution of the probe set.

  attr_reader :resultsName

  #============================================================================
  # Variable: @results
  # A record of the <Player's> results.
  #
  # Variable <@results> is a *Hash* that contains pairs of a result dimension
  # and a corresponding value. The <Scorer> knows how to interpret these.
  
  attr_accessor :results


  #============================================================================
  # Variable: @specialCodeFound
  # TRUE if the <Player> found a special result.
  #
  # Variable <@specialCodeFound> is TRUE if the <Player> had a special code
  # occur during execution.
  
  attr_accessor :specialCodeFound


  #============================================================================
  #
  # Class Methods
  #
  #============================================================================

  #============================================================================
  #
  # Instance Methods
  #
  #============================================================================

  #============================================================================
  # Method: initialize
  # Initialize a <Player>
  #
  # Method <initialize> is the *Ruby* way to ensure that a new <Player> is
  # correctly set up.
  #
  # Value:
  #   A correctly initialized <Player> instance.
  
  def initialize

    @grammar          = OrionGrammar.new
    @startSym         = GramSym.new(configuration.value(:startsym))
    @id               = @@idCntr
    @@idCntr          = @@idCntr + 1
    @score            = 0
    @results          = Hash.new(0)
    @specialCodeFound = FALSE

    errorExit('Initial weights not consistent.') unless @grammar.consistent?

  end
  

  #============================================================================
  # Method: readWeights
  # Reads new <Grammar> weights if available.
  #
  # Method <readWeights> fetches a set of initial weights from the 
  # configuration. There may be none there.
  #
  # Formal Parameters:
  #   self - the receiver of this method.
  #
  # Value:
  #   The mutated <Player> with the new weights
  #
  # Effects:
  #   The <Grammar> weights of the receiver may be modified

  def readWeights

    # If the configuration contains an initial weights vector, get it.

    theWeights = configuration.value(:weightsIn)
    setWeights(theWeights) if theWeights.length > 0
    errorExit('Input weights are not consistent.') unless self.consistent?

    return self

  end


  #============================================================================
  # Method: probeSet
  # Create a new probe set of *SQL* statements.
  #
  # Method <probeSet> creates a new set of *SQL* statements (a probe set) from
  # its grammar. The set is written to a file. The <Player> retains the file
  # name.
  #
  # Formal Parameters:
  #   self     - a <Player> who is to generate a probe set.
  #   probeCnt - the number of probes to generate.
  #   round    - the tournament round.
  #
  # Effects:
  #   A file is created in the work directory and filled with probes. The file
  #   name is retained by the <Player>. In addition, a results set name is
  #   created and remembered.

  def probeSet(probeCnt, round)

    # Create a file name and open the file. If the file cannot be opened,
    # be explicit about the problem.

    fileBase = configuration.value(:playerFormat) % [ round, @id ]
    nameBase = '%s/%s' % [ configuration.value(:filebase), fileBase ]
    @probeSetName = nameBase + '.prb'
    @resultsName  = nameBase + '.res'
    @weightsName  = nameBase + '.wgt'

    begin
      theFile = File.open(@probeSetName, 'w')
    rescue => excp
      errorExit("Player #{@id} cannot open probe file #{@probeSetName}", excp)
    end

    # Now generate as many probes as were requested and write each to the 
    # the file. Check the success result and record it in the results hash.

    prodCounts = Hash.new(0)

    mySeed = 9999999999999999999999*round*configuration.value(:seed).to_i + @id
    1.upto(probeCnt) do |i|
      theGen = @grammar.generate(@startSym, rand(mySeed) + 1, TRUE)
      theFile.puts(theGen[:text])
      mergeResults(@results, theGen[:prodCounts])
    end

    theFile.close

    # Write the weights that were used.

    if configuration.value(:saveFiles)
      begin
        theFile = File.open(@weightsName, 'w')
        theFile.puts writeWeights
        theFile.close
      rescue => excp
        errorExit("Player %d no weights file %s" % [ @id, @weightsName ], excp)
      end
    end

    tracing(3) { "Player #{@id} wrote probe file #{@probeSetName}" }

  end


  #============================================================================
  # Method: weights
  # Recover the weights from the <Grammar>.
  #
  # Method <weights> projects the weights from the underlying <Grammar> so that
  # an outsider can give them back later.
  #
  # Formal Parameters:
  #   self - the <Player> who is the recipient of the request.
  #
  # Value:
  #   An *Array* of weights (integers).
  #
  # Notes:
  #   - The weights follow the rule that they are always strictly greater than
  #     zero.
  #   - If the weights were given back unchanged, the underlying <Grammar>
  #     would be unchanged.

  def weights
    @grammar.to_weights
  end


  #============================================================================
  # Method: setWeights
  # Set the weights in the underlying <Grammar>.
  #
  # Method <setWeights> sets the weights in the underlying <Grammar> to the
  # *Array* of weights provided.
  #
  # Formal Parameters:
  #   self    - the <Player> receiver whose weights will be set.
  #   weights - the new weights in an *Array*.
  #
  # Effects:
  #   The weights in the underlying <Grammar> are set.
  #
  # See Also:
  #   - <weights>

  def setWeights(weights)
    @grammar.setWeights(weights)
  end


  #============================================================================
  # Method: consistent?
  # *TRUE* if the underlying <Grammar> is consistent.
  #
  # Predicate <consistent> is *TRUE* if and only if the <Player's> underlying
  # <Grammar> is consistent.
  #
  # Formal Parameters:
  #   self - the receiver <Player> whose consistency is questioned.
  #
  # Value:
  #   *TRUE* if and only if the underlying <Grammar> is consistent.
 
  def consistent?
    @grammar.consistent?
  end
  

  #============================================================================
  # Method: analyzeProbe
  # Analyze generation for one *Orion* probe.
  #
  # Method <analyzeProbe> write the generation history of one *Orion* probe
  # onto standard output. The configuration specifies the <Grammar> weights and
  # the start symbol; the random seed used originally is also necessary. If
  # no weights are supplied, the default weights are used.
  
  def analyzeProbe
    
    # Get the weights for the grammar and the other parameters and then 
    # generate the sentence with analysis turned on.

    readWeights
    startSym  = GramSym.new(configuration.value(:startsym))
    theSeed   = configuration.value(:seed).to_i
    theResult = @grammar.generate(startSym, theSeed, FALSE, TRUE, TRUE)

    # Now the tedious process of making a user readable 

    puts "The original seed = #{theSeed.to_s}"
    puts "The start symbol  = #{startSym.name}"
    puts theResult[:text]
    puts theResult[:analysis]

  end
  

  #============================================================================
  # Method: probeGen
  # Generate a set of *Orion* probes.
  #
  # Method <probeGen> supports the *GenProbeSet* *GeneticBug* command line
  # program. It writes a series of probes into one file and the set of 
  # <Grammar> weights used when generating the probes into another file. It
  # takes all of its direction from the configuration.
  #
  # Implicit Parameters:
  #   gFileName - the name of the file to which the probes are to be written.
  #   probeCnt  - the number of probes to generate.
  #   startSym  - the text of the starting <GramSym> name.
  #
  # Effects:
  #   - The probe set file is filled with random probes generated.
  #   - The weights file is filled with the <Grammar> weights used.

  def probeGen

    # Set up the values needed for all the generation.

    probeCnt = configuration.value(:probecnt).to_i
    startSym = GramSym.new(configuration.value(:startsym))

    # Adjust the weights if there is an input weights file. Then write them
    # if that is desired.

    readWeights

    begin
      if configuration.value?(:weightsOutName)
        woutName = configuration.value(:weightsOutName)
        woutFile = File.open(woutName, 'w')
        woutFile.puts writeWeights
        woutFile.close
      end     
      rescue => excp
        errorExit("Player cannot create weights file #{woutName}", excp)
    end

    # Make sure the probe file is available.

    gFileName = configuration.value(:probegenfile)
    begin
      gFile = File.open(gFileName, 'w')
    rescue => excp
      errorExit("Probe generation cannot open file #{gFileName}", excp)
    end

    # Write the generated probes file.

    mySeed = configuration.value(:seed).to_i
    srand mySeed
    1.upto(probeCnt) do |i|
      theRand = rand(9999999999999999999999999999999999999999999)
      gFile.puts @grammar.generate(startSym, theRand)[:text]
    end
    gFile.close

  end


  #============================================================================
  # Method: compareWeights 
  # Compare the <Grammar> weights of two <Players>.
  #
  # Method <compareWeights> creates a report on the weights of two <Players>
  # or, more precisely, on the weights of their <Grammars>. The report is
  # returned as a <TextRect> ready for human presentation.
  #
  # Formal Parameters:
  #   self - the receiver <Player>, the first of the comparands.
  #   other - the other <Player>
  #
  # Value:
  #   A <TextRect> suitable for human consumptions that presents the weight
  #   differences between the <Grammars> for the two players.

  def compareWeights(other)

    myWeights    = weights
    otherWeights = other.weights
    myTR         = TextRect.new
    otherTR      = TextRect.new

    myWeights.each_index do |i|
      myTR.below!('%5d' % myWeights[i])
      otherTR.below!('%5d' % otherWeights[i])
    end;

    myTR.join!(otherTR, ' ', ' ')
    myTR.number!
    myTR.columnate!(80)
    
    return myTR.box!('Grammar weight comparison.')
    
  end


  #============================================================================
  # Method: writeWeights
  # Write <Player> weights into an evaluable *String*.
  #
  # Method <writeWeights> writes a <Player's> weights (actually, the <Grammar>
  # weights) to into an "eval()"-uable *String* that can be used later to 
  # recreate the wrights.
  #
  # Formal Parameters:
  #   self - the receiver <Player> which is to write the weights.
  #
  # Value:
  #   A *String* with the <Player's> weights written neatly.

  def writeWeights
    @grammar.humanWeights
  end


  #============================================================================
  # Method: readResults
  # Read results from my results file
  #
  # Method <readResults> reads a score report file for the <Player> and
  # returns a *Set* of all the result dimensions for this player.
  #
  # Formal Parameters:
  #   self - the <Player> which is the receiver.
  #
  # Value:
  #   A *Set* of all the dimensions for this <Player>.
  #
  # Effects:
  #   - The <Player's> score file is opened, read, and closed.
  #   - The <Player's> results are updated.
  #
  # Notes:
  #   - This method builds a *String* from each result file internally and then
  #     eval()-uates that *String* to make a *Hash*. If the result files get
  #     too big, it may be better to add the members of the *Hash* one by one
  #     as they are read.

  def readResults

    # Read the file. Each line looks like 'symbol => value'. Evauate the line
    # into the Hash

    theFile = File.new(@resultsName, 'r')
    hashString = ''
    theFile.each do |l|
      l.chomp!.gsub!(/([\{\}])/, '*')
      l.rstrip!
      hashString << l << ",\n"
    end
    theHash = eval('{ ' + hashString + ' }')
    theFile.close

    # We are now going to replace the raw Hash with one that has the ORA-codes
    # with short names. There are simply too many ORA codes that have distinct
    # but useless error messages to keep track of. Also, spreading the weight
    # of ORA-codes around may hurt training.

    hash2 = Hash.new(0)
    theHash.each do |k, v| 
      oldKey = k.to_s
      begin hash2[k] = theHash[k]; next end unless oldKey.match('ORA-')
      newKey = oldKey[0, 9].to_sym
      hash2[newKey] += theHash[k]
    end

    # The player may already have some results. Add these results to the 
    # existing one.

    mergeResults(@results, hash2)

    # Look for any special Ora codes in the results. If the routine comes back
    # with a non-empty array, a report needs to be written. We don't mind 
    # reopening the file for every one of these because this is a very rare
    # event.

    badKeys = findSpecials(@results)
    badKeys.each do |k|
      bf = File.new(configuration.value(:badORACodesName), 'a')
      bf.puts 'Player file ' + @resultsName + ': Bad ORA code = ' + k.to_s
      bf.close
      FileUtils.cp(@probeSetName, @probeSetName + '.bad')
      @specialCodeFound = TRUE
    end

    # Create the set of all keys in the player's results. That set is the 
    # return value.

    Set.new(@results.keys)

  end

end # Player
