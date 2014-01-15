# Copyright (c) 2011, 2012, Oracle and/or its affiliates. All rights reserved. 

##############################################################################
# Class: GramTree
# A tree node in an abstract parse tree.
#
# A <GramTree> is a node in an abstract parse tree. Each node includes a 
# <GramSym> symbol, a representation function (may be *NIL*), a parent (is 
# *NIL* if this node is the root of a tree, and an ordered vector of children.
#
# Attributes:
#   @parent   - the <GramTree> that is the parent of this node. May be *NIL*.
#   @sym      - the <GramSym> for this node.
#   @children - a vector (that is, *Array*) of children ordered from left to
#               right. There may be no children, but the vector always exists.

class GramTree

  attr_reader   :sym
  attr_reader   :proc
  attr_reader   :children
  attr_accessor :myText
  attr_accessor :probeData
  attr_accessor :symbolTable


  #############################################################################
  # Method: initialize
  # Populate a new <GramTree>.
  #
  # Constructor <initialize> populates the attributes of a new <GramTree>.
  #
  # Formal Parameters:
  #   sym     - the <GramSym> for the new node.
  #   repProc - the representation function for the new node (may be *NIL*).
  #   genProc - the generation function (may be *NIL*).
  #
  # Value:
  #   A new <GramTree> with the supplied contents. This node has no children
  #   yet.

  def initialize(sym, probeData, repProc, genProc)
    @parent   		 = nil
    @sym      		 = sym
    @children 		 = []
    @repProc  		 = repProc
    @genProc  		 = genProc
    @myText   		 = nil
    @probeData		 = probeData
    @symbolTable	 = nil
  end


  #############################################################################
  # Method: to_s
  # Convert a <GramTree> to a *String*.
  #
  # Converter <to_s> converts a <GramTree> to a *String* for human purposes.
  #
  # Receiver:
  #   GramTree - the <GramTree> to be converted.
  #
  # Value:
  #   A *String* that represents the <GramTree> to a human.
  
  def to_s(offset = '')
    theLine   = ''
    newOffset = offset + ('  ') 
    @children.each do |c|
      theLine << c.to_s(newOffset) << "\n"
    end
    theLine << (offset + @sym.name )
  end


  #############################################################################
  # Method: frontier
  # Project the <GramTree> frontier.
  #
  # Method <frontier> projects the frontier of a <GramTree> as a *String*. The
  # "words" of the *String* are the text names of the <GramSyms> along the
  # frontier separated by spaces.
  #
  # Formal Parameters:
  #   self - the <GramTree> whose frontier is to be projected.
  #
  # Value:
  #   A *String* containing the text of the frontier.
  
  def frontier
    return self.sym.name if @children.empty?
    value = ''
    @children.each { |c| value << c.frontier << ' ' }
    return value
  end
  

  #############################################################################
  # Method: addChild
  # Add a child to a <GramTree>
  #
  # Mutator <addChild> adds a new child to the right of the existing children
  # of the <GramTree>. The argument's parent is set to point to the current
  # node.

  def addChild(child)
    @children << child
    child.setParent(self)
  end


  #############################################################################
  # Method: setParent
  # Set the parent of a <GramTree>.
  #
  # Mutator <setParent> sets the parent of a <GramTree> node.

  def setParent(parent)
    @parent = parent
  end


  #############################################################################
  # Method: changeRepProc
  # Change the representation procedure for this <GramTree>

  def changeRepProc(theProc)
    @repProc = theProc
  end


  #############################################################################
  # Method: changeGepProc
  # Change the generation procedure for this <GramTree>

  def changeGenProc(theProc)
    @genProc = theProc
  end


  #############################################################################
  # Method: represent
  # Create a text representation for a <GramTree> node
  #
  # HACK:
  #  - This doesn't really the <Grammar> argument under the *Orion* grammar
  #    system.

  def represent(theGram)
    return @sym.name unless theGram.isNT?(@sym)
    @repProc.call(self)
  end


  #############################################################################
  # Method: generate
  # Run a generation method on yourself.

  def generate
    @genProc.call(self) unless @genProc.nil?
  end

end # GramTree
