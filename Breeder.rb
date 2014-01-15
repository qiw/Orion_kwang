# Copyright (c) 2011, Oracle and/or its affiliates. All rights reserved. 

#==============================================================================
# Module: Breeder
# Implementation of breeding strategies for <Players>.
#
# Module <Breeder> contains the breeding strategies used to create a new 
# generation of <Players> from an existing one. <Breeder> is intended to be
# included in <Director> to allow the specific methods to be isolated from
# the logical operation of the <Director>.

module Breeder

  include Utility
  require_relative 'TextRect.rb'


  #============================================================================
  # Method: breed
  # Breed a new generation of <Players>.
  #
  # Method <breed> takes a current generation of <Players> with their 
  # execution reports and breeds a new generation. The new steps are
  #
  #   - Tell the <Breeder> that the generation is finished running.
  #   - Score each <Player>.
  #   - Rank the <Players>.
  #   - Breed the <Players> into a new generation.
  #
  # Formal Parameters:
  #   curGen - an *Array* of <Players> that have completed the round.
  #   scorer - the <Scorer> that is keeping track of the generation.
  #   round  - the number of the current round.
  #
  # Value:
  #   A new *Hash* with a new generation of <Players> and the best <Player>
  #   of the old generation.
  #   > { :newGen => new generation, :winner => best old Player }
  #
  # Notes:
  #   - The new generation will be the same size as the old.
  #
  # HACK:
  #   For the moment, the probabilities used in the breeding are hacked in.

  def breed(curGen, scorer, round)

    # Set parameters for this session.

    passThruPercent = 0.1

    genLen = curGen.length

    # Tell the scorer to create a score for everybody in the generation.
    
    scorer.scoreRound(curGen)

    # Now compute a score for each player.

    tracing(2) { prettyScores(curGen, "Unsorted scores after round #{round}") }

    # Sort the players by their scores. The minus signs push the smallest
    # value to the top (inverts the sort condition).
    
    curGen.sort! { |a, b| a.score <=> b.score }
    console { prettyScores(curGen, "Sorted scores after round #{round}.") }
                                                    
    # Create a fitness vector based on the ranks of the player scores. 
    # Assuming that the ranks run from 1 for the lowest score to n for the
    # highest score, there will i references to player ranked i in the 
    # vector.
    
    fitnessVec = []
    1.upto(genLen) { |i| fitnessVec += Array.new(i, curGen[i-1]) }

    # Begin creating a new generation. Any player that found a special Oracle
    # error code gets a free pass.

    newGen = Array.new
    curGen.each do |p|
      next unless p.specialCodeFound
      newP = Player.new
      newP.setWeights(p.weights)
      newGen.push(newP)
      tracing(2) { 'Special code pass thru player %d' % p.id }
    end

    # The winner of the last round gets a free pass presuming there is 
    # room left.

    if newGen.length < genLen
      newP = Player.new
      newP.setWeights(curGen.last.weights)
      newGen.push(newP)
      tracing(2) { 'Winner pass thru player %d' % curGen.last.id }
    end

    # Select some of the original players to go forward unchanged. These are
    # chosen at random according to the fitness vector.

    passCnt = ((genLen*passThruPercent) + 1).to_i
    passCnt = genLen - newGen.length if passCnt + newGen.length > genLen
    1.upto(passCnt) do
      newGen.push(self.send(configuration.value(:breedPassThru), fitnessVec))
    end

    # Fill the rest of the slots with new offspring.

    (newGen.length+1).upto(genLen) do
      newGen.push(self.send(configuration.value(:breedMate), fitnessVec))
    end

    # Finally, mutate a small proportion of the new generation.

    self.send(configuration.value(:breedMutate), newGen)

    return { :newGen => newGen, :winner => curGen.last }

  end


  #============================================================================
  # Method: mutateRuleAsGene
  # Mutate a generation.
  #
  # Method <mutateRuleAsGene> takes a generation of <Players> (contained in an
  # *Array*) and a <Configurator> for control values and mutates some of the
  # <Players>.  The <Players> are mutated in place; that is, the returned
  # generation has the same <Players> as the original but some of the
  # <Players> will have different behavior.
  #
  # Formal Parameters:
  #   gen - an *Array* of <Players> who are to be mutated.
  #   mutateAll - TRUE iff all the players of the generation are to be
  #               mutated. Defaults to FALSE.
  #
  # Effects:
  #   The <Players> in the generation have been mutated. Some of them will have
  #   different behavior than they had before.

  def mutateRuleAsGene(gen, mutateAll = FALSE)

    # We need to make sure that the mutant is consistent. Of course, the player
    # coming in IS consistent because we guarantee that. And so we can always
    # fall back on returning it unchanged. However, before we do that, we will
    # try multiple times to find a consistent mutation.

    mutatePercent = 0.20     # An arbitrary number.

    gen.each do |p|

      next unless mutateAll and rand <= mutatePercent

      tracing(2) { 'Mutate player %d' % p.id }

      # Get the weights from the player.

      myGenes = p.weights
      success = FALSE

      1.upto(gen.length) do # Generation length is a convenient limit

        # Copy and modify them the weights

        newGenes = myGenes.dup

        1.upto(newGenes.length/20) do 
          candidate = rand(newGenes.length)
          delta     = gRand(1.0, 0.1)
          newW      = (newGenes[candidate]*delta).to_i
          newGenes[candidate] = newW > 0 ? newW : 1
        end

        # Put the new weights into the player and test for consistency.
        # If we are, get out of here.

        p.setWeights(newGenes)        
        success = p.consistent?
        break if success

        # We have to go around the mutation loop again. Set the player's 
        # weights back to what they were.

        p.setWeights(myGenes)
          
      end

      # Report if we weren't successful. Notice that the old genes will have
      # been put back just before we fall out of the loop.

      tracing(2) { 'Mutation failed for player %d' % p.id } if not success

    end

  end


  #============================================================================
  # Method: passThruRuleAsGene
  # Create a <Player> to pass into the next generation
  #
  # Method <passThruRuleAsGenea> creates a new <Player> to pass through into a
  # new generation. The input is an *Array* of <Players> where each player is
  # represented as many times as its fitness suggests.
  #
  # Formal Parameters:
  #   fitnessVec - an *Array* of <Players>. The number of times a <Player> 
  #                appears in the vector is roughly propoportional to its
  #                selection probability based on fitness.
  # Value:
  #   A newly created <Player> that is a copy of a randomly selected
  #   (according to the fitness vector) <Player> passed in.
  #
  # Notes:
  #   - The copy is necessary because the same <Player> might be selected
  #     more than once and having multiple instances of the same <Player> in
  #     the next generation would lead to unfathomable bugs.

  def passThruRuleAsGene(fitnessVec)
    
    newP    = Player.new
    idx     = rand(fitnessVec.length)
    weights = fitnessVec[idx].weights
    newP.setWeights(weights)

    tracing(2) { 'Passed through player %d.' % fitnessVec[idx].id }

    return newP
    
  end


  #============================================================================
  # Method: matchMakeRuleAsGene
  # Breed two <Players> to create a third.
  #
  # Method <matchMakeRuleAsGene> selects two <Players> according to fitness
  # and forms a third whose genome is a combination of the parents'
  # genomes. The input is an *Array* of <Players> with more fit <Players>
  # appearing more often. The genome mix simply picks an arbitrary starting
  # point and an arbitrary length and replaces the genes from the first player
  # with those from the second starting at that point. The replacement is
  # wrap-around.
  #
  # Formal Parameters:
  #   fitnessVec - an *Array* of <Players>. The number of times a <Player> 
  #                appears in the vector is roughly propoportional to its
  #                selection probability based on fitness.
  #
  # Value:
  #   A new <Player> formed from the genetic combination of two existing
  #   <Players>.
  #
  # Notes:
  #   - Under this scheme, two <Players> may mate several times in a
  #     generation. But the offspring will be different (presumably) for 
  #     each mating because the genetic crossover will be (presumably)
  #     different.

  def matchMakeRuleAsGene(fitnessVec)

    #HACK HACK HACK
    Report.reportError('Must add consistency checking; see the matching NT method.')

    p1 = p2 = nil

    while TRUE do
      idx1 = rand(fitnessVec.length)
      idx2 = rand(fitnessVec.length)
      p1   = fitnessVec[idx1]
      p2   = fitnessVec[idx2]
      break if p1 != p2
    end

    weights1 = p1.weights
    weights2 = p2.weights
    
    crossOver = rand(weights1.length)
    swapLen   = (gRand(0.5, 0.1)*weights1.length).to_i
    swapLen   = 1 if swapLen < 1
    swapLen   = weights1.length/2 if swapLen >= weights1.length

    0.upto(swapLen-1) do |i|
      coIdx           = (crossOver+i).modulo(weights1.length)
      weights1[coIdx] = weights2[coIdx]
    end

    newP = Player.new
    newP.setWeights(weights1)

    tracing(2) do
      'Cross over player %d with player %d; start = %d, len = %d' %
        [ p1.id, p2.id, crossOver, swapLen ]
    end

    return newP

  end


  #============================================================================
  # Method: mutateNTAsGene
  # Mutate a generation under the nonterminal as gene rubric.
  #
  # Method <mutateNTAsGene> takes a generation of <Players> in an *Array* and
  # mutates some of the <Players>. The changes are in place; that is, the 
  # *Array* itself is unchanged but some of the <Players> may have changes to
  # their <Grammar> weights.
  #
  # The mutation occurs according to the nonterminal as gene rubric. A set of
  # nonterminals is selected and each of those nonterminals has all the
  # weights on all of its nonterminals modified.
  #
  # Formal Parameters:
  #   gen       - an *Array* of <Players> to be mutated.
  #   mutateAll - *TRUE* iff all the <Players> are to be mutated. Defaults to
  #               *FALSE*.
  #
  # Effects:
  #   The <Players> are mutated.

  def mutateNTAsGene(gen, mutateAll = FALSE)

    # Set the mutation parameters

    mutateRate       = 0.1 # Percentage of players to mutate.
    multiplierMean   = 1.0 # Base multiplier.
    multiplierStdDev = 0.1 # Spread of multiplier (as normal standard dev).
    ntRate           = 0.1 # Percentage of nonterminals to mutate.

    # Loop over all the players. Each gets a shot at being mutated. Of course
    # if we are mutating them all, then there is no need to use a random
    # choice

    gen.each do |p|

      next unless mutateAll or (rand < mutateRate)
      tracing(2) { 'Mutate player %d' % p.id }

      # Now we have a player to mutate. Get the grammar and then decide for
      # each non-terminal whether to modify it. We do that by asking the 
      # grammar for a random nonterminal symbol.

      grammar     = p.grammar
      mutateCount = (grammar.ntCount*ntRate).ceil
      myWeights   = p.weights
      success     = FALSE

      1.upto(gen.length) do # Generation length is a convenient limit.

        1.upto(mutateCount) do |i|
          
          # Get a random nonterminal from the grammar along and its rule
          # weights.  Then replace each weight in the weights vector with a
          # random variation.

          theNTData = grammar.randomNT
          weights   = theNTData[:weights]
          weights.each_index do |i|
            v = weights[i]
            newv = (v*gRand(multiplierMean, multiplierStdDev)).to_i
            weights[i] = newv < 1 ? 1 : newv
          end

          # Put the weights back into the data structure and ask the grammar to
          # update the nonterminal.

          theNTData[:weights] = weights
          grammar.updateNT(theNTData)

        end

        # Now check to see if the player is consistent.

        success = p.consistent?
        break if success

        # We have to go around the mutation loop again. Reset the player's
        # weights back to what they were.
        
        p.setWeights(myWeights)

      end

      # Report if we weren't successful. Notice that the old genes will have
      # been put back just before we fall out of the loop.

      tracing(2) { 'Mutation failed for player %d' % p.id } if not success

    end

  end


  #============================================================================
  # Method: matchMakeNTAsGene
  # Breed two <Players> to create a third.
  #
  # Method <matchMakeNTAsGene> selects two <Players> according to fitness and
  # forms a third whose genome is a combination of the parents' genomes. The
  # input is an *Array* of <Players> with more fit <Players> appearing more
  # often. The output is a new <Player> formed by a combination of two of 
  # the original <Players>. The combination is done nonterminal by nonterminal.
  #
  # Formal Parameters:
  #   fitnessVec - an *Array* of <Players>. The number of times a <Player> 
  #                appears in the vector is roughly propoportional to its
  #                selection probability based on fitness.
  #
  # Value:
  #   A new <Player> formed from the genetic combination of two existing
  #   <Players>.
  #
  # Notes:
  #   - Under this scheme, two <Players> may mate several times in a
  #     generation. But the offspring will be different (presumably) for 
  #     each mating because the genetic crossover will be (presumably)
  #     different.

  def matchMakeNTAsGene(fitnessVec)

    # Find two distinct players.

    p1 = p2 = nil

    while TRUE do
      idx1 = rand(fitnessVec.length)
      idx2 = rand(fitnessVec.length)
      p1   = fitnessVec[idx1]
      p2   = fitnessVec[idx2]
      break if p1.id != p2.id
    end

    tracing(2) { 'Cross over player %d with player %d' % [ p1.id, p2.id ] }

    # Now create an entirely new player and give it the weights of the first
    # parent.

    newP      = Player.new
    p1Weights = p1.weights

    1.upto(20) do

      newP.setWeights(p1Weights)

      # Now select nonterminals randomly from the second parent until we have half of
      # them (all distinct) and for each copy the weights for that nonterminal to the
      # new player.

      theNTs     = Set.new
      newGrammar = newP.grammar
      p2Grammar  = p2.grammar

      while TRUE do

        break if 2*theNTs.size > p2Grammar.ntCount
        ntData = p2Grammar.randomNT
        next if theNTs.member?(ntData[:NT])
        theNTs.add(ntData[:NT])
        newGrammar.updateNT(ntData)

      end

      return newP if newP.consistent?

    end

    # If we get here, we weren't able to create new weights. Report that and return
    # the first parent as value.

    tracing(2) { 'Crossover failed for players %d and %d.' % [ p1.id, p2.id ] }
    newP.setWeights(p1.Weights)

    return newP

  end


  #============================================================================
  # Method: prettyScores
  # Present scores in a pretty way for humans.
  #
  # Method <prettyScores> takes an *Array* of <Players> and provides an
  # attractive list of their scores in a new <TextRect>.
  #
  # Formal Parameters:
  #   thePlayers - an *Array* of <Players> in the order in which their 
  #                scores are to be presented.
  #   caption    - a *String* with a caption for the scores. There is a 
  #                sensible default.
  #
  # Value:
  #   A <TextRect> with the scores attractive presented.

  def prettyScores(thePlayers, caption = 'Scores')

    # Find the width needed for the player ID's. Also get the width for the
    # number of items.

    idBig      = thePlayers.inject(0) { |m,p| m > p.id ? m : p.id }
    idWidth    = Utility.numWidth(idBig)
    countWidth = Utility.numWidth(thePlayers.length)
    countWidth = countWidth < 2  ? 2 : countWidth

    # We need three columns: serial, player ID, and score.

    serialTR = TextRect.banner('Idx')
    idTR     = TextRect.banner('Player  ')    
    scoreTR  = TextRect.banner('Score   ')

    # We are going to make arrays of strings for each column so that we can
    # put them below the column names. We need formats first.

    serialFormat = "%#{countWidth}d. "
    idFormat     = "Score(%#{idWidth}d) = "
    scoresFormat = '%8.2f'

    serials = Array.new
    ids     = Array.new
    scores  = Array.new

    1.upto(thePlayers.length) do |i|
      p = thePlayers[i-1]
      serials.push(serialFormat % i)
      ids.push    (idFormat % p.id)
      scores.push (scoresFormat % p.score)
    end

    # Put the string arrays on the bottom of each TextRect, push the TextRects
    # together left to right, box the result, and return it.

    serialTR.below!(serials)
    idTR.below!(ids)
    scoreTR.below!(scores)

    serialTR.join!(idTR)
    serialTR.join!(scoreTR)
    
    # Return the box.

    serialTR.box(caption)

  end

end # Breeder
