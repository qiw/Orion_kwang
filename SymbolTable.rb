# Copyright (c) 2011, 2012, Oracle and/or its affiliates. All rights reserved. 

#==============================================================================
# Class: SymbolTable
# Symbol table segment for *Orion* RDBMS metadata.
#
# Class <SymbolTable> defines one segement of a tree-structured symbol table
# in which *Orion* maintains metadata about symbols in a *RDBMS* schema or
# database. Each <SymbolTable> object retains information about one *SQL* 
# scope. The scopes are linked into trees to reflect the lexical relationships
# between *SQL* statement elements.
#
# *SQL* statements contain both definitions of symbols (for example, column
# aliases are defined in SELECT statement selection lists) and uses of the 
# those symbols. In addition, the *RDBMS* environment also contains symbols
# (table names, view names, and so on) that are used within *SQL* statements.
# A complete symbol table (made of several <SymbolTable> objects) reflects the
# relationships of all these symbols one to another and to a statement itself.
#
# Notes:
#   - This section *URGENTLY* needs a description of a symbol table segment's
#     data, its theory of operation, its topology, and its connection to
#     *Orion* generation.
#   
#   - Why not use lower case symbols instead of upper case?


class SymbolTable

  require 'Configurator.rb'
  include Report
  include Utility


  #============================================================================
  # Section: Class Attributes

  #----------------------------------------------------------------------------
  # Variable: @@universe
  # The top <SymbolTable> segment with the outside world's data.
  #
  # Variable <@@universe> is a <SymbolTable> segment that contains the 
  # description of the outside world. It is initialized to *nil* and then
  # is filled when the first new segment is created. Each <SymbolTable>
  # segment contains a reference to this value.
  #
  # NOTES: 
  #   - Is the reference in each segment really necessary? Why not just
  #     reference the class attribute directly?

  @@universe = nil


  #----------------------------------------------------------------------------
  # Variable: @@bigBM
  # A global search structure for <SymbolTable> segments.
  #
  # Variable <@@bigBM> is class attribute holding keys for the external
  # metadata structure. This is a convenience structure to to avoid rescanning
  # <@@universe> again and again whenever a random pick of an object of a
  # predefined type is required. For example, whenever <addTable> is called,
  # it picks a symbol randomly from @@bigBM[:TABLES] and then uses that
  # randomly picked symbol to access an element of <@@universe> directly.
  #
  # <@@bigBM> is implemented as a *Hash*. Each key names a kind of *SQL* 
  # metadata object and the associated value is an *Array* of <@@universe>
  # items of that kind. Thus, the setup looks like this:
  #
  #   > { :TABLE =>    [ ... tables ...             ],
  #   >   :MVIEW =>    [ ... materialized views ... ],
  #   >   :VIEW  =>    [ ... views ...              ],
  #   >   :SEQUENCE => [ ... sequences ...          ],
  #   > }
  #
  # <@@bigBM> starts *nil* and is initialized by the first <SymbolTable>
  # segment only if metadata can actuall be read.
  #
  # Notes:
  #   - Why are the names of the kinds all capitals? The normal Ruby convention
  #     is for leading lowercase, at least, particularly for symbols.
  #   - Why are the category names prewired? Why can't they be discovered from
  #     the metadata itself? This might lead to a generic *addItem* method that
  #     took the kind of the item as a argument rather than having a different
  #     method for each *SQL* category.

  @@bigBM = nil


  #----------------------------------------------------------------------------
  # Variable: @@qbSerial
  # A serial counter for *SQL* query blocks encountered.
  #
  # Variable <@@qbSerial> is a serial counter for *SQL* query blocks (and other
  # *SQL environments?) that have been encountered by this <SymbolTable>
  # family. The counter starts at zero is only goes upward. It is used to 
  # create sensible, distinct segment names for human consumption.

  @@qbSerial = 0


  #----------------------------------------------------------------------------
  # Variable: @@fakeNum
  # Serial counter for generation of "faked" names.
  #
  # Variable <@@fakeNum> is a serial counter for the generation of "faked"
  # names. It is incremented every time a new name is generated to insure that
  # "faked" names never recur.

  @@fakeNum = 0


  #============================================================================
  # Section: Object Attributes And Accessors

  #----------------------------------------------------------------------------
  # Variables: Object attributes
  # <SymbolTable> attributes and their accessors.
  #
  #   @bitmap   - a local map of current segment's symbol table in human
  #               readable format. <@bitmap> is a subset of <@universe>
  #               selected as a query tree is generated.
  #   @child    - a pointer to child segments.
  #   @coltab   - hash of selected columns and corresponding tables
  #               {COL1 => [TAB1, TAB2, TAB3], ...}. <@coltab> resolves
  #               ambiguites between equally named columns/column aliases and
  #               helps to detect a situation when an autogenerated column
  #               alias is semantically required.
  #   @name     - a human readable name for the segment.
  #   @parent   - parent <SymbolTable> segment for this segment.
  #   @symtab   - a current segment's symbol table in human readable format.
  #   @universe - the universe <SymbolTable> segment for this segment.

  attr_accessor :symtab
  attr_accessor :coltab
  attr_accessor :parent
  attr_accessor :child
  attr_accessor :name
  attr_accessor :universe
  attr_accessor :bitmap


  #============================================================================
  # Section: Class Methods


  #============================================================================
  # Section: Object Methods

  #----------------------------------------------------------------------------
  # Method: initialize
  # Populate a new <SymbolTable>.
  #
  # Method <initialize> populates the attributes of a new <SymbolTable>
  # segment. It can be initialized with a configuration, a parent, and a child.
  #
  # Formal Parameters:
  #   config - a configuration value. (Default: *nil*).
  #   parent - the parent <SymbolTable> segment for this segment.
  #            (Default: *nil*).
  #   child  - a child <SymbolTable> segment for this segment.
  #             (Default: *nil*).
  #
  # Value:
  #   A new <SymbolTable>.
  #
  # Effects:
  #   If the class does not have its <@@universe> attribute set, this method
  #   will try to create a new segment for it.

  def initialize(config = nil, parent = nil, child = nil)

    # Kick the serial counter; we're making a new segment.

    @@qbSerial += 1

    # If the universe hasn't been created, do that now. The name of a file for
    # the symbol table lives in the configuration. That name must not be nil
    # and the file itself must exist. The file itself contains a text
    # representation of the metadata that can be eval-ed into a Ruby object.
    # The result of that evaluation becomes @@universe.

    if @@universe.nil?
      errorExit('Configuration nil for SymbolTable.') if config.nil?
      mdName = config.value(:symTab)
      errorExit('No metadata file |%s|' % mdName) unless File.exist?(mdName)
      mdFile = File.new(mdName)
      mdText = mdFile.read
      mdFile.close
      @@universe = eval(mdText)
    end

    # Now we set up the convenience universe map if necessary. The map starts
    # empty. Then we walk through the universe and pull out each item, one
    # by one. The key in each case will be name of something and the value
    # will be a tag that can be turned into a symbol.

    if @@bigBM.nil?
      @@bigBM = { TABLE: [], MVIEW: [], VIEW: [], SEQUENCE: [] }
      @@universe.each do |key, value|
        valueSym = value[:TYPE].to_sym
        next unless [:TABLE, :MVIEW, :VIEW, :SEQUENCE ].find_index(valueSym)
        @@bigBM[valueSym].push(key)
      end
    end

    # Now set all the object attributes of this segment.

    @name     = 'QB%d' % @@qbSerial
    @parent   = parent
    @child    = child
    @symtab   = Hash.new
    @coltab   = Hash.new
    @flags    = Set.new
    @universe = @@universe
    @bitmap   = @@bigBM

    addInlineSource(parent) unless parent.nil?

  end # initialize


  #----------------------------------------------------------------------------
  # Method: addColumnAlias
  # Return alias for column.
  #
  # Method <addColumnAlias> builds and returns a column alias for a column.
  #
  # Formal Parameters:
  #   colName     - the name of a column.
  #   sourceAlias - the alias of the source of the column.
  #
  # Value:
  #   A *Hash*
  #     > { :SCHEMA => schema_name,
  #     >   :NAME   => row_source_name,
  #     >   :ALIAS  => row_source_alias,
  #     >   :CNAME  => column_name,
  #     >   :CALIAS => column_alias
  #     > }
  #
  # Notes:
  #   - There was a comment describing a usage scenario for this method, but 
  #     not what it does. The effects of the method need to be described.
  #   - Is there a guarantee that the loop will actually find the sourceAlias?
  #   - If the loop will always find an entry, the code can be further
  #     simplified.

  def addColumnAlias(colName, sourceAlias)

    # If we don't know about the column name, there is nothing interesting
    # to return.

    return { SCHEMA: nil,
             NAME:   nil,
             ALIAS:  nil,
             CNAME:  nil,
             CALIAS: nil,
           } unless @coltab.has_key?(colName)

    # When we register a column in the @coltab structure, we almost always
    # already have an alias for that column except when the alias and the name
    # are the same.  Therefore, whenever we find an entry for sourceAlias in a
    # slot with key colName, we check explicitly if column alias in that entry
    # is the same as physical name of the column.  If that's the case, then we
    # make an alias up; otherwise we reuse an alias which is already there.

    entry     = @coltab[colName]
    oldKey    = nil
    colAlias  = nil
    tabAlias  = nil
    tabSchema = nil
    tabName   = nil

    entry.each do |key, value|

      next unless value == sourceAlias

      if key == colName
        colAlias = fakeName(entry.keys.max.to_s)
        oldKey = key
      else
        colAlias = key
      end

      tabAlias  = value
      tabSchema = @symtab[tabAlias][:SCHEMA]
      tabName   = @symtab[tabAlias][:NAME]
      break

    end
      
    entry[colAlias] = entry.delete(oldKey)

    # Now return what we found.

    { SCHEMA: tabSchema,
      NAME:   tabName, 
      ALIAS:  tabAlias, 
      CNAME:  colAlias.nil? ? nil : colName, 
      CALIAS: colAlias,
    }

  end


  #----------------------------------------------------------------------------
  # Method: addInlineSource
  # Link one <SymbolTable> to another.
  #
  # Method <addInlineSource> has a very unclear definition and use.
  #
  # Add a reference to another symbol table (usually for another query block).
  # There are two types of inline sources: parent and child. Typically PARENT
  # inline view is added automatically via initialize() constructor method
  # whenever input parameter parent is not nil. CHILD inline source is
  # typically created after parent's call for child symtab returned a
  # reference to it.
  #
  # Formal Parameters:
  #   source - ???
  #   type   - ???
  #
  # Value:
  #   A *Hash*
  #     > { :SCHEMA => nil, 
  #     >   :NAME   => inline_view_orig_alias,
  #     >   :ALIAS  => inline_view_alias,
  #     >   :TYPE   => "PARENT"|"CHILD",
  #     > }
  #
  # Effects:
  #   The <SymbolTable> segment is modified.

  def addInlineSource(source = @parent, type = :PARENT)

    name                    = source.name
    @symtab[name]           = {}
    @symtab[name][:ALIAS]   = name
    @symtab[name][:NAME]    = name
    @symtab[name][:TYPE]    = type == :PARENT ? 'PARENT' : 'CHILD'
    @symtab[name][:COLUMNS] = source.coltab.method(:keys)
        
    return { SCHEMA: nil, NAME: name, ALIAS: name, TYPE: type.to_s }

  end # addInlineSource


  #----------------------------------------------------------------------------
  # Method: addMView
  # Add a random *SQL* materialized view into this <SymbolTable>
  #
  # Method <addMView> is a wrapper around <addPhysicalSource>. It finds a
  # random materialized view from the universe, finds an alias for that
  # materialized view, and inserts the materialized view into the local
  # <SymbolTable> segment appropriately. The value is a *Hash* describing the
  # materialized view selected.
  #
  # Value:
  #   A description of a random table as a *HASH*; the contents are
  #     > { :SCHEMA => schema_name,
  #     >   :NAME   => row_source_name,
  #     >   :ALIAS  => row_source_alias,
  #     >   :TYPE   -> row_source_type,
  #     > }
  #
  # Effects:
  #   The <SymbolTable> segment has an entry for this materialized view added.
  #
  # See:
  #   - <addPhysicalSource>
  #   - <getMView>

  def addMView
    addPhysicalSource(:MVIEW)
  end # addMView


  #----------------------------------------------------------------------------
  # Method: addSequence
  # Add a random *SQL* sequence into this <SymbolTable>
  #
  # Method <addSequence> is a wrapper around <addPhysicalSource>. It finds a
  # random sequence from the universe, finds an alias for that sequence, and
  # inserts the sequence into the local <SymbolTable> segment
  # appropriately. The value is a *Hash* describing the sequence selected.
  #
  # Value:
  #   A description of a random table as a *HASH*; the contents are
  #     > { :SCHEMA => schema_name,
  #     >   :NAME   => row_source_name,
  #     >   :ALIAS  => row_source_alias,
  #     >   :TYPE   -> row_source_type,
  #     > }
  #
  # Effects:
  #   The <SymbolTable> segment has an entry for this sequence added.
  #
  # See:
  #   - <addPhysicalSource>
  #   - <getSequence>

  def addSequence
    addPhysicalSource(:SEQUENCE)
  end # addSequence


  #----------------------------------------------------------------------------
  # Method: addSourceAlias
  # Return an alias for a table with an existing alias.
  #
  # Method <addSourceAlias> takes a purported table alias and returns
  # information about that alias. There are three cases to consider:
  #   - the input is an existing alias for a table. Then the value is simply
  #     information about that alias.
  #   - the input is the name (not the alias) of an existing table. The table
  #     is provided (if necessary) with an alias and the alias information is
  #     returned.
  #   - the input is neither an alias nor a name of a table. In this case, 
  #     essentially *nil* information is returned.
  # In each case, the search is in the present <SymbolTable> segment.
  #
  # As illogical as it may sound to pass an alias to get an alias, 
  # it actually makes some sense if one recalls that
  #   - a row source's alias is a primary discriminator between row sources
  #     which have been used in a query block more than once.
  #   - until the same row source is pulled into a query block for the second
  #     time, its alias will be equal to its name.
  #   - the <SymbolTable> class has no control on the AST shape being 
  #     generated. Therefore, when asked for an alias, it silently assumes
  #     that the AST representer knows what is happening and is happy to serve
  #     a (semantically) meaningful alias.
  #
  # Formal Parameters:
  #   tAlias - a *String* providing a table alias (possibly a table name).
  #
  # Value:
  #   A description of a table alias as a *Hash*.
  #     > { :SCHEMA => row_source_schema,
  #     >   :NAME   => row_source_name,
  #     >   :ALIAS  => row_source_alias,
  #     >   :TYPE   => row_source_type,
  #     > }
  #
  # Notes:
  #   - If the input is faulty, a "faked" alias name is generated and all the
  #     other return information is *nil*; that is, the field values are *nil*.

  def addSourceAlias(tAlias)

    # If the alias isn't in the symbol table, then return essentially NIL
    # information with a faked alias name.

    return { SCHEMA: nil,
             NAME:   nil,
             ALIAS:  fakeName('UNKNOWN_ALIAS'),
             TYPE:   nil,
           } unless @symtab.has_key?(tAlias) 

    # The name is in the table. If it turns out to be a table name, generate
    # an alias that isn't already there. 

    newAlias = tAlias

    if @symtab[tAlias][:ALIAS] == @symtab[tAlias][:NAME]
      newAlias = fakeName(newAlias) if @symtab.has_key?(newAlias)
      @symtab[newAlias]         = @symtab.delete(tAlias)
      @symtab[newAlias][:ALIAS] = newAlias
      syncMetadata(tAlias, newAlias)
    end     

    # Now all the parts are available to return for the caller

    { SCHEMA: @symtab[newAlias][:SCHEMA],
      NAME:   @symtab[newAlias][:NAME],
      ALIAS:  newAlias,
      TYPE:   @symtab[newAlias][:TYPE],
    }

  end # addSourceAlias


  #----------------------------------------------------------------------------
  # Method: addSourceColumn
  # Register a row source column in a <SymbolTable> segment.
  #
  # Method <addSourceColumn> registers a row source's column in the <@coltab>
  # structure and returns its name (along with other potentially useful
  # information). 
  #
  # The method chooses a random column from the row source. The row source
  # alias is either supplied by an optional input parameter or picked up
  # randomly from the <@symtab> structure. As the column is entered into the
  # <@coltab>, a potential conflict of names is resolved automatically (via
  # private method <addColToColtab>) and an alias is created if required.
  #
  # Formal Parameters:
  #   sourceAlias - the name of a row source (default *nil*).
  #
  # Value:
  #   A *Hash*.
  #     > { :SCHEMA => schema, 
  #     >   :NAME   => row_source_name,
  #     >   :ALIAS  => row_source_alias, 
  #     >   :CNAME  => column_name,
  #     >   :CALIAS => column_alias,
  #     > }

  def addSourceColumn(sourceAlias = nil)

    # Use the row source alias supplied by the input parameter; otherwise
    # choose one randomly.

    tabkey = sourceAlias || choose(@symtab.keys)

    # If that row source doesn't meet the necessary conditions, return some
    # essentially NIL information. Notice the use of internal assignments in
    # the returned Hash to make sure the pairs of fields get the same value.

    hasT = @symtab.has_key?(tabkey) and @symtab[tabkey].has_key?(:COLUMNS)
    hasC = ! (columns(@symtab[tabkey])).empty?
    isOK = hasT && hasC

    return { SCHEMA: nil,
             NAME:   hasT ? @symtab[tabkey][:NAME] : fakeName('UNKNOWN'),
             ALIAS:  fn = fakeName(hasT ? @symtab[tabkey][:NAME] : 'UNKNOWN'),
             CNAME:  fc = fakeName('UNKNOWN_COLUMN'),
             CALIAS: fc,
           } unless isOK

    # This part handles columns that belong to locally declared dictionary
    # sources.

    colkey = choose(columns(@symtab[tabkey]))

    return { SCHEMA: @symtab[tabkey][:SCHEMA],
             NAME:   @symtab[tabkey][:NAME], 
             ALIAS:  tabkey,
             CNAME:  colkey,
             CALIAS: addColToColtab(colkey, @symtab[tabkey][:ALIAS]),
           } unless %w( PARENT, CHILD ).find_index(@symtab[tabkey][:TYPE])

    # Here we take care of inline query blocks. An address of the inline view
    # is stored in :COLUMNS key of the specific @symtab slot. A column from
    # the qb's @coltab is picked up and stored in current @coltab along with
    # referred qb's alias.
    #
    # iv_metadata structure: [column_name, column_alias, source_alias]

    #inview      = columns(@symtab[tabkey])
    #iv_metadata = inview.getSourceColumn
    #colalias    = addColToColtab(iv_metadata[:CNAME], inview.name)
    
    #return { SCHEMA: nil, 
    #         NAME:   colalias ? inview.name : nil,
    #         ALIAS:  iv_metadata[:ALIAS],
    #         CNAME:  iv_metadata[:CNAME],
    #         CALIAS: colalias,
    #       }
    return { SCHEMA: nil,
             NAME:   tabkey, 
             ALIAS:  @symtab[tabkey][:ALIAS],
             CNAME:  choose(columns(@symtab[tabkey])),
             CALIAS: addColToColtab(colkey, @symtab[tabkey][:ALIAS]),
           } 

  end # addSourceColumn


  #----------------------------------------------------------------------------
  # Method: addTable
  # Add a random *SQL* table into this <SymbolTable>.
  #
  # Method <addTable> is a wrapper around <addPhysicalSource>. It finds a
  # random table from the universe, finds an alias for that table, and inserts
  # the table into the local <SymbolTable> segment appropriately. The value
  # is a *Hash* describing the table selected.
  #
  # Value:
  #   A description of a random table as a *HASH*; the contents are
  #     > { :SCHEMA => schema_name,
  #     >   :NAME   => row_source_name,
  #     >   :ALIAS  => row_source_alias,
  #     >   :TYPE   -> row_source_type,
  #     > }
  #
  # Effects:
  #   The <SymbolTable> segment has an entry for this table added.
  #
  # See:
  #   - <addPhysicalSource>
  #   - <getTable>

  def addTable
    addPhysicalSource(:TABLE)
  end # addTable


  #----------------------------------------------------------------------------
  # Method: addView
  # Add a random *SQL* view into this <SymbolTable>
  #
  # Method <addView> is a wrapper around <addPhysicalSource>. It finds a
  # random view from the universe, finds an alias for that view, and inserts
  # the view into the local <SymbolTable> segment appropriately. The value is
  # a *Hash* describing the view selected.
  #
  # Value:
  #   A description of a random table as a *HASH*; the contents are
  #     > { :SCHEMA => schema_name,
  #     >   :NAME   => row_source_name,
  #     >   :ALIAS  => row_source_alias,
  #     >   :TYPE   -> row_source_type,
  #     > }
  #
  # Effects:
  #   The <SymbolTable> segment has an entry for this view added.
  #
  # See:
  #   - <addPhysicalSource>
  #   - <getView>

  def addView
    addPhysicalSource(:VIEW)
  end # addView


  #----------------------------------------------------------------------------
  # Method: getMView
  # Retrieve a *SQL* materialized view.
  #
  # Method <getMView> retrieves a materialized view description from the
  # <SymbolTable> segment and returns it as a *Hash* given the name of the
  # materialized view.
  #
  # Formal Parameters:
  #   name - the *String* name of the materialized view to be retrieved.
  #
  # Value:
  #   A *Hash* describing the materialized view:
  #    > { :SCHEMA => schema_name,
  #    >   :NAME   => materialized_view_name,
  #    >   :ALIAS  => materialized_view_alias,
  #    >   :TYPE   => 'MVIEW',
  #    > }
  #
  # See:
  #   - <getPhysicalSource>
  #   - <addMView>

  def getMView(name)
    getPhysicalSource(name, 'MVIEW')
  end # getView


  #----------------------------------------------------------------------------
  # Method: getSourceColAlias
  # Find the metadata for a column.
  #
  # Method <getSourceColAlias> returns the metadata for a column belonging to a
  # particular row source whose alias is provided.
  #
  # Formal Parameters:
  #   colName     - the name of the column.
  #   sourceAlias - the row source alias.
  #
  # Value:
  #   A *Hash*.
  #     > { :SCHEMA => schema_name,
  #     >   :NAME   => source_name,
  #     >   :ALIAS  => source_alias,
  #     >   :CNAME  => column_name,
  #     >   :ALIAS  => column_alias
  #     > }
  #
  # Notes:
  #   - What happens in the real computation if t_alias turns out to be null?

  def getSourceColAlias(colName, sourceAlias)

    # If there isn't any information about the column, return essentially
    # nothing right away.

    return { SCHEMA: nil,
             NAME:   nil,
             ALIAS:  nil,
             CNAME:  nil,
             CALIAS: nil,
           } if @coltab[colName].keys.size == 0

    candidates = Array.new
    @coltab[colName].each {|k, v| candidates.push([k, v]) if v == sourceAlias}
    
    t_alias, c_alias = nil
    c_alias, t_alias = choose(candidates)[0..1] unless candidates.size == 0
    t_schema = @symtab.has_key?(t_alias) ? @symtab[t_alias][:SCHEMA] : nil
    t_name   = @symtab.has_key?(t_alias) ? @symtab[t_alias][:NAME]   : nil

    { SCHEMA: t_schema, 
      NAME:   t_name, 
      ALIAS:  t_alias,
      CNAME:  t_alias ? colName : nil,
      CALIAS: c_alias,
    }

  end # getSourceColAlias


  #----------------------------------------------------------------------------
  # Method: getSourceColumn
  # Find metadata for a column.
  #
  # Method <getSourceColumn> returns metadata related to a source column. The
  # metadata is selected at random from <@coltab> if no source alias is
  # supplied or picked randomly for a set of column aliases related to a
  # source alias that is supplied. If <@coltab> is empty, essentially a set of
  # *nil* values is returned.
  # 
  # Notice that the same column may in principle have multiple aliases related
  # to the same row source alias; consider
  #   > (SELECT A1.C1 AS Y1, A1.C1 AS Y2 FROM T1 A1)
  #
  # Value:
  #   A *Hash*.
  #     > { :SCHEMA => schema_name,
  #     >   :NAME   => row_souce_name,
  #     >   :ALIAS  => row_source_alias,
  #     >   :CNAME  => column_name,
  #     >   :CALIAS => column_alias,
  #     > }
  #
  # Notes:
  #   - The code seems to suggest that there is no random choice if the source
  #     alias is not supplied. But the header comment says something random
  #     is given back. Which is right?

  def getSourceColumn(sourceAlias = nil)

    # If the column table is empty, return essentially NIL.

    return { SCHEMA: nil,
             NAME:   nil,
             ALIAS:  nil,
             CNAME:  nil,
             CALIAS: nil,
           } if @coltab.keys.size == 0

    # If the source alias is NIL, then return a random selection. Notice the
    # use of internal variables in the returned Hash.

    ca = choose(@coltab.keys)
    cn = choose(@coltab[ca].keys)
    return { SCHEMA: @symtab[@coltab[cn][ca]][:SCHEMA],
             NAME:   @symtab[@coltab[cn][ca]][:NAME],
             CNAME:  cn,
             CALIAS: ca,
             ALIAS:  @coltab[cn][ca],
           } if sourceAlias.nil?

    # The source alias exists. Get a random selection from it.

    candidates = Array.new
    @coltab.each do |key, value|
      value.each do |v_key, v_value|
        candidates.push([key, v_key, v_value]) if v_value == sourceAlias
      end
    end

    t_alias, c_name, c_alias  = nil
    return {
	SCHEMA:	nil,
	NAME:	nil,
	ALIAS:	nil,
	CNAME:	nil,
	CALIAS:	nil
    } if candidates.empty?
    candidate = choose(candidates)
    c_name, c_alias, t_alias = candidate[0..2] unless candidate.nil?

    t_schema = @symtab.has_key?(t_alias) ? @symtab[t_alias][:SCHEMA] : nil
    t_name   = @symtab.has_key?(t_alias) ? @symtab[t_alias][:NAME]   : nil

    # Return what we've built.

    { SCHEMA: t_schema,
      NAME:   t_name,
      ALIAS:  t_alias,
      CNAME:  c_name,
      CALIAS: c_alias
    }

  end # getSourceColumn



  #----------------------------------------------------------------------------
  # Method: getSequence
  # Retrieve a *SQL* sequence.
  #
  # Method <getSequence> retrieves a sequence description from the
  # <SymbolTable> segment and returns it as a *Hash* given the name of the
  # sequence.
  #
  # Formal Parameters:
  #   name - the *String* name of the sequence to be retrieved.
  #
  # Value:
  #   A *Hash* describing the sequence.
  #    > { :SCHEMA => schema_name,
  #    >   :NAME   => sequence_name
  #    >   :ALIAS  => sequence_alias,
  #    >   :TYPE   => 'SEQUENCE',
  #    > }
  #
  # See:
  #   - <getPhysicalSource>
  #   - <addSequence>

  def getSequence(name)
    getPhysicalSource(name, 'SEQUENCE')
  end # getView


  #----------------------------------------------------------------------------
  # Method: getTable
  # Retrieve a *SQL* table.
  #
  # Method <getTable> retrieves a table description from the <SymbolTable>
  # segment and returns it as a *Hash* given the name of the table.
  #
  # Formal Parameters:
  #   name - the *String* name of the table to be retrieved.
  #
  # Value:
  #   A *Hash* describing the table.
  #    > { :SCHEMA => schema_name,
  #    >   :NAME   => table_name
  #    >   :ALIAS  => table_alias,
  #    >   :TYPE   => 'TABLE',
  #    > }
  #
  # See:
  #   - <getPhysicalSource>
  #   - <addTable>
  #
  # Notes:
  #   - Why does this method allow a *nil* name?

  def getTable(name=nil)
    getPhysicalSource(name, 'TABLE')
  end # getTable


  #----------------------------------------------------------------------------
  # Method: getView
  # Retrieve a *SQL* view.
  #
  # Method <getView> retrieves a view description from the <SymbolTable>
  # segment and returns it as a *Hash* given the name of the view.
  #
  # Formal Parameters:
  #   name - the *String* name of the view to be retrieved.
  #
  # Value:
  #   A *Hash* describing the view.
  #    > { :SCHEMA => schema_name,
  #    >   :NAME   => view_name
  #    >   :ALIAS  => view_alias,
  #    >   :TYPE   => 'VIEW',
  #    > }
  #
  # See:
  #   - <getPhysicalSource>
  #   - <addView>

  def getView(name)
    getPhysicalSource(name, 'VIEW')
  end # getView


  #----------------------------------------------------------------------------
  # Method: setFlag
  # Add a new flag to a <SymbolTable> segment.
  #
  # Method <setFlag> adds a new flag to the <SymbolTable> segment. The supplied
  # flag is an arbitrary object.
  #
  # Formal Parameter:
  #   flag - an objet to be added to the flags.
  #
  # Effects:
  #   The supplied flag is added to the <SymbolTable> segment.

  def setFlag(flag)
    @flags.add(flag)
  end # setFlag


  #----------------------------------------------------------------------------
  # Method: clearFlag
  # Clear a flag from a <SymbolTable> segment.
  #
  # Method <clearFlag> clears (that is, removes) a flag from a <SymbolTable>
  # segment. The flag is an arbitrary object.
  #
  # Formal Parameters:
  #   flag - the object to be removed.
  #
  # Effects:
  #   The flag is removed from the <SymbolTable> segment.

  def clearFlag(flag)
    @flags.delete(flag)
  end # clearFlag


  #----------------------------------------------------------------------------
  # Method: hasFlag?
  # TRUE if a <SymbolTable> segment has a flag.
  #
  # Method <hasFlag?> is TRUE if and only if the flag is currently set for the
  # <SymbolTable> segment. The flag may be an arbitray object.
  #
  # Formal Parameters:
  #   flag - the flag whose presence is to be checked.
  #
  # Value:
  #   *TRUE* if and only the flag is set for the <SymbolTable> segment.
  
  def hasFlag?(flag)
    @flags.include?(flag)
  end # hasFlag?

  #============================================================================
  # Section: Private Object Methods
  # Methods private to the <SymbolTable> class.

# private

  #----------------------------------------------------------------------------
  # Method: columns
  # Return a list of columns from a dictionary object or a list of exported
  # column aliases from an inline view.
  #
  # Method <columns> bridges a gap between dictionary objects (tables, views, etc.)
  # and inline row sources (sub-queries or super-queries). These two classes of
  # relational objects are of different nature from interface point of view but
  # it would be great to have relevant public (like addSourceColumn)
  # and utility (like choose) methods work uniformly on both. Private method
  # <columns> provides for this possibility by hiding a principal difference of
  # internal structures of these two classes. It also provides for automatic
  # sync-up of column aliases (no syncMetadata call is required).
  #
  # Formal Parameters:
  #   tStruct - an entry in @symtab Hash representing one row source
  #   
  # Value:
  #   An array of available column aliases for that row source

  def columns(tStruct)
    return [] if tStruct.nil?
    tStruct[:COLUMNS].instance_of?(Method) ? tStruct[:COLUMNS].call : tStruct[:COLUMNS]
  end # columns

  private

  #----------------------------------------------------------------------------
  # Method: addColToColtab
  # Add a column to the column table.
  #
  # Method <addColToColtab> adds a column with a real name from a source with
  # an alias to the column table structure.
  #
  # Formal Parameters:
  #   colName  - the name of a column.
  #   tabAlias - the alias of a table (or other row source?).
  #   
  # Value:
  #   An alias for added column. This might be the same as the column name.
  #
  # Notes:
  #   - The value is *nil* if the column name is *nil*.

  def addColToColtab(colName, tabAlias)

    # Return NIL if the column name is NIL.

    return nil if colName.nil?

    # The column name is known not to be NIL.  If column colName was not
    # registered in @coltab yet, then go ahead and create a new entry with the
    # alias the same as the name.

    unless @coltab.has_key?(colName)
      @coltab[colName] = { colName => tabAlias }
      return colName
    end

    # Otherwise generate a unique alias name and add an entry to the existing
    # slot for the column name.

    colAlias = fakeName(@coltab[colName].keys.max.to_s)
    @coltab[colName][colAlias] = tabAlias

    return colAlias

  end # addColToColtab


  #----------------------------------------------------------------------------
  # Method: addPhysicalSource
  # Choose a random source from the universe.
  #
  # Method <addPhysicalSource> picks a physical source randomly from the
  # universe, insert its metadata into the <SymbolTable> segment, and returns
  # a descriptive *Hash*.  The method takes care of repeating sources by
  # generating a unique alias for the table which is already in the local sym
  # table.  If sourceType is not present in the universe then a fake name is
  # generated and returned.
  #
  # Formal Parameter:
  #   sourceType - a *Symbol* describing the kind of source to select.
  #                (Default is :TABLES.)
  # Value:
  #   A *Hash*.
  #     > { :SCHEMA => schema_name,
  #     >   :NAME   => row_source_name,
  #     >   :ALIAS  => row_source_alias,
  #     >   :TYPE   => row_source_type
  #     > }
  #
  # Effects:
  #   Information on the physical source is added to the <SymbolTable> segment.

  def addPhysicalSource(sourceType = :TABLES)

    # If there is no item of the sort requested, return an essentially empty
    # description and do nothing to the segment. Notice the use of a locally
    # defined variable inside the Hash literal.

    return { SCHEMA: nil,
             NAME:   pn = fakeName('UNKNOWN_' + sourceType.to_s.chop),
             ALIAS:  pn,
             TYPE:   sourceType,
           } if @bitmap[sourceType].size == 0

    # A TEMPORARY solution to fully qualified object name inconsistency:
    # populate ps_schema to the schema name ONLY if @flags[:SCHEMA] is non-nil

    keysym    = choose(@bitmap[sourceType])
    ps_schema = hasFlag?(:SCHEMA) ? @universe[keysym][:SCHEMA] : nil
    ps_name   = @universe[keysym][:NAME]
    ps_alias  = @universe[keysym][:ALIAS]
    ps_type   = @universe[keysym][:TYPE]
    ps_alias  = fakeName(ps_alias) if @symtab.has_key?(ps_alias)

    # Update the symbol table.

    @symtab[ps_alias]         = @universe[keysym].clone
    @symtab[ps_alias][:ALIAS] = ps_alias

    # Return what's been built.

    { SCHEMA: ps_schema,
      NAME:   ps_name,
      ALIAS:  ps_alias,
      TYPE:   ps_type,
    }

  end # addPhysicalSource


  #----------------------------------------------------------------------------
  # Method: fakeName
  # Create a "faked" name with a given prefix.
  #
  # Method <fakeName> creates a "faked" name given a *String* prefix for the
  # name. The name is guaranteed never to have been generated before.
  #
  # Formal Parameters:
  #   prefix - a *String* that is the prefix of the name.
  #
  # Value:
  #   A *String* that is a new and previously unseen name.
  #
  # Notes:
  #   - The class attribute <@@fakeNum> is used as a serial counter to
  #     guarantee uniqueness of the names.
  #
  # See:
  #   - <@@fakeNum>

  def fakeName(prefix)
    @@fakeNum += 1
    '%s_%d' % [ prefix, @@fakeNum ]
  end # fakeName


  #----------------------------------------------------------------------------
  # Method: findByAlias
  # Find a <SymbolTable> slot from an alias.
  #
  # Method <findByAlias> finds a <SymbolTable> segment entry by an alias (or 
  # other key).
  #
  # Formal Parameter:
  #   sourceAlias - the text of the lookup key.
  #
  # Value
  #   The value of the <SymbolTable> entry for the key. The result may be
  #   *nil*.

  def findByAlias(sourceAlias)
    @symtab[sourceAlias]
  end # findByAlias


  #----------------------------------------------------------------------------
  # Method: getPhysicalSource
  # Choose a physical source from a <SymbolTable> segment.
  #
  # Method <getPhysicalSource> chooses an existing physical source of a
  # particular type from a <SymbolTable> segment given a possible name or
  # alias. The value is essentially *nil* if nothing interesting can be done.
  #
  # Formal Parameters:
  #   sourceName - a name or alias for the source (default is *nil*).
  #   sourceType - a *String* that gives the type for the source (default is
  #                'TABLE').
  #
  # Value:
  #   A Hash.
  #     > { :SCHEMA => physical_source_schema,
  #     >   :NAME   => physical_source_name,
  #     >   :ALIAS  => physical_source_alias, 
  #     >   :TYPE   => physical_source_type,
  #     > }

  def getPhysicalSource(sourceName = nil, sourceType = 'TABLE')

    unless sourceName.nil?
    
      # First we lookup @symtab by its key (alias) assuming that sourceName
      # represents an alias. If key was found and thee type of the source
      # equals sourceType, then return the result of a lookup.

      slot = findByAlias(sourceName)

      return { SCHEMA: slot[:SCHEMA],
               NAME:   slot[:NAME],
               ALIAS:  slot[:ALIAS],
               TYPE:   slot[:TYPE] == sourceType ? sourceType : nil,
             } unless slot.nil?

      # The look up failed. Return some made up stuff. Notice the use of a 
      # variable in the Hash literal.

      return { SCHEMA: nil,
               NAME:   pn = fakeName('UNKNOWN_' + sourceType.to_s),
               ALIAS:  pn,
               TYPE:   sourceType,
             }

    end

    # The sourceName was nil so pick a random candidate and return it. There
    # may be no reasonable candidates.
    
    pickTab = Array.new
    @symtab.each_key do |key|
      pickTab << key if @symtab[key][:TYPE] == sourceType
    end

    return getPhysicalSource(choose(pickTab), sourceType) if not pickTab.empty?

    # It turns out there were no candidates for a random choice. So return
    # an essentially NIL choice. Notice the use of the internal variable
    # in the Hash literal.

    { SCHEMA: nil,
      NAME:   pn = fakeName('UNKNOWN_' + sourceType.to_s),
      ALIAS:  pn,
      TYPE:   sourceType,
    }

  end # getPhysicalSource


  #----------------------------------------------------------------------------
  # Method: syncMetadata
  # Synchronize a <SymbolTable> segment's metadata.
  #
  # Method <syncMetadata> synchronizes two variations of metadata for a row
  # source that has had a new alias assigned.
  #
  # Formal Parameters:
  #   oldAlias - the alias before the change.
  #   newAlias - the alias after the change.
  #
  # Effects:
  #   The <SymbolTable> segment has been adjusted to account for the new
  #   alias.
  #
  # Notes:
  #   - However unrealistic this situation may seem but if a row source gets
  #     a new alias after some columns of this source were added to <@coltab>,
  #     the two main metadata structures will go out of sync. <@coltab>
  #     columns will point to an alias which would no longer exist in
  #     <@symtab>. This private method is called from <addSourceAlias> method
  #     whenever non-trivial alias substitution was done.
  #
  #   - If this is only called in once place, why not inline it there?

  def syncMetadata(oldAlias, newAlias)

    @coltab.each do |col, entry|
      entry.each do |key, value|
        # puts "#{value} - #{newAlias} - #{oldAlias}"
        @coltab[col][key] = newAlias if value == oldAlias
      end
    end

  end # syncMetadata

end # SymbolTable
