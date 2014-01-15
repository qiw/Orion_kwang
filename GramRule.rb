# Copyright (c) 2011, Oracle and/or its affiliates. All rights reserved. 

##############################################################################
# Class: GramRule
# Production rules for a <Grammar> object.
#
# Class <GramRule> implements grammar rules. It ensures that exactly one
# <GramRule> object exists for each (mathematically) distinct production in a
# context free grammar. The <new> method is redefined to ensure this property.

class GramRule

  #############################################################################
  # GramRule Class Variables
  #############################################################################

  #############################################################################
  # Variable: @@ruleTable
  # The *Hash* that remembers existing <GramRules>.
  #
  # Class variable <@@ruleTable> is the *Hash* that remembers <GramRules> that
  # have already been created.  These are kept in a *Hash* whose pairs are a
  # <GramSym> and a *Hash*.  The <GramSym> is the left hand side of a possible
  # rule and the *Hash* contains all the possible right hand sides. Each right
  # hand side is paired with the completed <GramRule> it represents. When a
  # new <GramRule> candidate is proposed, it is searched in this structure. If
  # an existing <GramRule> matches the candidate, it is returned. Otherwise a
  # new <GramRule> is created and inserted into the table before it is
  # returned.
  #
  # <@@ruleTable> is a class variable because all <GramRules> must be checked.
  # It must start empty, of course, because nothing has been done yet.

  @@ruleTable = Hash.new


  #############################################################################
  # GramRule Public Class Methods
  #############################################################################

  #############################################################################
  # Constructor: new
  # Construct a new <GramRule>
  #
  # Constructor <new> returns a <GramRule> with the left hand and right hand
  # sides provided by the caller. Because the policy is that only one
  # <GramRule> can exist with such a pair, the <GramRule> may not be
  # constructed at the moment; one constructed earlier may be returned.
  #
  # Formal Parameters:
  #   lhs - a <GramSym> that is to be the left hand side of the rule.
  #   rhs - an *Array* of <GramSyms> that form the right hand side of the rule.
  #         The array may be empty, but it may not be *NIL*.
  #
  # Value:
  #   A <GramRule> with the specified left and right hand sides. This method
  #   must always return a value.
  #
  # Side Effects:
  #   The class variable <@@ruleTable> may have an entry made or updated.
  #
  # Implementation Notes:
  #   This method is a redefinition of the default constructor. It checks for
  #   errors, uses the <@@ruleTable> dictionary to see if an appropriate
  #   rule already exists, and returns that if it can. Otherwise, it does an
  #   explicit allocation and initialization of a new <GramRule>, puts that in
  #   the dictionary, and returns it.

  def self.new(lhs, rhs)

    raise if lhs.nil?
    raise if lhs.class != GramSym
    raise if rhs.nil?
    raise if rhs.class != Array
    raise if rhs.compact.length < rhs.length
    rhs.each { |s| raise if s.class != GramSym }

    @@ruleTable[lhs] = Array.new if @@ruleTable[lhs].nil?
    @@ruleTable[lhs].each { |aRule| return aRule if rhs.eql?(aRule.rhs) }

    newRule = allocate
    newRule.send(:initialize, lhs, rhs)
    @@ruleTable[lhs] << newRule

    return newRule

  end


  #############################################################################
  # GramRule Attribute Methods
  #############################################################################

  #############################################################################
  # Method: lhs
  # Return the left hand side <GramSym> of a <GramRule>
  #
  # Reader attribute <lhs> returns the <GramSym> that is the left hand side of
  # a <GramRule>.
  #
  # Receiver:
  #   GramRule - the rule whose left hand side is wanted.
  #
  # Value:
  #    The left hand side of the <GramRule>

  attr_reader :lhs


  #############################################################################
  # GramRule Private Instance Methods
  #############################################################################

  #############################################################################
  # Method: initialize
  # Initialize a new <GramRule>
  #
  # Initializer <initialize> sets the initial attribute values for a <GramRule>
  # object.
  #
  # Receiver:
  #   GramRule - a rule waiting to be initialized.
  #
  # Formal Parameters:
  #   lhs - a <GramSym> that is to be the left hand side of the rule.
  #   rhs - an *Array* of <GramSyms> that form the right hand side of the rule.
  #         The array may be empty, but it may not be *NIL*.
  #
  # Value:
  #   Formally, the initialized <GramRule> is returned although this fact is
  #   not made use of.
  #
  # Side Effects:
  #   The attributes of the <GramRule> are set.

  def initialize(lhs, rhs)
    @lhs = lhs
    @rhs = rhs
  end


  #############################################################################
  # GramRule Public Instance Methods
  #############################################################################

  #############################################################################
  # Method: rhs
  # Projects the right hand side of a <GramRule>
  #
  # Projector <rhs> projects the right hand side of a <GramRule> object.
  #
  # Receiver:
  #   GramRule - the <GramRule> whose right hand side is projected.
  #
  # Value:
  #   An *Array* that is the right hand side of the <GramRule>. Strictly, this
  #   is a copy so that modifications to it do not change the original rule.

  def rhs
    @rhs.dup
  end


  #############################################################################
  # Method: to_s
  # Convert a <GramRule> to a *String*.
  #
  # Convertor <to_s> converts a <GramRule> into a human readable *String* that
  # looks like a typical context free production from a textbook.
  #
  # Receiver:
  #   GramRule - the rule that is to be converted.
  #
  # Value:
  #   A *String* that looks like what humans think a production rule looks
  #   like.

  def to_s
    val = @lhs.name + " ==>"
    @rhs.each { |s| val.concat(" " + s.name) }
    return val
  end

end # class GramRule
