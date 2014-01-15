# Copyright (c) 2011, 2012, Oracle and/or its affiliates. All rights reserved. 

#==============================================================================
# Class: Director
# The tournament director for <Orion>.
#
# Class <Director> is the genetic tournament directory for the <Orion>
# implementation of the *GeneticBug* project.

class Director

  require 'Player.rb'
  require 'Breeder.rb'

  include Report
  include Breeder

  #============================================================================
  #
  # Variables
  #
  #============================================================================

  #============================================================================
  # Variable: @scorer
  # A <Scorer> to help the <Director>.
  #
  # Variable <@scorer> is a <Scorer> associated with this <Director>. It does
  # the scoring for the player execution cycles.

  #============================================================================
  # Variable: @curGen
  # The *Orion* generation running now.
  #
  # Variable <@curGen> is an *Array* of <Players> running in the
  # the current generation.

  #============================================================================
  # Variable: @popcount
  # The number of <Players> in a generation.
  #
  # Variable <@popcount> is the number of <Players> in any one generation of
  # of the tournament.

  #============================================================================
  # Variable: @rounds
  # The number of tournament rounds.
  #
  # Variable <@rounds> is the number of rounds the current tournament will run.

  #============================================================================
  # Variable: @probecnt
  # The number of *SQL* statements in each round.
  #
  # Variable <@probecnt> is the number *SQL* statements that each <Player> will
  # generate for each round of the tournament. Strictly speaking, a probe might
  # consist of more than one *SQL* statement, but *Orion* will not be smart
  # enough to do that for some time yet.
  
  #============================================================================
  # Variable: @seed
  # The seed for Kernel.rand.
  #
  # Variable <@seed> remembers the initial seed for the random number
  # generator.


  #============================================================================
  #
  # Methods
  #
  #============================================================================

  #============================================================================
  # Method: initialize
  # Initialize a <Director>
  #
  # Method <initialize> is the *Ruby* way to ensure that a new <Director> is
  # properly started. 
  #
  # Effects:
  #   The <Director> is ready to operate.

  def initialize
    @scorer = Scorer.new(configuration.value(:scoreType))
    @curGen = nil
    @seed   = configuration.value(:seed).to_i
    srand @seed
  end


  #============================================================================
  # Method: run
  # Run an *Orion* tournament.
  #
  # Method <run> runs a complete *Orion* tournament according to the 
  # directions found in the *Orion* <Configurator>.
  #
  # Effects:
  #   An *Orion* tournament is run and the results are reported.

  def run

    # Tell the world we are running and trace the configuration.

    console { 'The Orion tournament is running.' }
    tracing(1) { configuration.to_TR }

    # Get initial configuration values and report them.

    @popcount = configuration.value(:popcount).to_i
    @rounds   = configuration.value(:rounds).to_i
    @probecnt = configuration.value(:probecnt).to_i

    console 'Tournament startup values' do
      [ "Grammars per round           = #{@popcount}",
        "Tournament rounds            = #{@rounds}",
        "Probes per grammar per round = #{@probecnt}" ]
    end

    # Get the execution setup.

    commandTemplate = 
      configuration.value(:sqlEngine) +
      ' ' + 
      configuration.value(:optionTemplate)

    saveFiles = configuration.value(:saveFiles)

    # Set up the competitors. The initial competitors are mutated to get
    # some (untrained) variation on the first round. Before that, they are
    # passed off to read weights if any were supplied. We mention variable
    # breeding just so it will be alive when the loop ends.
    
    @curGen = Array.new(@popcount){ Player.new.readWeights }
    self.send(configuration.value(:breedMutate), @curGen, TRUE)
    breeding = Hash.new

    # Now run the tournament proper.

    GC.enable

    1.upto(@rounds) do |round|

      GC.start
      console { "Running round #{round}." }

      @curGen.each do |p| 

        # Generate the probes for one player.

        tracing(2) { "Player #{p.id}, round #{round}: Probe build" }
        p.probeSet(@probecnt, round)

        # Run the executor on the probe set. Create an execution line first
        # and then send it to the system. 
        
        inName = p.probeSetName
        uName  = configuration.value(:schemaName)
        pWord  = configuration.value(:schemaPassword)
        rName  = p.resultsName
        cLine  = commandTemplate % [ inName, uName, pWord, rName ]

        tracing(2) { "Player #{p.id}, round #{round}: SQL exec" }
        unless system(cLine)
          errorExit("Player #{p.id}, round #{round}: Failure", nil)
        end
        tracing(2) { "Player #{p.id}, round #{round}: SQL done" }

      end

      oldGen = @curGen

      breeding = breed(@curGen, @scorer, round) 
      @curGen  = breeding[:newGen]

      # Remove the result and probe files unless they are to be saved.
      
      unless saveFiles
        oldGen.each do |p|
          File.delete(p.probeSetName)
          File.delete(p.resultsName)
        end
      end

    end

    # Trace  comparison of the starting and ending weights to the trace file.

    tracing(2, 'Start and end grammar weights') do
      p = Player.new.readWeights
      p.compareWeights(breeding[:winner])
    end

    # Write the winner's weights to an output file.

    begin
      if configuration.value?(:weightsOutName)
        woutName = configuration.value(:weightsOutName)
        woutFile = File.open(woutName, 'w')
        woutFile.puts breeding[:winner].writeWeights
        woutFile.close
      end     
      rescue => excp
        errorExit("Director cannot create weights file #{woutName}", excp)
    end

    # Ask the scorer to write records of all the interesting scoring data.

    @scorer.finalReport

    # All done

    console { 'The tournament was a load of fun.' }

  end

end # Director
