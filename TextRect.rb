# Copyright (c) 2010, 2011, Oracle and/or its affiliates. All rights reserved. 

#==============================================================================
# Class: TextRect
# Management for blocks of text.
#
# Class <TextRect> manages the production and manipulation of text rectangles,
# blocks of text that are aligned horizontally and vertically.
#
# The purpose of <TextRects> is to build nice aligned displays of text lines
# for outputs like tables and reports. Along with the basic operations,
# <TextRects> supply many additional operations to make common operations like
# bannering and bordering easy to do.
#
# A <TextRect> is a vector of *Strings*. There are no returns in the
# *String*s; when a <TextRect> is first constructed, any existing returns are
# used to break longer *Strings* into several lines. A <TextRect> may be
# thought of as a box of characters, as wide as its longest *String* and as
# deep as the number of lines. A *TextRect* may be empty (not *NIL*) when it
# happens to have no lines at all.
#
# <TextRects> can be combined vertically and horizontally. When they are 
# combined horizontally, the lines from the left <TextRect> are padded so that
# the result is columnar. There are several fancier ways to combine
# <TextRects>.

class TextRect

  #============================================================================
  #
  #   Class methods
  #
  #============================================================================

  #----------------------------------------------------------------------------
  # Method: banner
  # Make a banner from a *String*.
  #
  # Method <banner> takes a *String* and builds a <TextRect> with the
  # *String* as an underlined banner. If no underlining character is provided,
  # the hyphen character '-' is used.
  #
  # Format Parameters:
  #   theHead - a *String* that is to be used as a banner text. Any returns in
  #             the *String* are deleted.
  #   theBar  - a character to use for underlining.  If the argument contains
  #             multiple characters, only the first will be used.  The default
  #             value is the hyphen character '-'.
  #
  # Value:
  #   A new <TextRect> with two lines: the first is the bannering text and the 
  #   second is an underline as long as the banner.
  #
  # Example:
  #   > TextRect.banner('Hi there!', '=') # => Hi there!
  #   >                                        =========

  def TextRect.banner(theHead, theBar = '-')
    theBar    = theBar[0,1] unless theBar.nil? or theBar.length == 0
    cleanHead = theHead.delete("\n")
    TextRect.new([ cleanHead, cleanHead.tr(cleanHead, theBar) ])
  end

  
  #============================================================================
  #
  #   Instance methods
  #
  #============================================================================

  #----------------------------------------------------------------------------
  # Method: initialize
  # Create a new <TextRect>.
  # 
  # Method <initialize> builds a new <TextRect> and returns it as value. The
  # value of the argument determines the *String*s that will initialize the
  # <TextRect>.
  #
  # nil      - an empty (but not *NIL*) <TextRect> is created.
  # String   - the <TextRect> is initialized with the contents of the
  #            *String*.
  # Array    - the <TextRect> is initialized with the contents of the
  #            *Array*. Each array element must be a *String*.
  # TextRect - the new <TextRect> is a (deep) copy of the old.
  #
  # In general, any *String* used to initialize a <TextRect> that has _k_
  # internal returns will create <em>(k+1)</em> lines in the <TextRect>; the
  # splits occur at the returns. All returns (including a trailing one if it
  # exists) are discarded.
  #
  # Formal Parameters:
  #   arg - a description of the <TextRect> to be created.
  #
  # Effect:
  #   A new <TextRect> is initialized with lines determined by the argument.
  #
  # Errors:
  #   - An argument of any other class will cause initialization to fail.

  def initialize(arg = nil)

    @theLines = []
    return if arg.nil?

    case arg
      when String   then @theLines.concat(arg.split("\n"))
      when Array    then arg.each { |s| @theLines.concat(s.split("\n")) }
      when TextRect then @theLines = arg.lines
      else raise 'TextRect new() argument has unknown class.'      
    end

  end


  #----------------------------------------------------------------------------
  # Method: below
  # Put one <TextRect> below another.
  # 
  # Method <below> builds a new <TextRect> whose lines are those of the
  # reciever <TextRect> followed by those supplied by the argument. If the
  # addend is *NIL*, the new <TextRect> is a copy of the old.
  #
  # Formal Parameters:
  # self   - a <TextRect> whose lines are to be combined with the addend.
  # addend - the extension to the <TextRect>. The addend parameter follows the
  #          the same rules as the parameter for <initialize>.
  #
  # Value:
  #   A new <TextRect> whose lines are those of the original <TextRect>
  #   followed by the lines supplied by the addend.
  #
  # Examples:
  #   > A = TextRect.new("abc\ndef\nghikl") # => abc
  #   >                                          def
  #   >                                          ghikl
  #   A way to copy A; this produces a new <TextRect> just like A.
  #   > A.below(nil)                        # => abc
  #   >                                          def
  #   >                                          ghikl
  #
  #   > A.below("rst\ntuvw")                # => abc
  #   >                                          def
  #   >                                          ghikl
  #   >                                          rst
  #   >                                          tuvw
  #
  # See Also:
  #  - <below!>
  #  - <new>

  def below(addend)
    TextRect.new(self).below!(addend)
  end


  #----------------------------------------------------------------------------
  # Method: below!
  # Put one <TextRect> below another.
  #
  # Method <below!> builds a <TextRect> from its argument and mutates the
  # receiver by putting the lines of the new <TextRect> below those of the
  # receiver. The processing of arguments and construction of the value is the
  # same as method <below> The mutated receiver is returned as value.
  #
  # Formal Parameters:
  # self   - a <TextRect> that is to be mutated by the addition of lines.
  # addend - the extension to the <TextRect>. The addend follows the rules for
  #          the method <below>.
  #
  # Value:
  #   The receiver <TextRect> with the specified lines added below.
  #
  # Side Effects:
  #   The <receiver> is mutated to hold the new lines.
  #
  # See Also:
  #   - <below>
  #   - <new>

  def below!(addend)
    theBelow = TextRect.new(addend)
    @theLines.concat(theBelow.lines)
    return self
  end


  #----------------------------------------------------------------------------
  # Method: box
  # Put a "box" around a <TextRect> with an (optional) banner.
  #
  # Method <box> takes a <TextRect> receiver and creates a new <TextRect> that
  # has a "box" display around the lines of the original. An optional banner
  # line can appear immediately above the box.
  #
  # Formal Parameters:
  #   self   - a receiver <TextRect> to be boxed. The receiver is unchanged.
  #   banner - a *String* that will appear as a banner immediately above the
  #            boxed text. This argument may be *NIL* in which case no banner
  #            will appear.
  #
  # Value:
  #   A <TextRect> with the lines from the receiver boxed and possibly
  #   bannered.
  #
  # Examples:
  #   > A = TextRect.new("abc\ndef\nghikl") # => abc
  #   >                                          def
  #   >                                          ghikl
  #   > A.box('A banner') # => A banner
  #   >                        +=======+
  #   >                        | abc   |
  #   >                        | def   |
  #   >                        | ghikl |
  #   >                        +=======+
  #
  # See Also:
  #   - <box!>

  def box(banner = nil)
    theCopy = TextRect.new(self)
    return theCopy.box!(banner)
  end


  #----------------------------------------------------------------------------
  # Method: box!
  # Put a "box" around a <TextRect> with an (optional) banner.
  #
  # Method <box!> takes a <TextRect> receiver and creates a "box" display
  # around its lines. An optional banner line can appear immediately above the
  # box. The processing of arguments and construction of the value is the same
  # as the method <box>.  The mutated receiver is returned as value.  example
  #
  # Formal Parameters:
  #   self   - a receiver <TextRect> to be boxed. The receiver is mutated.
  #   banner - a *String* that will appear as a banner immediately above the
  #            boxed text. This argument may be *NIL* in which case no banner
  #            will appear.
  #
  # Value:
  #   The mutated receiver <TextRect> that has been boxed.
  #
  # Side Effects:
  #   The mutated <TextRect> is boxed with an optional banner.
  #
  # See Also:
  #   - <box>

  def box!(banner = nill)

    theEdge = self.genBar('=')
    theEdge.lPad!('+')
    theEdge.rPad!('==+')
    self.lPad!('| ')
    self.rPad!(' |')

    theBox = TextRect.new(banner)
    theBox.below!(theEdge)
    theBox.below!(self)
    @theLines = theBox.lines
    return self.below!(theEdge)

  end


  #----------------------------------------------------------------------------
  # Method: each
  # Iterate over the lines of a <TextRect>.
  #
  # Method <each> returns the lines of its <TextRect> receiver from the
  # first to the last in order. Obviously, if the receiver has no lines, the
  # iteration terminates immediately. Each iteration yields a *String*.
  #
  # Formal Parameters:
  #   self - a <TextRect> whose lines are to be returned.
  #
  # Yield:
  #   - A *String* that is a line of the receiver <TextRect>.
  #
  # See Also:
  #   - <lines>

  def each
    @theLines.each { |s| yield s }
  end


  #----------------------------------------------------------------------------
  # Method: genBar
  # Make a "bar" to fit over a <TextRect>.
  #
  # Method <genBar> creates a <TextRect> which contains a "bar" as long as the
  # width of its receiver <TextRect>. The "bar" is a single line of
  # repetitions of the supplied bar character; the default is the hyphen '-'.
  # 
  # Foraml Parameters:
  #   self -    a <TextRect> from which a bar will be created.
  #   barChar - a character that is repeated to generate the bar. If a *String*
  #             more than one character long is passed in, only the first 
  #             character is used. The default is a hyphen '-'. If the actual
  #             value is the empty (not *NIL*) *String*, the default value is 
  #             used.
  #
  # Value:
  #   A <TextRect> containing a single line. That line is as many repetitions
  #   of the bar character as the width of the receiver <TextRect>; if that
  #   width is zero, the empty (not *NIL*) <TextRect> is returned.
  #
  # Example:
  #   > A = TextRect.new(%w{ abc defgh ij klm }) # => abc
  #   >                                               defgh
  #   >                                               ij
  #   >                                               klm
  #
  #   > A.genBar('@*$') # => '@@@@@'

  def genBar(barChar = '-')
    barChar = '-' if barChar.length == 0
    theWidth = self.width
    TextRect.new(theWidth == 0 ? '' : String.new(barChar[0])*theWidth)
  end


  #----------------------------------------------------------------------------
  # Method: join
  # Join two <TextRects> side by side.
  #
  # Method <join> adds the lines from the addend to the right of the
  # lines in the receiver <TextRect> and returns the result as an entirely new
  # <TextRect>. Before the addition, all the lines in the left <TextRect> that
  # will have a line suffixed are padded to the length of the widest line
  # using the supplied padding character (defaulted to blank). If there are
  # more lines in the addend than in the receiver, the receiver has enough
  # lines (of the repeated padding character) added to make up the difference.
  # If the supplied separator is not *NIL*, it will be placed after each left
  # line before the join that has a addend line appended.  The receiver is
  # unharmed; a copy is made to ensure this and to become the value of the
  # operation.
  #
  # Formal Parameter:
  #   self      - a <TextRect> whose lines will be suffixed by those of the
  #               addend; this <TextRect> will not be modified.
  #   addend    - the lines to be added. If this is not a <TextRect>, a new
  #               <TextRect> will be created from the argument to supply the
  #               necessary lines.
  #   padChar   - a character to be used as padding (if any is necessary).
  #               Only the first character of the supplied *String* will be
  #               used. If *NIL* is supplied, blank will be used.
  #   separator - a *String* that will appear after each addend line. This
  #               value may be *NIL*.
  #
  # Value:
  #   - A new <TextRect> with the lines of the receiver <TextRect>. Each line
  #     will be suffixed (after padding and separation) with the corresponding
  #     line of the addend <TextRect>.
  #
  # Notes:
  #   - If the addend is not a <TextRect>, it will be turned into a <TextRect>
  #     following the rules for <TextRect> <new>.
  #   - Lines at the bottom of the left addend will not be padded if there is
  #     no addend nor separator to suffix to them.
  #
  # See Also:
  #   - <join!>
  #   - <new>

  def join(addend, padChar=' ', separator = nil)
    theCopy = TextRect.new(@theLines)
    theCopy.join!(addend, padChar, separator)
  end

  
  #----------------------------------------------------------------------------
  # Method: join!
  # Join two <TextRects> side by side.
  # 
  # Method <join!> has the same description as <join> except that it replaces
  # the receiver <TextRect> with the result. In effect, the addend lines are
  # appended to the receiver lines.
  #
  # Value:
  #   - The modified receiver <TextRect>.
  #
  # Effect:
  #   - The receiver <TextRect> is modified to be the result described by
  #     method <join>
  #
  # See Also:
  #   - <join>

  def join!(addend, padChar = ' ', separator = nil)

    # Make the addend into a TextRect.

    return self if addend.nil?

    case addend
      when String   then right = TextRect.new(addend)
      when Array    then right = TextRect.new(addend)
      when TextRect then right = addend
      else raise 'join! addend has unknown class.'      
    end

    # If either the right or the left is empty, do the trival thing.

    rLen = right.length
    return self if rLen == 0

    sLen = @theLines.length
    if sLen == 0
      right.lines.each { |l| @theLines << l }
      return self
    end

    # If the left operand must be extended, do it now.

    (sLen+1).upto(rLen) { @theLines << '' }

    # Pad the left side if necesary. We only need to pad the strings up to as
    # far as there are right operand lines; the remainder can be ignored. Once
    # the pad is in place, add the right string.

    sWidth    = self.width
    thePad    = padChar[0]
    rLines    = right.lines
    separator = '' if separator.nil?
    
    0.upto(rLen-1) do |i|
      @theLines[i] = @theLines[i].ljust(sWidth, thePad)
      @theLines[i] << separator << rLines[i]
    end

    return self

  end


  #----------------------------------------------------------------------------
  # Method: lines
  # The lines of a <TextRect> as an *Array*
  #
  # Method <lines> returns the lines of a <TextRect> as an *Array*.  Each
  # *Array) element is a *String*; there are no returns.  If the <TextRect> is
  # empty, the *Array* will be as well. The *Array* is a copy; it can be 
  # modified without affecting the <TextRect>.
  #
  # Formal Parameters:
  #   self - a <TextRect> whose lines are to be returned.
  #
  # Value:
  #   An *Array* of *String*s. The *Array* is in the same order as the lines
  #   in the <TextRect> and each <String> is a copy.
  #
  # See Also:
  #   - <each>

  def lines
    result = Array.new
    @theLines.each { |l| result << String.new(l) }
    return result
  end


  #----------------------------------------------------------------------------
  # Method: lPad
  # Pad a <TextRect> on the left side.
  # 
  # Method <lPad> adds a padding *String* to the left of each line of a
  # <TextRect>.
  #
  # Formal Parameters:
  #   self   - a receiver <TextRect> to be prefixed.
  #   thePad - a *String* to be prefixed to each line of the <TextRect>. If no
  #            *String* is supplied, the empty (not *NIL*) *String* is used.
  #
  # Value:
  #    A new <TextRect> such that each line is the corresponding line of the
  #    receiver with the padding *String* prefixed.
  #
  # Example:
  #   >  A = TextRect.new("abc\ndef\nghikl") # => abc
  #   >                                           def
  #   >                                           ghikl
  #
  #   > A.lpad('**') # => **abc
  #   >                   **def
  #   >                   **ghikl
  #
  # See Also:
  #   - <lPad!>
  #   - <rPad>
  #   - <rPad!>

  def lPad(thePad = '')
    theCopy = TextRect.new(@theLines)
    theCopy.lPad!(thePad)
  end


  #----------------------------------------------------------------------------
  # Method: lpad!
  # Pad a <TextRect> on the left side.
  # 
  # Method <lPad> adds a padding *String* to the left of each line of a
  # <TextRect>.
  #
  # Formal Parameters:
  #   self   - a receiver <TextRect> to be prefixed.
  #   thePad - a *String* to be prefixed to each line of the <TextRect>. If no
  #            *String* is supplied, the empty (not *NIL*) *String* is used.
  #
  #
  # Value:
  #   The receiver <TextRect> with the *String* prefixed.
  #
  # Side Effect:
  #   The receiver <TextRect> is modified in place.
  #
  # See Also:
  #   - <lPad>
  #   - <rPad>
  #   - <rPad!>

  def lPad!(thePad = '')
    @theLines.collect! { |l| thePad + l }
    return self
  end


  #----------------------------------------------------------------------------
  # Method: rPad
  # Pad a <TextRect> on the right side.
  #
  # Method <rPad> suffixes each line of a <TextRect> with a padding
  # *String*. If a padding *String( is not provided, the empty (not *NIL*)
  # String is used. The <TextRect>lines are extended to the width of the
  # <TextRect> before the padding is applied.
  #
  # Formal Parameters:
  #   self   - the receiver <TextRect> whose lines are to be right padded.
  #   thePad - a *String* to be added to every line of the <TextRect>. If no
  #            *String* is provided, the empty (not *NIL*) *String* is the
  #            default.
  #
  # Value:
  #   A <TextRect> with the lines of the receiver each suffixed (after length
  #   extension) with the padding *String*.
  #
  # Example:
  #   > A = TextRect.new("abc\ndef\nghikl") # => abc
  #   >                                          def
  #   >                                          ghikl
  #
  #   > A.rPad('**') # => abc  **
  #   >                   def  **
  #   >                   ghikl**
  #
  # Notes:
  #   - A empty (not *NIL*) padding *String* has the effect of making all the
  #     lines of the value be the same length by padding them on the right 
  #     with blanks.
  #
  # See Also:
  #   - <rPad!>
  #   - <lPad>
  #   - <lPad!>
  #   - <join>
  #   - <join!>

  def rPad(thePad = '')
    theCopy = TextRect.new(@theLines)
    theCopy.rPad!(thePad)
  end


  #----------------------------------------------------------------------------
  # Method: rPad!
  # Pad a <TextRect> on the right side.
  #
  # Method <rPad!> suffixes each line of a <TextRect> with a padding
  # *String*. If a padding *String( is not provided, the empty (not *NIL*)
  # String is used. The <TextRect>lines are extended to the width of the
  # <TextRect> before the padding is applied.
  #
  # Formal Parameters:
  #   self   - the receiver <TextRect> whose lines are to be right padded.
  #   thePad - a *String* to be added to every line of the <TextRect>. If no
  #            *String* is provided, the empty (not *NIL*) *String* is the
  #            default.
  #
  # Value: 
  #   The receiver <TextRect> with its lines padded on the right.
  #
  # Side Effects:
  #   The receiver <TextRect> has its lines padded on the right.
  #
  # See Also:
  #   - <rPad>
  #   - <lPad>
  #   - <lPad!>
  #   - <join>
  #   - <join!>

  def rPad!(thePad = '')
    len      = @theLines.length
    padArray = Array.new(len, thePad)
    padTR    = TextRect.new(padArray)
    self.join!(padTR)
  end


  #----------------------------------------------------------------------------
  # Method: to_s
  # Convert a <TextRect> to a *String*.
  #
  # Method <to_s> converts a <TextRect> into a single *String*. The *String*
  # contains all the lines of the receiver <TextRect>, each terminated by a
  # return. If there are no lines in the <TextRect>, the value will be the
  # empty (not *NIL*) *String*.
  #
  # Formal Parameters:
  #   self - a <TextRect> whose lines will be used to build a *String*.
  #
  # Value:
  #   A *String* formed by the catenation of the lines of the <TextRect>. Each
  #   line will be terminated with a return.
  #
  # Example:
  #   > A = TextRect.new(%w{ abc defgh ij klm }) # => abc
  #   >                                               defgh
  #   >                                               ij
  #   >                                               klm
  #
  #   > A.to_s # => "abc\ndefgh\nij\nklm\n"

  def to_s
    result = ''
    @theLines.each { |s| result << s << "\n" }
    return result
  end


  #----------------------------------------------------------------------------
  # Method: length
  # The number of lines in a <TextRect>.
  #
  # Method <length> returns the number of lines in a <TextRect>. The value is
  # zero if the <TextRect> is empty.
  #
  # Formal Parameters:
  #   self - the receiver <TextRect> whose length is to be found.
  #
  # Value:
  #   The number of lines in the <TextRect>.
  #
  # See Also:
  #   - <width>

  def length
    return nil if self.nil?
    return @theLines.length
  end


  #----------------------------------------------------------------------------
  # Method: width
  # The length of the longest line in a <TextRect>.
  #
  # Method <width> returns the length of the longest line of a <TextRect>. This
  # is zero if the <TextRect> is empty.
  #
  # Formal Parameters:
  #   self - the receiver <TextRect> whose width is to be found.
  #
  # Value:
  #   The length of the longest line in the receiver <TextRect>.
  #
  # Note: 
  #   - The length of a line is found by treating it as a *String*.
  #
  # See Also:
  #   - <length>

  def width
    theWidth = 0
    @theLines.each { |l| theWidth = l.length if l.length > theWidth }
    theWidth
  end


  #----------------------------------------------------------------------------
  # Method: number
  # Prefix a <TextRect> with line numbers.
  #
  # Method <number> prefixes each line of a <TextRect> with a number, a
  # separator, and a space.  If a separator is not provided, a period '.' is
  # used by default. The numbering is right justified. The prefixes are
  # adjusted so that the separators align vertically. The separator *String*
  # is not limited to a single character. An empty *String* will default to
  # a period.
  #
  # Formal Parameters:
  #   self   - a receiver <TextRect> whose lines are to be numbered.
  #   theDot - a separator for the number field. It defaults to a period '.'.
  #
  # Value:
  #   A <TextRect> with the lines of the receiver <TextRect> numbered.
  #
  # Example:
  #   > A = TextRect.new(%w{one two three ... onehundred}) # => one
  #   >                                                         two
  #   >                                                         three
  #   >                                                          ...
  #   >                                                         onehundred
  #
  #   > A.number('|') # =>   1| one
  #   >                      2| two
  #   >                      3| three
  #   >                        ...
  #   >                    100| onehundred
  #
  # Notes:
  #   - The numbering starts from 1 and runs to the length of the <TextRect>.
  #     An empty <TextRect> will return an empty <TextRect>.
  #
  # See Also:
  #   - <number!>

  def number(theDot = '.')
    theCopy = TextRect.new(@theLines)
    theCopy.number!(theDot)
  end


  #----------------------------------------------------------------------------
  # Method: number!
   # Prefix a <TextRect> with line numbers.
  #
  # Method <number!> prefixes each line of a <TextRect> with a number, a
  # separator, and a space.  If a separator is not provided, a period '.' is
  # used by default. The numbering is right justified. The prefixes are
  # adjusted so that the separators align vertically. The separator *String*
  # is not limited to a single character. An empty *String* will default to
  # a period.
  #
  # Formal Parameters:
  #   self   - a receiver <TextRect> whose lines are to be numbered.
  #   theDot - a separator for the number field. It defaults to a period '.'.
  #
  # Value:
  #   The numbered receiver <TextRect>.
  #
  # Side Effects:
  #   The receiver <TextRect> has every line prefixed with a number.
  #
  # See Also:
  #   - <number>

  def number!(theDot = '.')
    theDot = '.' if theDot.length == 0
    theDot = theDot.delete("\n")
    l      = @theLines.length
    nums   = Array.new
    1.upto(l) { |i| nums << sprintf('%d%s ', i, theDot) }
    w = nums[l-1].length
    nums.each_index { |i| nums[i] = nums[i].rjust(w) +  @theLines[i] }
    @theLines = nums
    return self
  end


  #----------------------------------------------------------------------------
  # Method: columnate
  # Break <TextRect> lines into columns.
  #
  # Method <columnate> breaks a <TextRect's> lines into roughly equal columns
  # and pastes those together left to right with padding in between. The
  # number of columns is roughly defined by the desired width:
  #   > columns ~= theWidth/self.width
  # but is always at least one. The pad *String* is also is involved in the
  # width computation. The pad defaults to a space. If the <TextRect> cannot
  # form more than one column in the width, it is copied unchanged.
  #
  # Formal Parameters:
  #   self     - a receiver <TextRect> to be broken into columns
  #   theWidth - the maximum width of the result. If the receiver is so wide
  #              that more than one column would break this limit, the
  #              receiver is returned unchanged.
  #   thePad   - a padding *String* to put between the columns. The default is
  #              a blank ' '. The padding string may be longer than one
  #              character.
  #
  # Value:
  #   A <TextRect> with the receiver <TextRect's> lines columnated.
  #
  # See Also:
  #   - <columnate!>

  def columnate(theWidth, thePad = ' ')
    theCopy = TextRect.new(@theLines)
    return theCopy.columnate!(theWidth, thePad)
  end


  #----------------------------------------------------------------------------
  # Method: columnate!
  # Break <TextRect> lines into columns.
  #
  # Method <columnate!> breaks a <TextRect's> lines into roughly equal columns
  # and pastes those together left to right with padding in between. The
  # number of columns is roughly defined by the desired width:
  #   > columns ~= theWidth/self.width
  # but is always at least one. The pad *String* is also is involved in the
  # width computation. The pad defaults to a space. If the <TextRect> cannot
  # form more than one column in the width, it is returned unchanged.
  #
  # Formal Parameters:
  #   self     - a receiver <TextRect> to be broken into columns
  #   theWidth - the maximum width of the result. If the receiver is so wide
  #              that more than one column would break this limit, the
  #              receiver is returned unchanged.
  #   thePad   - a padding *String* to put between the columns. The default is
  #              a blank ' '. The padding string may be longer than one
  #              character.
  #
  # Value:
  #   The receiver <TextRect> with its lines columnated.
  #
  # Side Effects:
  #   The receiver <TextRect> with its lines columnated.
  #
  # See Also:
  #   - <columnate>

  def columnate!(theWidth, thePad = ' ')

    # Setup the basic sizes.

    trLen  = @theLines.length
    return self if trLen == 0
    thePad = '' if thePad.nil?
    pdWide = thePad.length
    trWide = self.width
    cols   = 1

    # If there is just no room to break at all, return now.

    return self if 2*trWide + pdWide > theWidth

    # At least two columns will fit. See how many more will.

    2.upto(theWidth) do |i|
      break if i*trWide + (i-1)*pdWide > theWidth
      cols = i
    end
    
    # Find the length of the basic columns. There may be some extra elements
    # beyond the allocation of the original. Pass them to the columns one by
    # one from left to right.

    baseLen = trLen.div(cols)
    theLens = Array.new(cols, baseLen)
    0.upto(trLen-cols*baseLen-1) { |i| theLens[i] = theLens[i] + 1 }

    # Now create an array of lines for each column.

    colArrays = Array.new(cols, Array.new)
    colStart  = 0
    0.upto(cols-1) do |i|
      colArrays[i] = @theLines[colStart, theLens[i]]
      colStart    += theLens[i]
    end

    # Readjust the current TR with the first column of lines.

    @theLines = colArrays[0]

    # Now for each of the other columns, join it to the existing TR using the
    # pad in between.

    1.upto(cols-1) do |i|
      theCol = TextRect.new(colArrays[i])
      theCol.lPad!(thePad) if pdWide > 0
      self.join!(theCol)
    end

    return self

  end


  #----------------------------------------------------------------------------
  # Method: fold
  # Fold <TextRect> lines to fit a particular width.
  #
  # Method <fold> revises the lines of a <TextRect> so that they are no longer
  # than some width. This is achieved by "folding" the lines at white
  # space. Of course, if a single "word" inside a line is longer than the
  # proposed width, then that word must live on an overlong line by itself.
  # The folding rules are
  #   - Whitespace at the end of any "folded" line will be dropped.
  #   - If the number argument is not *NIL*, it is assumed to be a starting
  #     number. The original lines are numbered and the folded sections are
  #     are aligned to the right of these numbers.
  #   - If the breaker argument is not *NIL*, it is inserted between the new
  #     columns of folded lines but not before or after the entire result.
  #
  # Formal Parameters:
  #   self    - the receiver <TextRect> to be folded.
  #   width   - the maximum length of a folded line. This width includes the 
  #             length of any numbering.
  #   number  - the starting number (an integer) for the numbering. If this is
  #             *NIL*, no numbering is done. The default is *NIL*.
  #   breaker - a *String* to place between the folded lines. The default is
  #             *NIL*.
  #
  # Value:
  #   A <TextRect> with the receiver <TextRect's> lines folded and possible
  #   numbered and broken.
  #
  # See Also:
  #   - <fold!>

  def fold(width, number = nil, breaker = nil)
    theCopy = TextRect.new(@theLines)
    theCopy.fold!(width, number, breaker)
  end


  #----------------------------------------------------------------------------
  # Method: fold!
  # Fold <TextRect> lines to fit a particular width.
  #
  # Method <fold!> revises the lines of a <TextRect> so that they are no longer
  # than some width. This is achieved by "folding" the lines at white
  # space. Of course, if a single "word" inside a line is longer than the
  # proposed width, then that word must live on an overlong line by itself.
  # The folding rules are
  #   - Whitespace at the end of any "folded" line will be dropped.
  #   - If the number argument is not *NIL*, it is assumed to be a starting
  #     number. The original lines are numbered and the folded sections are
  #     are aligned to the right of these numbers.
  #   - If the breaker argument is not *NIL*, it is inserted between the new
  #     columns of folded lines but not before or after the entire result.
  #
  # Formal Parameters:
  #   self    - the receiver <TextRect> to be folded.
  #   width   - the maximum length of a folded line. This width includes the 
  #             length of any numbering.
  #   number  - the starting number (an integer) for the numbering. If this is
  #             *NIL*, no numbering is done. The default is *NIL*.
  #   breaker - a *String* to place between the folded lines. The default is
  #             *NIL*.
  #
  # Value:
  #   The receiver <TextRect> with its lines folded.
  #
  # Side Effects:
  #   The receiver <TextRect> is modified in place.
  #
  # See Also:
  #   - <fold>

  def fold!(width, number = nil, breaker = nil)

    # If the TextRect has no lines, just return immediately.

    len = @theLines.length
    return self if len == 0

    # Create an array of line numbers. Make sure they are right adjusted.
    # When the array is complete, make up a left fill for those broken lines
    # that will not be copied. Also remember the length of the numbering
    # header.

    theNums = Array.new(len, '')

    if not number.nil? 
      0.upto(len-1) { |i| theNums[i] = "#{(i+number).to_s}. " }
      numWide = theNums.last.length
      theNums.collect! { |s| s.rjust(numWide) }
    end

    theFill = theNums.last.tr(theNums.last, ' ')
    numLen  = theNums.last.length

    # Now process the strings of the original TextRect one by one. The new
    # lines are collected into an initially empty Array. Each line from the
    # receiver is processed in turn.

    theRes = Array.new

    @theLines.each_index do |i|

      # Get a line from the receiver and split it into words. Set of an array
      # of replacement lines and initialize the first replacement line to 
      # be the number for the line followed by the first word and a space. 
      # Every working line will end with a space (to be removed later).

      theWords = @theLines[i].split
      newLines = Array.new
      newLine  = theNums[i] + theWords.delete_at(0) + ' '
      
      # In this loop, process each word in turn. Notice that as the line
      # already includes the first word and has a space at the end. If the line
      # cannot take one more word, take the trailing blank off, put it into
      # the accumulating array of new lines, and initialize the next new
      # line -- which must exist because there is a word pending -- with the
      # the left fill. Then, regardless of whether a line was saved, put the
      # word and a space at the end of the current line.

      theWords.each do |w|
        if newLine.length + w.length > width
          newLine.chomp!(' ')
          newLines << newLine
          newLine = String.new(theFill)
        end
        newLine << w << ' '
      end
      
      # All the words from this original line have been processed. Make sure
      # the last partial line gets into the array. Then put the folded lines
      # into the result. If this isn't the last line and the breaker isn't
      # NIL, put in a breaker line.

      newLines << newLine      
      theRes.concat(newLines)
      theRes << breaker unless breaker.nil? or i == @theLines.length - 1

    end

    @theLines = theRes

    return self

  end

end # TextRect

