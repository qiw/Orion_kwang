# Copyright (c) 2011, Oracle and/or its affiliates. All rights reserved. 

#==============================================================================
# Class: Driver
# The top level driver for <Orion>.
#
# Class <Driver> runs the <Orion> operation from the top level.

class Driver

  include Utility

  #============================================================================
  #
  # Variables And Constants
  #
  #============================================================================

  #============================================================================
  # Variable: @configName
  # The name of the configuration file.
  #
  # Instance variable <@configName> is a *String* that provides the name of
  # configuration file for this run of *Orion*.

  #============================================================================
  # Variable: @configuration
  # The <Configurator> that controls this *Orion* run.
  #
  # Instance variable <@configuration> is a <Configurator> that controls this
  # *Orion* run. It is created directly from the <@configName> used to 
  # initialize this 

  #============================================================================
  #
  # Methods
  #
  #============================================================================

  #============================================================================
  # Method: initialize
  # Initialize a newly created <Driver>.
  #
  # Method <initialize> is the *Ruby* hidden method called on object creation
  # for a <Driver> object. It fills the fields of the object for their 
  # initial state.
  #
  # Formal Parameters:
  #   configName - the text of the configuration file name.
  #
  # Effects:
  #   The newly created <Driver> has its attributes set to the their initial
  #   values.

  def initialize(configName)
    @configName = configName
  end


  #============================================================================
  # Method: run
  # Run a complete *Orion* operation.
  #
  # Method <run> does a complete *Orion* execution cycle. The actual behavior
  # is controlled by the configuration that was initialized when the <Driver>
  # was created.
  #
  # Effects:
  #   A complete *Orion* cycle is executed. Various files and other outputs
  #   may be modified or created depending on the requests in the
  #   configuration.

  def run
    Utility.report(nil, 'Orion is running.')
    @scorer        = Scorer.new(@configuration)
    @director      = Director.new(@configuration, @scorer)
    @director.run
  end

end # Driver
