# Copyright (c) 2011, 2012, Oracle and/or its affiliates. All rights reserved. 

#==============================================================================
# Class: Scorer
# Computes scores for *Orion* execution runs.
#
# Class <Scorer> takes the results of a round of execution and provides scores
# to all the <Players>. The scores, of course, are used as a fitness measure
# for the next generation.
#
# To keep track of both individual <Player> scores and of scores over entire
# populations, <Scorer> uses a data structure that is commonly called a
# _result_ through what follows. The structure is a *Hash*. The keys are the
# dimension names and the values are integers (at least so far) of a
# measurement over a dimension. The dimensions are always *Symbol*s. Thus, a
# result might look like
#
#  > {
#  >   :OraOp65 => 3,
#  >   :bytecount => 93,
#  >   :results   => 1,
#  >   :resultsetsize => 17,
#  >   :codeBlock917z => 1
#  > }
#
# Notes:
#   - The names of the dimensions are not known in advance. Therefore, any one
#     result may not have scores for all possible dimensions. Each result
#     *Hash* is initialized so that the default value for an unseen key is 
#     zero.
#   - Probably non-integer numeric values would work perfectly well. So far
#     there has been no need of them.

class Scorer

  require 'set'

  include Report
  include Utility

  #============================================================================
  #
  # Class and object attributes.
  #
  #============================================================================

  #----------------------------------------------------------------------------
  # Variable: @trace
  # The trace level from the <Configuration>.
  #
  # Variable <@trace> is just the trace level from the configuration cached
  # for quick access.

  #----------------------------------------------------------------------------
  # Variable: @exemplars
  # Example data points for scoring.
  #
  # *Array* <@exemplarResults> contains results for exemplar data points.
  # Each data point generates one result in the array.

  #----------------------------------------------------------------------------
  # Variable: @exemplarDims
  # Dimensions for example data points.
  #
  # *Set* <@exemplarDims> contains all the dimension *Symbol*s found in all
  # example results in <@exemplars>.

  #----------------------------------------------------------------------------
  # Variable: @exemplarPop
  # The accumlated exemplar results.
  #
  # Variable <@exemplarPop> is a result that accumulates all the results from
  # the individual examples in <@exemplars>.

  #----------------------------------------------------------------------------
  # Variable: @playerPop
  # The total of all results from all scored <Players>
  #
  # Variable <@playerPop> is a result that accumlates all the results ever
  # seen when scoring a player.

  #----------------------------------------------------------------------------
  # Variable: @allDims
  # Variable <@allDims> is a *Set* of all the dimensions ever seen.


  #============================================================================
  #
  # Methods
  #
  #============================================================================

  #----------------------------------------------------------------------------
  # Method: initialize
  # Initialize a newly created <Scorer>.
  #
  # Method <initialize> is the *Ruby* hidden method called on object creation
  # for a <Scorer> object. It fills the fields of the object for their 
  # initial state.
  #
  # Two of the fields are the set of exemplars and the set of dimensions of
  # the exemplars.
  #
  # Formal Parameters:
  #   scoreType - a *Symbol* that names the scoring method to use.
  #
  # Effects:
  #   The newly created <Scorer> has its attributes set to the their initial
  #   values.

  def initialize(scoreType)

    # Remember the Orion trace level locally.

    @trace = configuration.value(:tracelevel).to_i

    # Remember the scoring method.

    @scoreType = scoreType

    # Get the exemplars into an internal structure. Make each of the exemplar
    # results return 0 for a dimension that is unknown to them.

    exemplarFile = File.new(configuration.value(:exemplars), 'r')
    @exemplars   = eval(exemplarFile.read)
    exemplarFile.close
    @exemplars.each { |e| e.default=0 }

    # The exemplars may have some special failure codes in them. We clean
    # them up now. The clean up method would tell use the details, but we
    # really don't care.

    @exemplars.each { |r| findSpecials(r) }

    # Get the exemplar dimensions into a set.

    @exemplarDims = Set.new
    @exemplars.each { |e| @exemplarDims.merge(e.keys) }

    # Normalize each exemplar so that it is as if it had been run as many
    # times as the group size for the players. This is important so that the
    # distance measurement in the scoring works right.

    count = configuration.value(:probecnt).to_i
    @exemplars.each { |e| e.each { |k, v| e[k] = count*v } }

    # Now accumulate the exemplars into a single population.

    @exemplarPop = Hash.new(0)
    @exemplars.each { |e| mergeResults(@exemplarPop, e) }

    # Get the player results in order.

    @playerPop = Hash.new(0)
    @allDims   = Set.new(@exemplarDims)

    # Get the player statistics started.

    @sumVars  = Hash.new(0.0)
    @sumSqs   = Hash.new(0.0)
    @countPop = 0

    # Add in the scores for the exemplars

    @exemplars.each { |e| updateStatistics(e) }

  end


  #----------------------------------------------------------------------------
  # Method: updateStatistics
  # Add a new result in the statistics memory.
  #
  # Method <updateStatistics> adds one result into the statistics accumulators.

  def updateStatistics(theResults)

    theResults.each_key do |k|
      r            = theResults[k]
      @sumVars[k] += r
      @sumSqs[k]  += r*r
    end
    @countPop += 1

    @sumVars.each_key do |k|
      if @sumVars[k] == 0 and @sumSqs[k] != 0 then
        puts 'Dim = %s '%  k.to_s + ' Variable sum is zero.'
        raise
      end
    end

  end


  #----------------------------------------------------------------------------
  # Method: exemplarDistance
  # Player scores are based on distance to exemplars.
  #
  # Method <exemplarDistance> gives a score to each <Player> that is based on
  # on the distance from the <Player> to the closest exemplar.
  #
  # The method used has two major steps:
  #   - During the first step, the distance between every <Player> and every
  #     exemplar is computed. At the end of this cycle, the score for a 
  #     <Player> will be (temporarily) the shortest distance between itself
  #     and any exemplar. During the computations, the longest distance
  #     between any <Player> and any exemplar was also saved.
  #   - The final score for each <Player> is its shortest distance _divided_
  #     into the maximum distance. This means that scores run from 1 up to
  #     the number of times the shortest distance goes into the longest.
  #
  # Arguments:
  #   self       - the <Scorer> with the cumulative score data.
  #   thePlayers - an *Array* of <Players> that need to be scored.
  #
  # Effects: Each player has its score set.

  def exemplarDistance(thePlayers)

    # During this pass, compute the distances between every player and every
    # exemplar. Also keep track of the maximum distance ever seen.

    thePlayers.each do |p|

      p.score = nil

      @exemplars.each do |e|
        distance = 0.0
        @allDims.each do |d|
          diff = p.results[d] - e[d]
          distance += diff*diff
        end
        distance = Math.sqrt(distance)
        p.score  = distance if (p.score.nil? or distance < p.score)
      end

    end

    # Now each player's score becomes is "flipped" by dividing it into the
    # maximum distance. This makes "close" players have bigger scores.

    maxDistance = 0;
    thePlayers.each { |p| maxDistance = p.score if p.score > maxDistance }
    thePlayers.each { |p| p.score = maxDistance/p.score }

  end


  #----------------------------------------------------------------------------
  # Method: normalExemplarDistance
  # Scores are based on normalized distance to exemplars.
  #
  # Method <normalExemplarDistance> computes a <Player's> score by converting
  # the original dimension of each <Player> and exemplar to a normalized
  # dimension and them running a typical distance computation.

  def normalExemplarDimension(thePlayers)

    # Begin by getting the mean and standard deviation for every dimension

    mean   = Hash.new(0)
    stddev = Hash.new(0)

    # If the sum of squares is zero, we assume that only zero measurements 
    # were seen on this dimension and so we will give it somewhat artificial
    # value to avoid any later zero divides.

    @allDims.each do |d|
      if @sumSqs[d] == 0 
        mean[d]   = 0
        stddev[d] = 1
        next
      end

      mean[d]   = @sumVars[d]/@countPop
      var       = @sumSqs[d]/@countPop - mean[d]*mean[d]
      stddev[d] = var == 0 ? 1.0 : Math.sqrt(var)
    end
    
    # Now make a vector of zScores for each exemplar

    exemplarZScore = Array.new

    @exemplars.each do |e|
      eNormal = Hash.new(0.0)
      e.each_key do |k|
        eNormal[k] = (e[k] - mean[k])/stddev[k]
      end
      exemplarZScore.push(eNormal)
    end

    # Similarly, make a Hash of zScores for each player. We will index the
    # Hash by the player so we can update the player's score later.

    playerZScore = Hash.new

    thePlayers.each do |p|
      eNormal = Hash.new(0.0)
      p.results.each_key { |k| eNormal[k] = (p.results[k]-mean[k])/stddev[k] }
      playerZScore[p] = eNormal
    end

    # We now replicate the distance mesaurement from the exemplarDistance
    # method but with zScores instead of raw distances.

    thePlayers.each do |p|

      p.score = nil

      exemplarZScore.each do |e|
        distance = 0.0
        @allDims.each do |d|
          diff = playerZScore[p][d] - e[d]
          distance += diff*diff
        end
        distance = Math.sqrt(distance)
        p.score  = distance if (p.score.nil? or distance < p.score)
      end

    end

    # Now each player's score becomes is "flipped" by dividing it into the
    # maximum distance. This makes "close" players have bigger scores.

    maxDistance = 0;
    thePlayers.each { |p| maxDistance = p.score if p.score > maxDistance }
    thePlayers.each { |p| p.score = maxDistance/p.score }

  end


  #----------------------------------------------------------------------------
  # Method: scoreRound
  # Score one round.
  #
  # Method <scoreRound> computes the scores for a generation of players.
  # This, in turn, requires that
  #   - the elements of the scores be gathered from the players.
  #   - the elements are combined into the permanent scoring data.
  #   - each player is scored against that accumulation.
  #
  # Formal Parameters:
  #   self   - the <Scorer> recipient who is to do the scoring.
  #   curGen - an *Array* of <Players> who have score sheets in hand.
  #
  # Effects:
  #   - The <Scorer> accumulates the score information and assigns a score to
  #     each <Player> in the generation.
  #   - Accumulated scoring data is updated.
  
  def scoreRound(curGen)

    # We do not know the dimensions the execution engine reported for this
    # round. Each player reads its score file and updates its own results.
    # It then returns the set of all its dimensions. These are added into
    # the set of all dimensions for the round and that, in turn is added into
    # the cumulative set of all dimensions seen. The results are merged into
    # historical collection of all results.

    dimSet = Set.new
    curGen.each { |p| s = p.readResults; dimSet.merge(s); }
    curGen.each { |p| updateStatistics(p.results) }
    @allDims.merge(dimSet)
    curGen.each { |p| mergeResults(@playerPop, p.results) }

    # Now the chosen scoring method is called.

    self.send(@scoreType, curGen)

  end


  #----------------------------------------------------------------------------
  # Method: finalReport
  # Write final reports of interesting scoring facts.
  #
  # Method <finalReport> writes reports on various files and output streams
  # about the information uncovered during scoring. Principally, these are
  # occurrences of distinct ORA codes, operators, and the like.

  def finalReport

    # Make sure we can get a file to write to.

    begin
      sdFile = File.new(configuration.value(:allDimsName), 'w')
    rescue => excp
      errorExit('Scorer cannot write score keys file.', excp)
    end

    # Write an attractive sorted list of all the dimensions seen in player
    # results and the count of each score.

    dims = @playerPop.keys.sort
    vals = Array.new
    dims.each { |k| vals << @playerPop[k].to_s }

    left  = TextRect.new(dims.collect! { |d| d.to_s })
    right = TextRect.new(vals)
    left.join!(right, ' ', ' = ').box!('All dimensions and counts')
    sdFile.puts left.to_s
    
    # Now put out a list of all the distinct Ora codes.

    left = TextRect.new
    dims = @playerPop.keys.sort
    dims.each { |d| left.below!(d.to_s) if d.to_s.match('ORA-') }
    sdFile.puts ' '
    sdFile.puts left.number!.box!('Distinct ORA codes').to_s
 
    # Similarly, put out all the distinct Oracle opcodes.

    left = TextRect.new
    dims = @playerPop.keys.sort
    dims.each { |d| left.below!(d.to_s) if d.to_s.match('OraOp') }
    sdFile.puts ' '
    sdFile.puts left.number!.box!('Distinct RDBMS Oracle opcodes').to_s

    # Close the report file.

    sdFile.close

    # Now write the Ora Codes out on their own
    
    begin
      sdFile = File.new(configuration.value(:allDimsName)+'OraCodes', 'w')
    rescue => excp
      errorExit('Scorer cannot write OraCodes file.', excp)
    end

    oraNames = []
    dims.each {|d| oraNames << d.to_s if d.to_s.match('ORA-')}
    oraNames.collect! { |n| n.sub(/ORA\-/, '') }
    oraNames.each { |s| sdFile.puts s }
    sdFile.close

  end

end # Scorer
