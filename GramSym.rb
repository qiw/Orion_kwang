# Copyright (c) 2011, Oracle and/or its affiliates. All rights reserved. 

##############################################################################
# Class: GramSym
# The symbol alphabet for a <Grammar>
#
# Class <GramSym> implements grammar symbols. It ensures that exactly one
# <GramSym> object exists for each distinct symbol text. The <new> method is
# redefined to ensure this property.
#
# Notes:
# * Unfortunately, the name *Symbol* is already used in Ruby.


class GramSym

  #############################################################################
  # GramSym Class Variables
  #############################################################################

  #############################################################################
  # Variable: @@symbolTable
  # The *Hash* that remembers created <GramSyms>.
  #
  # The class must remember the <GramSym> objects that have already been
  # created.  These are kept in a *Hash* whose pairs are the text of the
  # <GramSym> and the the <GramSym> object itself. The class variable
  # <@@symbolTable> holds this *Hash*.

  @@symbolTable = Hash.new


  #############################################################################
  # GramSym Automatic Attributes
  #############################################################################

  #############################################################################
  # Variable: @name
  # The name of a <GramSym>.
  #
  # Attribute <@name> is a readable attribute of a <GramSym>. This is the 
  # text supplied when the <GramSym> was created.

  attr_reader :name


  #############################################################################
  # GramSym Public Class Methods
  #############################################################################

  #############################################################################
  # Constructor: new
  # Construct a new <GramSym>
  #
  # Constructor <new> returns a <GramSym> with the supplied *String* as its
  # name. The constructor ensures that only one <GramSym> exists with a
  # particular name.
  #
  # Formal Parameters:
  #   name - a *String* to be the name of the <GramSym>
  #
  # Value:
  #   The unique <GramSym> with the supplied text as name.
  #
  # Side Effects:
  #   An entry may be made in the class variable <@@symbolTable>.

  def self.new(name)
    raise if name.nil?
    raise if name.class != String
    possible = @@symbolTable[name]
    return possible unless possible.nil?
    possible = allocate
    possible.send(:initialize, name)
    @@symbolTable[name] = possible
    return possible
  end


  #############################################################################
  # GramSym Public Instance Methods
  #############################################################################

  #############################################################################
  # Method: <=>
  # Three way comparison for <GramSyms>
  #
  # Comparator *<=>* compares two <GramSyms> and returns -1, 0, or 1 as the 
  # first is less than, equal to, or greater than the second. This is the 
  # normal Ruby comparison.
  #
  # Receiver:
  #   GramSym - the left hand <GramSym> for the comparison.
  #
  # Formal Parameters:
  #   s2 - the right hand <GramSym> for the comparison.
  #
  # Value:
  #   -1, 0, or 1. The result is the same as the text comparison using 
  #   *<=>* for *Strings* on the <GramSym> names.

  def <=>(s2)
    @name <=> s2.name
  end


  #############################################################################
  # GramSym Private Instance Methods
  #############################################################################

  #############################################################################
  # Method: initialize
  # Initialize a newly constructed <GramSym>
  # 
  # Initializer <initialize> initializes a newly allocated <GramSym> object.
  #
  # Formal Parameters:
  #   name - a *String* to be the name of the <GramSym>
  #
  # Value:
  #   The unique <GramSym> with the supplied text as name.
  #
  # Side Effects:
  #   The attributes of the <GramSym> are set.
  
  def initialize(name)
    @name = name
  end

end # class GramSym
