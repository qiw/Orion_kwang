# Copyright (c) 2011, 2012, Oracle and/or its affiliates. All rights reserved. 

##############################################################################
# Class: Grammar
# A complete stochastic context free grammar.
#
# Class <Grammar> implements a stochastic context free grammar. It provides
# mechanisms for the definition of the grammar, the assignment of
# probabilities, tests for consistency, generation of sentences, and training
# of the grammar.  A grammar is built from <GramSymS> to provide the symbols
# and <GramRules> to provide the production rules.

class Grammar

  require 'OMatrix.rb'

  #############################################################################
  # Grammar Instance Attributes
  #############################################################################

  #############################################################################
  # Variable: @ruleTable
  # Vector of all weighted <GramRules> in the <Grammar>.
  #
  # Attribute <@ruleTable> is an *Array* of all the weighted <GramRules> added
  # to the <Grammar>. The *Array* is indexed from 0 with no gaps. Each element
  # is a baby structure of three elements which provide the weight, the
  # <GramRule> itself, and a procedure object that applies any semantic or
  # presentation restrictions during sentence generation. The structure is
  # implemented as a *Hash* with known fields.
  #
  # > :weight  => Numeric
  # > :rule    => GramRule
  # > :repProc => Proc
  # > :genProc => Proc


  #############################################################################
  # Variable: @ruleSet
  # A set of <GramRules>.
  #
  # Attribute <@ruleSet> is a *Hash*. The key is a <GramRule> and the value
  # is irrelevant. The attribute maintains the set of all rules
  # in hand and its properties. It also provides a quick way to see if a
  # <GramRule> has already been inserted in the <Grammar>.


  #############################################################################
  # Variable: @ntIndex
  # Index from nonterminal symbols to <GramRules>.
  #
  # Attribute <@ntIndex> maintains the relationship between nonterminal symbols
  # and grammar rules. It is a *Hash* whose keys are <GramSyms> and whose
  # values are a nonce structure.
  #
  # > @ntIndex == { GramSym => { :total => integer,
  # >                            :rules => Array, 
  # >                            :index => integer } }
  # >   GramSym is (by definition) a grammar nonterminal.
  # >   :total is total weight of all rules for the nonterminal
  # >   :rules is an Array of GramRule indexes in the @ruleTable
  # >   :index is a distinct index (starting from zero and with no gaps) for
  # >          the nonterminal.


  #############################################################################
  # Variable: @mapIdxToSym
  # Map for <@ntIndex> :index entries to <Symbols>.
  #
  # Variable <@mapIdxToSym> maps the integer :index entry in a <@ntIndex> item
  # back to the <Symbol> that is its index there. This is an *Array*.


  #############################################################################
  # Variable: @ntFamily
  # An *Array* of all the keys from <@ntIndex>.
  #
  # Variable <@ntFamily> maintains a set (implemented as an *Array*) of all the
  # nonterminal <GramSyms> that are keys of the <@ntIndex> table. This *Array*
  # supports the choice of a random nonterminal.


  #############################################################################
  # Grammar Private Instance Methods
  #############################################################################

  #############################################################################
  # Constructor: initialize
  # Construct a new <Grammar>
  #
  # Initializer <initialize> populates a new empty (but not *NIL*) <Grammar>
  # object.
  #
  # Value:
  #   A new, empty (not *NIL*) Grammar.
  #
  # Notes:
  # * In Ruby's magic way, the method name is <initialize>, but Ruby really
  #   creates a constructor *new* from it.

  def initialize
    @ruleTable   = Array.new
    @ruleSet     = Hash.new
    @ntIndex     = Hash.new
    @ntFamily    = nil # Initialized by first randomNT call.
    @metadata    = Metadata.new
    @mapIdxToSym = Array.new
  end


  #############################################################################
  # Grammar Public Instance Methods
  #############################################################################

  #############################################################################
  # Method: isNT?
  # *TRUE* if the <GramSym> is a nonterminal of the <Grammar>
  #
  # Predicate <isNT?> is *TRUE* if the <GramSym> is a nonterminal symbol in
  # the <Grammar>.
  # 
  # Receiver:
  #   Grammar - the <Grammar> containing the purported nonterminal symbol.
  #
  # Formal Parameters:
  #   s - a <GramSym> that might be a nonterminal in the <Grammar>.
  #
  # Value:
  #   *TRUE* if and only if there has been at least one <GramRule> added to
  #   the <Grammar> such that _s_ is on the left hand side of the <GramRule>

  def isNT?(s)
    @ntIndex.has_key?(s)
  end


  #############################################################################
  # Method: addRule
  # Add a <GramRule> to a <Grammar>.
  #
  # Mutator <addRule> adds a new <GramRule> to the <Grammar>. It is an error
  # to add the same rule more than once.
  #
  # Receiver:
  #   Grammar - the <Grammar> to which the <GramRule> is added.
  #
  # Formal Parameters:
  #   theRule   - a <GramRule> to added to the <Grammar>.
  #   theWeight - a weight for the rule. This must be a numeric value no less
  #               than one.
  #   repProc   - a (possibly *NIL*) *Proc* object that will be used to build
  #               the <GramTree> node for the <GramRule> during generation.
  #   genProc   - a (possibly *NIL*) *Proc* object that will be called during
  #               initial application of the rule when building the generated
  #               tree.
  #
  # Value:
  #   The revised <Grammar>.
  #
  # Side Effects:
  #   The <GramRule> and its associated values will be added to the <Grammar>.
  #
  # Errors:
  #   * It is an error to add the same <GramRule> more than once.
  #   * Neither the <GramRule> nor the weight may be *NIL*.
  #   * The weight will converted to an integer; this integer must be strictly
  #     larger than zero.

  def addRule(theRule, theWeight, repProc = nil, genProc = nil)

    # Check the obvious errors.

    errorExit('The input Rule is nil') if theRule.nil?
    errorExit('The input weight is nil') if theWeight.nil?
    theWeight = theWeight.to_i
    errorExit('The input weight %d < 0' % theWeight) if theWeight < 1
    errorExit('Duplicate rule %s' % theRule.to_s) if @ruleSet.has_key?(theRule)

    # If the left hand side is not in the table already, make the initial
    # entry. Notice that the index for the nonterminal is the length of the
    # Hash up to now. That length is not incremented until after the right
    # hand side of the expression is computed.

    lhs = theRule.lhs
    if not @ntIndex.has_key?(lhs)
      @mapIdxToSym[@ntIndex.length] = lhs
      @ntIndex[lhs] = { :total => 0, 
                        :rules => Array.new, 
                        :index => @ntIndex.length }
    end

    # Now insert the rule into its vector remembering the index and update the
    # nonterminal index.

    rIndex = @ruleTable.length
    @ruleSet[theRule] = nil
    @ruleTable << { :rule => theRule, :weight => theWeight,
                    :repProc => repProc, :genProc => genProc }
    @ntIndex[lhs][:total] += theWeight
    @ntIndex[lhs][:rules] << rIndex

    return self

  end


  #############################################################################
  # Method: to_TR
  # Make a <TextRect> of the <Grammar> for human consumption
  #
  # Projector method dumpMe reports the structure of the receiver Grammar in
  # a form intended for human construction. The report is returned as a
  # TextRect so that it can easily be combined with other text structures.
  #
  # === Parameters
  # [self] a receiver Grammar whose description is desired.
  #
  # === Value
  # A TextRect with a human readable description of the receiver Grammar. The
  # format is intentionally left undefined.

  def to_TR

    # Process the symbols into two groups. The nonterminals are just the keys
    # are just the symbols that start some rule. The terminals are everything
    # else. We find the terminals by catenating all the rule right hand sides
    # together, find the unique symbols, and then subtracting the nonterminals.

    theNTs = @ntIndex.keys
    theTs  = []

    @ruleSet.each_key { |r| theTs.concat(r.rhs) }
    theTs.uniq!
    theNTs.each { |s| theTs.delete(s) }
    
    tStrs  = []
    ntStrs = []
    theNTs.each { |s| ntStrs.push(s.name) }
    theTs.each  { |s| tStrs.push(s.name)  }
    ntStrs.sort!
    tStrs.sort!

    # The symbol dumps can be built now.

    theNTTR = TextRect.new(ntStrs)
    theTTR  = TextRect.new(tStrs)
    theNTTR.number!
    theTTR.number!

    theNTTR.columnate!(120, ' | ')
    theNTTR.box!('Nonterminals')
    theNTTR.below!(' ')
    theTTR.columnate!(120, ' | ')
    theTTR.box!('Terminals')
    theTTR.below!(' ')

    # Now build the rule dump.

    ruleDump = TextRect.new()

    @ntIndex.keys.sort.each do |h|

      title = "Rules starting with #{h.name}; weight = #{@ntIndex[h][:total]}"
      nums  = TextRect.new
      rules = TextRect.new
      @ntIndex[h][:rules].each do |r|
        nums.below!(sprintf("%d.", @ruleTable[r][:weight]))
        rules.below!(@ruleTable[r][:rule].to_s)
      end
      nums.rjust!
      nums.concat!(rules, ' ')
      nums.box!(title)
      nums.below!(' ')

      ruleDump.below!(nums)

    end

    ruleDump.box!('Production rules')
    ruleDump.below!(' ')

    # Put everything together in one dump.

    theNTTR.below!(theTTR)
    theNTTR.below!(ruleDump)

    return theNTTR.box!('The complete grammar dump.')

  end


  #############################################################################
  # Method: buildMatrices
  # Construct the interesting <Grammar> matrices.
  #
  # Method <buildMatrices> constructs and returns the interesting matrices
  # associated with a probabilistic grammar. The value is an *Hash* of 
  # three elements { :Q => q, :C => c, :A => a} where
  #  q - is the nonterminal to rule matrix whose elements are the probability
  #      that nonterminal is on the left of that rule.
  #  c - is the rule to nonterminal matrix whose elements are the count of 
  #      the nonterminal occurences in the rule.
  #  a - is the matrix product qc and is therefore square and indexed by
  #      nonterminals. The elements can be thought of as the average number
  #      of nonterminals generated by another nonterminal on one rule
  #      application.
  #
  # Recipient:
  #   <Grammar> - whose matrices are to be calculated.
  #
  # Value: 
  #   The *Hash* described above.

  def buildMatrices

    # We need the number of nonterminals and the number of rules to size the
    # matrices.

    ruleCnt = @ruleSet.length
    ntCnt   = @ntIndex.length

    # There are three matrices involved. The third is a product, so it will be
    # created automatically. The other two are Q and C.

    q = OMatrix.new(ntCnt, ruleCnt)
    c = OMatrix.new(ruleCnt, ntCnt)

    # The rows in matrix Q are indexed by nonterminals. Almost all entries of Q
    # are zero. The only non zero entries Q[i, j] are those where nontermial
    # i is at the left of rule j and then the value of the entry is the 
    # probability of rule j.

    @ntIndex.each_value do |ns|
      total = ns[:total].to_f
      theRow = ns[:index]
      ns[:rules].each do |r|
        theProb = @ruleTable[r][:weight]/total
        q[theRow, r] = theProb.to_f
      end
    end

    # The rows in matric C are indexed by rules and the column by nonterminals.
    # The entry C[i, j] is the number of times nonterminal j appears on the
    # right of rule i.

    @ruleTable.each_index do |i|
      r = @ruleTable[i][:rule]
      rhs = r.rhs
      rhs.each { |s| c[i, @ntIndex[s][:index]] += 1 if isNT?(s) }
    end

    # The matrix A is the product Q x C. If its spectral radius is strictly
    # less than 1, the grammar is consistent.

    a = q*c

    # Build the return hash.
    
    { :Q => q, :C => c, :A => a }

  end


  #############################################################################
  # Method: spectralRadius
  # Compute the spectral radius of a <Grammar>.
  #
  # Method <spectralRadius> computes the spectral radius of a <Grammar>. The
  # spectral radius is a numeric property associated with one of the matrices
  # derived from the grammar. It is used to decide if the <Grammar> is 
  # consistent.
  #
  # Receiver:
  #   <Grammar> - to be tested for consistency.
  #
  # Value:
  #   The spectral radius of the <Grammar>.

  def spectralRadius
    theMatrices = buildMatrices

    # HACK: If needed, this can dump the matrices. It is probably best used
    #       with ValidateGrammarWeights.

    if false

      qStream = File.new('QMatrix', 'w')
      cStream = File.new('CMatrix', 'w')
      aStream = File.new('AMatrix', 'w')

      qMatrix = theMatrices[:Q]
      qStream.puts 'Matrix Q[%d, %d]' % [qMatrix.rowSize, qMatrix.colSize]
      0.upto(qMatrix.rowSize-1) do |i|
        0.upto(qMatrix.colSize-1) do |j|
          val = qMatrix[i, j]
          qStream.puts '%d %d %f' % [i, j, val ] if val != 0.0
        end
      end

      cMatrix = theMatrices[:C]
      cStream.puts 'Matrix C[%d, %d]' % [cMatrix.rowSize, cMatrix.colSize]
      0.upto(cMatrix.rowSize-1) do |i|
        0.upto(cMatrix.colSize-1) do |j|
          val = cMatrix[i, j]
          cStream.puts '%d %d %f' % [i, j, val ] if val != 0.0
        end
      end

      aMatrix = theMatrices[:A]
      aStream.puts 'Matrix A[%d, %d]' % [aMatrix.rowSize, aMatrix.colSize]
      0.upto(aMatrix.rowSize-1) do |i|
        0.upto(aMatrix.colSize-1) do |j|
          val = aMatrix[i, j]
          aStream.puts '%d %d %f' % [i, j, val ] if val != 0.0
        end
      end

      qStream.close
      cStream.close
      aStream.close

    end
    return theMatrices[:A].radius
  end


  #############################################################################
  # Method: consistent?
  # Check if a <Grammar> is consistent.
  #
  # Predicate method <consistent?> tests a <Grammar> to see if it is
  # consistent. A _consistent_ grammar is one that will not "run away" while 
  # generating sentences.
  #
  # Receiver:
  #   Grammar - to be tested for consistency.
  #
  # Value:
  #   TRUE if and only if the <Grammar> is consistent.

  def consistent?
    return spectralRadius < 1.0
  end
  

  #############################################################################
  # Method: randomRule
  # Choose a random <GramRule> for a nonterminal <GramSym>.

  def randomRule(sym)

    raise unless isNT?(sym)

    theTotal    = 0
    totalWeight = @ntIndex[sym][:total]
    theChoice   = rand(totalWeight) + 1
   
    @ntIndex[sym][:rules].each do |i|
      theWeight  = @ruleTable[i][:weight]
      theTotal  += theWeight
      if theChoice <= theTotal
        ruleName = "Rule.#{sym.name}.#{i}"
        return { :rule     => @ruleTable[i][:rule], 
                 :repProc  => @ruleTable[i][:repProc],
                 :genProc  => @ruleTable[i][:genProc],
                 :ruleName => ruleName.to_sym }
      end
    end
    
  end


  #############################################################################
  # Method: defaultRepresent
  # Default representation method for a <GramTree> node.
  #
  # Callback <defaultRepresent> is the default representation generator for a
  # <GramTree> node. If the grammar definer doesn't specify any other method,
  # this one will be used.
  #
  # If the node represents a terminal, the value is the text of the terminal
  # symbol. If it is a nonterminal, the value is the catenation (in order, of
  # course) of the representations of the children. Blanks are stripped from
  # both ends of the value. There are blanks between children when there is
  # more than one.
  #
  # Formal Parameters:
  #   theTree - the <GramTree> node which is to be represented.
  #
  # Value:
  #   A *String* that is the representation of the node. There will be no
  #   blanks at either end of the *String* and conceivably the *String* could
  #   be empty (but not *NIL*).

  def defaultRepresent(theTree)
    return theTree.sym.name unless isNT?(theTree.sym)    
    theLine = ''
    spacer  = ''
    theTree.children.each do |c|
      theLine << spacer << c.represent(self)
      spacer = ' '
    end
    return theLine
  end


  #############################################################################
  # Method: ntCount
  # The number of nonterminals in the <Grammar>.
  #
  # Method <ntCount> returns the number of nonterminal symbols in the
  # <Grammar>.
  #
  # Formal Parameters:
  #   self (implicit) - the <Grammar> whose nonterminal count is needed.
  #
  # Value:
  #   The number of nonterminals in the <Grammar>.

  def ntCount
    return @ntIndex.length
  end
  

  #############################################################################
  # Method: projectNT
  # Project a nonterminal and its weights from the <Grammar>.
  #
  # Method <projectNT> takes a grammar nonterminal as its argument and returns
  # a nonce data structure with information about the nonterminal and its rule
  # weights. The data structure is a *Hash* and the listing here shows the
  # value for each of its keys.
  #
  # The Data Structure:
  #   :NT      - the <GramSym> for the nonterminal. This is just the input.
  #   :weights - an *Array* of the nonterminal's rule weights in order.
  #
  # Formal Parameters:
  #   self - the <Grammar> to be queried.
  #   nt   - the <GramSym> nonterminal to be projected.
  #
  # Value:
  #   The nonce data structure described here.

  def projectNT(nt)
    weights = []
    @ntIndex[nt][:rules].each { |ri| weights.push(@ruleTable[ri][:weight]) }
    return { :NT => nt, :weights => weights }
  end


  #############################################################################
  # Method: randomNT
  # Get a random nonterminal from the <Grammar>.
  # 
  # Method <randomNT> gets a random nonterminal <GramSym> from the <Grammar>.
  # The values are uniformly distributed. In addition, an *Array* of its 
  # rule weights is returned.
  #
  # Formal Parameters:
  #   self (implicit) - the <Grammar> from which a nonterminal is needed.
  # 
  # Value:
  #   A nonce data structure. This is a *Hash* with key :NT referencing the
  #   a nonterminal <GramSym> and key :weights referencing an *Array* of its
  #   rule weights.
  #
  # Notes:
  #   - On the first call, an *Array* of all nonterminals will be created from
  #     the grammar.

  def randomNT
    @ntFamily = @ntIndex.keys if @ntFamily.nil?
    theNT     = @ntFamily[rand(@ntFamily.length)]
    return projectNT(theNT)
  end


  #############################################################################
  # Method: updateNT
  # Updates a nonterminal with new weights.
  #
  # Method <updateNT> updates a nonterminal <GramSym> with new weights from the
  # same data structure as was produced by <randomNT>.

  def updateNT(theData)
    weights = theData[:weights]
    total   = weights.inject(0) { |s,v| s + v }
    theNT   = theData[:NT]
    @ntIndex[theNT][:total] = total
    i = 0
    @ntIndex[theNT][:rules].each do |r|
      @ruleTable[r][:weight] = weights[i]
      i += 1 
    end
  end


  #############################################################################
  # Method: generate
  # Generate a sentence from the <Grammar>
  #
  # Receiver:
  #   Grammar - a <Grammar> from which a sentence is to be generated.
  #
  # Formal Parameters:
  #   startSym   - a <GramSym> which is to be used as the start symbol for the
  #                sentence to be generated.
  #   theSeed    - an integer used to seed the random number generator.
  #   countProds - a boolean that is *TRUE* if a production count *Hash* should
  #                be created as part of the generation. Defaults to *FALSE*.
  #   doAnalysis - a boolean that tells whether analysis should be done. 
  #                Defaults to *FALSE*.
  #   forceSeed  - a boolean that says whether the seed provided should be 
  #                used without modification. Defaults to *FALSE*.
  #
  # Value:
  #   A nonce *Hash* of these elements:
  #     :start      - the starting <GramSym>.
  #     :text       - the *String* that is the sentence.
  #     :seed       - the random number seed that will get this sentence back
  #                   again.
  #     :analysis   - an analytic trace of the generation process as an *Array*
  #                   of *Strings*.
  #     :prodcounts - a *Hash* that counts the number of each production has 
  #                   been used in the generation. Unused productions default
  #                   to zero.
  
  def generate(startSym, theSeed,
               countProds=FALSE, doAnalysis=FALSE, forceSeed=FALSE)

    # Check the obvious errors and get set up. The interesting variables are
    #   top - the root of the generated tree.
    #   work - Array of tree nodes yet to expanded.
    #   analysis - the record of what happened.
    #
    # The analysis vector is a list of ad hoc records, themselves arrays. The
    # members of the array are the generated frontier left of the replaced
    # non-terminal, the remaining frontier right of the replacement, and the
    # replacement rule which also provides the replacement symbol.
    #
    #   :left  => left side before replacement.
    #   :right => items left to replace.
    #   :rule  => the rule doing the replacement.

    raise "Symbol |#{startSym.name}| not non-terminal" unless isNT?(startSym)
    theSeed = theSeed*configuration.value(:seed).to_i unless forceSeed
    srand theSeed

    # Each tree node contains private "metadata" that describes the
    # relationships between various names (and other things?) used in this 
    # specific generated probe. Only one object is created and it is passed 
    # around and modified by all the tree nodes as they are generated and
    # represented.
    #
    # The object itself is a hash (as a kind of poor man's record). The current
    # fields are
    #   :columns => ?
    #   :tables  => tables mentioned in the FROM clause and so eligible for 
    #               use as part of column names.
    #   :tableAliases => table aliases created in the FROM clause and so
    #                    eligible for use elsewhere.
    #   :queryNames => query names generated in some clauses and used
    #                  elsewhere.

    pd = {#:columns           => [], 
          #:tables            => [],
          #:tableAliases      => [],
          #:queryNames        => [],
          #:columnAliases     => [],
          #:views             => [],
          #:materializedViews => [] }
	 }

    @metadata.clearSymbolTable
    # @metadata.addSymbolTable # if @metadata.symtab.empty?	# This *if* condition is a TEMPORARY patch because it appears that @metadata gets reused for entire probeset

    prodCounts = Hash.new(0)

    # Now create the top tree node, put it in the worklist, and do whatever
    # analysis seems desirable.

    top        = GramTree.new(startSym, pd, self.method(:defaultRepresent),
                              nil)
    work       = [ top ]
    analysisTR = TextRect.new if doAnalysis

    # Begin a typical working loop. So long as there is something left in the
    # work list, process it. Notice that order doesn't matter because the
    # nodes are already hooked properly into their parents and are just waiting
    # their own expansion in turn.
    
    until work.empty? do

      # Only do a replacement if we have a nonterminal. But get the analysis
      # done if needed.

      theNode = work.shift
      theSym  = theNode.sym
      next unless isNT?(theSym)

      # Find a replacement rule for this non-terminal. The return value is a
      # *Hash* { :rule => GramRule, :repProc => repProc, :genProc => genProc }.
      # If there are procedures for the rule, tell the tree node about it.

      theHash = randomRule(theSym)
      theNode.changeRepProc(theHash[:repProc]) unless theHash[:repProc].nil?
      theNode.changeGenProc(theHash[:genProc]) unless theHash[:genProc].nil?
      theNode.generate
      prodCounts[theHash[:ruleName]] += 1 if countProds

      # For each symbol on the right hand side of the rule, add a new tree 
      # node and attach it to the parent. Also, push it onto the working list
      # for its own later expansion. Everybody gets the default representation
      # until they prove better.

      subWork = []
      
      theHash[:rule].rhs.each do |s|

        newNode = GramTree.new(s, pd, self.method(:defaultRepresent), nil)
        theNode.addChild newNode
        subWork.push(newNode)

      end

      work = subWork.concat(work)

      if doAnalysis
        analysisTR.below! "Rule: #{theHash[:rule].to_s}"
        analysisTR.below! TextRect.new(top.frontier).fold(90).lPad('      ')
        analysisTR.below! ' '
      end

    end

    # Now find the text representation. If the representation goes wrong, the
    # exception will be caught and the special 'generator died' statement
    # created.

    begin
      theText = top.represent(self)
      success = :T
      reason  = 'OK'
    rescue SyntaxError => excp
      theText = 'select null from dual where 1 = 0'
      success = :F
      reason  = excp.message
    end

    { :start      => startSym, 
      :seed       => theSeed,
      :analysis   => analysisTR,
      :text       => '/*%d*/ %s' % [ theSeed, theText ],
      :success    => success,
      :reason     => reason,
      :prodCounts => prodCounts
    }

  end


  #############################################################################
  # Method: to_weights
  # Project an *Array* of <GramRule> weights
  #
  # Projector <to_weights> creates an *Array* of the <GramRule> weights for
  # the <Grammar>. The *Array* is (implicitly) indexed in the same order as
  # the rules are in the <Grammar>.
  #
  # Receiver:
  #   Grammar - a <Grammar> whose <GramRule> weights are to be projected.
  #
  # Value:
  #   An *Array* of the <GramRule> weights for the <Grammar> in the order
  #   in which the <GramRules> appear.

  def to_weights
    weights = []
    @ruleTable.each_index { |i| weights << @ruleTable[i][:weight] }
    weights
  end



  #############################################################################
  # Method: humanWeights
  # Project a human-readable version of a weights table.
  #
  # Method <humanWeights> create a <TextRect> table of the <Grammar> weights
  # both suitable for human understanding and for later reinput to the the
  # *Orion* system. The output is textually weights with readable productions
  # but it takes the form of an evaluable text *Array*.
  #
  # Receiver:
  #   Grammar - a <Grammar> whose weights are to be projected.
  #
  # Value:
  #   a <TextRect> with an evaluable text *Array* of the weights.

  def humanWeights

    # Get the weights into an array and then find the width in digits of the
    # largest weight.

    weights = to_weights
    widths  = Array.new
    weights.each { |w| widths.push(Utility.numWidth(w)) }
    theWidth = widths.max

    # Make a TextRect column of the weights.

    theFormat = "  %#{theWidth}d, # "
    theStrs   = Array.new
    weights.each { |w| theStrs.push(theFormat % w) }
    theNums = TextRect.new(theStrs)

    # Now make a TextRect column of the text of the rules themselves.

    theRules = Array.new
    @ruleTable.each_index { |i| theRules.push(@ruleTable[i][:rule].to_s) }

    # Now put the parts together and return the result.

    theNums.join!(theRules)
    theTop = TextRect.new('[')
    theTop.below!(theNums)
    theTop.below!(TextRect.new(']'))
    
    theTop
                  
  end
  

  #############################################################################
  # Method: setWeights
  # Set the weights of the <Grammar>
  #
  # Method <setWeights> sets the weights of the <Grammar> from an incoming
  # *Array*.
  #
  # Formal Parameters:
  #   self      - the receiver <Grammar> whose weights are set.
  #   weights   - an *Array* of strictly positive values which will replace the
  #               current <Grammar> weights.
  #   checkOnes - TRUE if weights must be at least one.
  #
  # Effect:
  #   The <Grammar> will have its weights changed to supplied values.
  #
  # Errors:
  #   - Every weight will be converted to an integer. That integer must be at
  #     least 1. This check is only active if the checkOnes flag is on.
  #   - There must be exactly the same number of weights as rules in the 
  #     <Grammar>. The weights must be organized (by the caller) to be 
  #     correlated with those that might be project by <to_weights>.
  #
  # See Also:
  #   <to_weights>

  def setWeights(weights, checkOnes = TRUE)

    if weights.length != @ruleTable.length
       errorExit('Weights length %d != rule table length %d.' % 
                 [weights.length, @ruleTable.length])
    end

    # Update the individual weights.

    weights.each_index do |i|
      w = weights[i]
      errorExit('Input weight %d is zero' % i) if checkOnes and w < 1
      @ruleTable[i][:weight] = w
    end

    # Update the weight totals for each non terminal.

    @ntIndex.each_value do |v|
      total = 0
      v[:rules].each { |i| total += @ruleTable[i][:weight] }
      v[:total] = total
    end

  end


  #############################################################################
  # Method: to_PLParser
  # Project a <Grammar> into a *PLParser* input record.
  #
  # Projector <to_PLParser> projects a <Grammar> into a form suitable for 
  # *PLParser* input. This is essentially just a a pretty-printed text but the
  # the few special rules for *PLParser* files are respected. The output is 
  # a <TextRect> so that it is easy to use it elsewhere.
  #
  # Receiver:
  #   Grammar - the <Grammar> for which a *PLParser* input file is to be
  #             created.
  #
  # Formal Parameters:
  #   startSym - the start nonterminal for the <Grammar>.
  #
  # Value:
  #   A <TextRect> which contains the *PLParser* input.
  #   
  # Notes:
  #   * The value is a <TextRect> because it is easy to use this for further
  #     processing. In particular, it can simply be written to a text output
  #     file.
  #   * The exact layout of the *PLParser* input file is not specified. 
  #     *PLParser* itself will take fairly free-form input and it is a mistake
  #     to constrain this method too much.
  #   * At the moment, *PLParser* requires that its start nonterminal be the
  #     left hand side of the first production. A <Grammar> is looser than
  #     that so an artificial start is forced onto the *PLParser* input.

  def to_PLParser(startSym)

    thePLP = TextRect.new

    @ntIndex.each do |nt, s|

      theNT = TextRect.new("#{nt.name} ::= ")
      before = '   '

      s[:rules].each do |i|
        rhs = @ruleTable[i][:rule].rhs
        rhs.each { |sym| before << sym.name << ' ' }
        theNT.below!(before)
        before = ' | '
      end

      theNT.below!(' ;')
      thePLP.below!(theNT)

    end

    thePLP.below!('&G')

  end


  #############################################################################
  # Method: adjustWeights
  # Adjust a <Grammar's> weights to a top value
  #
  # Method <adjustWeights> adjusts all of a <Grammar's> weights to a particular
  # top value and replaces zeros with estimated frequencies.

  def adjustWeights(theTop)

    # The nonterminals are processed one by one.

    @ntIndex.each do |nonTerm, rSet| # nonTerm is used for debugging if needed.

      # Variable rules is an Array of Rules indexes.

      rules = rSet[:rules]

      # The first special case is when there is only one Rule for the
      # nonterminal. In that case, its weight is just the top weight
      # regardless of what it was before.

      if rules.length == 1
        @ruleTable[rules[0]][:weight] = theTop
        next
      end

      # Now we know that there are at least two rules. Find the maximum 
      # weight from all of them.

      max = 0.0
      rules.each do |i|
        x   = @ruleTable[i][:weight]
        max = x if max < x
      end

      # The second special case occurs when the maximum value is zero. That
      # means all the values are zero. In this case, we can just replace them
      # all with the top weight and go process the next nonterminal

      if max == 0.0
        rules.each { |i| @ruleTable[i][:weight] = theTop }
        next
      end

      # Now we know that there are at least two weights and that at least one
      # is not zero. Every weight will be multiplied by the ratio top/max.
      # This will make the maximum weight top and all the others smaller.
      # There may still be some zeros left and we will take care of those in a
      # moment.

      ratio = theTop.to_f/max
      rules.each { |i| @ruleTable[i][:weight] *= ratio }

      # AD HOC: Finally, make sure that no rule has a weight less than
      #         1/100-th of the top weight. By using the ceiling, we ensure
      #         that this is at least 1 even for small top values. This step
      #         eliminates any zeros.
      #
      # HACK: Eventually replace this with Good-Turing estimation.

      lowest = (0.01*theTop).ceil
      rules.each do |i|
        @ruleTable[i][:weight] = lowest if @ruleTable[i][:weight] < lowest 
      end

    end
    
    # Now we have to reset all the weight totals so the grammar follows the
    # weight rules.

    @ntIndex.each_value do |v|
      total = 0
      v[:rules].each { |i| total += @ruleTable[i][:weight] }
      v[:total] = total
    end

  end


  #############################################################################
  # Method: validateWeights
  # Validate weights for a <Grammar>.
  #
  # Method <validateWeights> takes a set of <Grammar> weights as input and
  # checks them for consistency. In the process, it normalizes them to a
  # have a standardized largest weight and to eliminate non-zero weights.
  # If requested and if the weights are inconsistent, an attempt will be 
  # made to make the weights consistent. The output is either a set of 
  # consistent adjusted weights or an error message.
  #
  # Effects:
  #   The weights are adjusted as necesary and written out.
  #
  # Notes:
  #   - The weights are in the configuration parameter :weightsIn.

  def validateWeights

    # Read in the weights. Put them into the rules allowing zeros. Adjust them
    # to the top weight requested.

    theWeights = configuration.value(:weightsIn)
    setWeights(theWeights, FALSE)
    adjustWeights(configuration.value(:topWeight).to_f)

    # Find the spectral radius of the grammar. Report the size to user.

    wFile  = File.new(configuration.value(:weightsOut), 'w')
    radius = spectralRadius
    msg    = 'Grammar is %sconsistent; radius = %f' % 
              [ radius >= 1.0 ? 'in' : '', radius ] 
    console { msg }

    # Now find the maximum radius desired. If there isn't one, assume 1.0 will
    # do. If the grammar fits under that bound, write it out and report to the
    # user.

    maxRadius =
      configuration.value?(:maxRadius) ? configuration.value(:maxRadius) : 1.0

    if radius < maxRadius
      console { 'Grammar is under bound %f. New weights written' % maxRadius }
      wFile.puts humanWeights
      wFile.close
      return
    end

    # Report that the grammar is not under the desired bound. Say so.

    console { 'Grammar radius %f > bound %f' % [ radius, maxRadius ] }
    if not configuration.value(:adjustConsistency)
      wFile.puts humanWeights
      wFile.close
      console { 'Adjustment is off; out of bounds weights written' }
      return
    end

    # The problem comes from the non-zero elements of the matrix. There are
    # relatively few of these (about 300 out of 40,000 in one example). So we
    # look for the non-zero elements and record them. Begin by setting up the
    # data we eneed.

    theMatrices  = buildMatrices
    a            = theMatrices[:A]
    q            = theMatrices[:Q]
    c            = theMatrices[:C]
    aSide        = q.rowSize
    rSide        = q.colSize

    # Find the non-zero elements of A and push their indices into a vector
    # locations. Put if a non-terminal has only one rule, don't bother with
    # it. That probability will always be 1.0.

    thePairs = Array.new
    0.upto(aSide-1) do |i|
      next if @ntIndex[@mapIdxToSym[i]][:rules].length == 1
      0.upto(aSide-1) do |j|
        thePairs.push([i, j]) if a[i, j] != 0
      end
    end

    # The next step is to attempt to lower the radius. We do this by attacking
    # the non-zero entries -- at random. Each entry is the dot product of the
    # probabilities coming from one nonterminal and the nonterminal symbol
    # counts per rule from another nonterminal. The idea is to look for a
    # single subproduct of one of the selected dot product (or nonzero A matrix
    # entry) and to lower that subproduct by lowering the probability of one
    # of the rules. We do this process repeatedly until we tire of it or the
    # radius drops below a reasonable level.
    #
    # Notice that nothing that is done in this loop can create a new non-zero
    # entry nor drive an old one to zero.
    #
    # In this process, we only accept a change if it improves the radius. We
    # also make the element shrinkage more and more stringent as we fail to
    # improve and then relax it again when we do improve. There are bounds on
    # on how high and low the shrinkage can be.

    oldRadius = radius
    hiCutoff  = 0.9
    loCutoff  = 0.1
    shrinker  = 0.99
    theShrink = hiCutoff
    
    1.upto(20000) do |attempt|

      # Now we select a random non-zero entry to try to make smaller.

      thePair  = choose(thePairs)
      leftIdx  = thePair[0]
      rightIdx = thePair[1]
      leftSym  = @mapIdxToSym[leftIdx]
      rightSym = @mapIdxToSym[rightIdx]

      # Next, look for the subproduct of that product that is the largest. If
      # they are all the same, any one will do. This is true even if there is
      # just one.

      maxProd = 0.0
      maxIdx  = -1
      0.upto(rSide-1) do |j|
        product = q[leftIdx, j]*c[j, rightIdx]
        if product != 0.0
          newMax  = [maxProd, product].max
          maxIdx  = j if newMax >= maxProd
          maxProd = newMax
        end
      end

      # Adjust the weight of the rule we found downward. Save the weights in
      # case this adjustment didn't work. Don't let a weight shrink below 1.

      oldWeights                  = to_weights
      oldWeight                   = @ruleTable[maxIdx][:weight]
      @ruleTable[maxIdx][:weight] = [oldWeight*theShrink, 1.0].max.ceil

      # Adjust the totals for the nonterminal.

      total = 0
      @ntIndex[leftSym][:rules].each { |i| total += @ruleTable[i][:weight] }
      @ntIndex[leftSym][:total] = total

      # Adjust the q matrix entries. They will change exactly where the 
      # weights have changed in the nonterminal

      @ntIndex[leftSym][:rules].each do |i|
        q[leftIdx, i] = @ruleTable[i][:weight]/total.to_f
      end

      # Recompute the matrix A. Recompute the spectral matrix. If it is
      # small enough, quit. Remember to readjust the weights when before
      # writing them.

      a      = q*c
      radius = a.radius

      if radius <= maxRadius
        console { [ 'Grammar weights under bound %f.' % maxRadius,
                    'New spectral radius = %f' % radius,
                    'New weights written.'
                  ]
                }
        adjustWeights(configuration.value(:topWeight).to_f)
        wFile.puts humanWeights
        wFile.close
        return
      end

      # The attempt didn't go far enough. Figure out if it was an improvement.

      if radius > oldRadius
        # No improvement. Put back the old weights and shrink more next time.
        theShrink = [ loCutoff, theShrink*shrinker ].max
        setWeights(oldWeights)
        direction = 'Regress'
      else
        # Yeah! Remember the best radius and relax the shrink ratio.
        oldRadius = radius
        theShrink = [ hiCutoff, (theShrink+hiCutoff)/2.0 ].min
        direction = 'Improve'
      end
        
      # Report on progress every once in a while

      if attempt.divmod(1000)[1] == 0
        console { '%d: %s Radius = %f; shrink = %f' %
                     [attempt, direction, oldRadius, theShrink]
                }
      end

    end

    errorExit 'HACK: weight validation incomplete'

  end


  #############################################################################
  # Method: chooseTable
  # Choose a table name from the metadata.

  def chooseTable
    @metadata.chooseTable
  end


  #############################################################################
  # Method: addTableAlias
  # Add a new table alias

  def addTableAlias(theAlias)
    @metadata.addTableAlias(theAlias)
  end


  #############################################################################
  # Method: chooseTableAlias
  # Choose a table alias from the metadata.

  def chooseTableAlias
    @metadata.chooseTableAlias
  end


  #############################################################################
  # Method: chooseColumn
  # Choose a column name from the metadata.

  def chooseColumn
    @metadata.chooseColumn
  end


  #############################################################################
  # Method: addColumnAlias
  # Add a new column alias

  def addColumnAlias(theAlias)
    @metadata.addColumnAlias(theAlias)
  end


  #############################################################################
  # Method: chooseColumnAlias
  # Choose a column alias from the metadata.

  def chooseColumnAlias
    @metadata.chooseColumnAlias
  end


  #############################################################################
  # Method: chooseSchema
  # Choose a schema name from the metadata.

  def chooseSchema
    @metadata.chooseSchema
  end


  #############################################################################
  # Method: addQueryName
  # Add a new queryName

  def addQueryName(theName)
    @metadata.addQueryName(theName)
  end


  #############################################################################
  # Method: chooseQueryName
  # Choose a query name from the metadata.

  def chooseQueryName
    @metadata.chooseQueryName
  end


end # class Grammar
