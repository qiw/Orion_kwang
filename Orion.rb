# Copyright (c) 2011, 2012, Oracle and/or its affiliates. All rights reserved. 

#==============================================================================
# Module: Orion
# Namespace for the *GeneticBug* implementation.
#
# Module <Orion> is the namespace container for the *Ruby* components of the
# *GeneticBug* project. It also starts the top level driver. Unexpected errors
# are caught and reported neatly here. <Orion> provides some application
# specific output and debugging methods.

require 'TextRect.rb'

module Orion

  require 'Configurator.rb'
  require 'Utility.rb'
  require 'Report.rb'
  require 'Scorer.rb'
  require 'Director.rb'
  require 'SymbolTable.rb'
  require 'Metadata.rb'
  require 'GramSym.rb'
  require 'GramRule.rb'
  require 'GramTree.rb'
  require 'Grammar.rb'
  require 'SQLGrammar.rb'


  #============================================================================
  # Method: analyzeprobe
  # Provide a detailed analysis of one *Orion* probe.
  #
  # Method <analyzeprobe> provides a detailed generation analysis of one
  # *Orion* probe. The intention is to help debugging of the generation
  # process. The analysis appears on the standard output.
  #
  # Effects:
  #   A detailed *Orion* probe analysis history appears on standard out.
  #
  # Notes:
  #   - The input configuration must specify the random seed used to generate
  #     the probe to be analyzed. Generally, this will be available from a
  #     probe that has already been generated.
  #   - The input configuration must specify the start symbol for the
  #     generation.
  #   - If the grammar weights are not specfied, the default weights will be
  #     used.

  def Orion.analyzeprobe
    Player.new.analyzeProbe
  end
    

  #============================================================================
  # Method: initial_weights
  # Get the *SQL* grammar's initial weights.
  #
  # Method <initial_weights> finds the initial weights assigned to the *SQL*
  # <Grammar> and writes them to standard output.
  #
  # Effects:
  #   The weights assigned to the initial built-in *SQL* <Grammar> appear as a
  #   vector of integers on standard output, one per line, in the same order
  #   as the productions in the <Grammar>.
  #
  # Notes:
  #   - The caller is responsible for ensuring that the output vector matches
  #     a <Grammar> if it is to be used later to initialize some other
  #     execution.

  def Orion.initial_weights
    puts Player.new.writeWeights
  end


  #============================================================================
  # Method: probegen
  # Generate an *Orion* probe set.
  #
  # Method <probegen> creates a set of *Orion* probes and writes them to a
  # file. This mechanism uses the same techniques as a full tournament to 
  # build the probes.
  #
  # Effects:
  #   A file of generated probes will be written as specified by the 
  #   input configuration.

  def Orion.probegen
    Player.new.probeGen
  end


  #============================================================================
  # Method: retrieve_sql_grammar
  # Get the *SQL* grammar used by *Orion*.
  #
  # Method <retrive_sql_grammar> finds the <Grammar> used for *Orion* probe
  # generation and writes it on standard output. The output is in a form
  # suitable for *PLParser* input.
  #
  # Effects:
  #   The <Grammar> used for *Orion* probe generation is written to standard
  #   output in a form suitable for *PLParser*.
  #
  # Notes:
  #   - The input must include a start symbol for the <Grammar> because
  #     *PLParser* implicitly assumes that the productions for the start
  #     symbol will be first.
  #   - There is no _human_ order to the productions.
  #   - All the productions for a particular non-terminal will be grouped.

  def Orion.retrieve_sql_grammar
    startSym = GramSym.new(@configuration.value(:startsym))
    puts Player.new.grammar.to_PLParser(startSym)
  end


  #============================================================================
  # Method: tournament
  # Run an *Orion* tournament.
  #
  # Method <tournament> runs a single tournament for *Orion*. If the method
  # succeeds, it will leave reports as instucted by the configuration; if it
  # fails, it will report the failure.
  #
  # Effects:
  #   A complete *Orion* tournament is run according to the configuration.
  #
  # Notes:
  #   - The purpose of the method is to wrap the call to the director.

  def Orion.tournament
    Director.new.run
    rescue SystemStackError => excp
      Report.reportError('Orion Director failed', excp)
  end


  #============================================================================
  # Method: validateweights
  # Validate a weight set and adjust it as requested.
  #
  # Method <validateweights> takes a set of <Grammar> weights as input and
  # checks them for consistency. In the process, it normalizes them to a
  # have a standardized largest weight and to eliminate non-zero weights.
  # If requested and if the weights are inconsistent, an attempt will be 
  # made to make the weights consistent. The output is either a set of 
  # consistent adjusted weights or an error message.
  #
  # Effects:
  #   The weights are adjusted as necesary and written out.
 
  def Orion.validateweights
    OrionGrammar.new.validateWeights
  end


  #============================================================================
  # Method: (main)
  # Run an *Orion* command.
  #
  # Start running. The configuration must be created BEFORE anything else is
  # done. Then <Report> must be started.  No <Report> routine should be called
  # before these steps are finished. Unless <Report> is sane, we cannot use
  # the error reporting procedures.
  #
  # The body of this method dispatches to the <Orion> method that does the
  # task required.

  begin
    @configuration = Configurator.new(ARGV[0])
    Report.setup(@configuration)
  rescue
    raise 'Orion failed in initial setup.'
  end

  begin
    eval "Orion.#{ARGV[1]}"
  rescue => excp
    Report.reportError('Orion top level', excp)
  end

end # Orion



