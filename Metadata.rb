# Copyright (c) 2011, 2012, Oracle and/or its affiliates. All rights reserved. 

##############################################################################
# Class: Metadata
# SQL database metadata for use in SQL generation.
#
# A <Metadata> object is a library of information about a SQL database that
# can be used to create more realistic SQL statements.
#
# Attributes:

class Metadata

  include Utility
  include Report

  #############################################################################
  # Method: initialize
  # Populate a new <Metadata>
  #
  # Constructor <initialize> populates the attributes of a new <Metadata>.
  #
  # Value:
  #   A new <Metadata>.

  def initialize
    bonus    = %w[ ename job sal comm ]
    dept     = %w[ deptno dname loc ]
    emp      = %w[ empno ename job mgr hiredate sal comm deptno ]    
    salgrade = %w[ grade losal hisal ]
    scottSchema = { :tables => [ [ 'bonus',    bonus],
                                [ 'dept',     dept ],
                                [ 'emp',      emp  ],
                                [ 'salgrade', salgrade ]
                              ],
                   :views  =>             %w[ FeedBeef ],
                   :materialized_views => %w[ DeafBabe ],
                   :sequences =>          %w[ FadedDad ]
                 }
  # @st	     = SymbolTable.new(configuration)
    @st	     = nil
    @stStack = []
    @schemas = [ [ 'scott', scottSchema] ]
    # A stack to keep track of a dictionary object's quaified name being unders construction
    # A stack entry (currently we do not push more than one but it may change later) is a *HASH*
    # that has the following entries:
    # - :STATE (takes values 0 through 4, see states descriptions below)
    # - :ALIAS (contains an ALIAS of a dictionary object which qualified name is being built)
    # - :NAME (contains a *true* name of a dictionary object as registered in a database dictionary)
    # - :CNAME (contains an object column's *true* name)
    # - :CALIAS (contains an object column's *column alias* as introduced in a SELECT clause
    # The *state* provided a limited information about both query and object's name contexts. Based
    # on that information choose* methods make a proper decision about picking a next component for
    # the object qualified name. They may as well raise an exception if an unreachable state had been
    # found. The following contexts are encripted as states:
    # - :STATE => 0 (all other *HASH* entries are supposed to be empty):
    #    - NO object's name is being built (in any part of the SQL statement)
    #    - chooseSchema has just been called (in any applicable part of the SQL statement)
    #    - set at initialization time
    # - :STATE => 1 (:ALIAS must be set, all other entries are empty)
    #    - table/view alias has just been chosen by chooseAlias() method (in any applicable context of the SQL statement). Next expected calls are:
    #      - chooseSchema (in any context)
    #      - chooseColumn (in SELECT or WHERE contexts)
    #      - chooseColumnAlias (in WHERE context)
    #      - NONE, chooseSchema, chooseTable (in FROM context)
    # - :STATE => 2 (:ALIAS and :NAME are set, all other entries are empty)
    #   - table/view name has just been selected by chooseTableName method (it is expected that we're in FROM context of the SQL statement). Next expected calls are:
    #      - chooseSchema (in any context)
    #      - chooseAlias (in FROM context)
    #      - chooseTable (in FROM context)
    # - :STATE => 3 (:ALIAS and :CNAME are set, :NAME MAY be set (no factor), other entries are empty)
    #   - column name has just been chosen by chooseColumn method (in SELECT FROM contexts of the SQL statement). Next expected calls are:
    #      - chooseSchema (in any context)
    #      - chooseColumn (in SELECT or FROM contexts)
    #      - chooseColumnAlias (in SELECT context)
    #      - chooseTable (in SELECT or FROM contexts)
    #      - chooseAlias (in SELECT or FROM contexts)
    @cursrc  = [{:STATE => 0}] 
  end

  #############################################################################
  # Method: symtab
  # Return the symbol table structure of the SymbolTable object (comes in handy
  # in some other methods like columnsFromTable

  def symtab
    @st.nil? ? {} : @st.symtab
  end

  #############################################################################
  # Method: clearSymbolTable
  # Clear current symbol table pointer and symbol tables stack

  def clearSymbolTable
    @st		= nil
    @stStack.clear
    @cursrc	= [{:STATE => 0}]
  end

  #############################################################################
  # Method: addSymbolTable
  # Push existing symbol table on top of the symbol tables stack or create a new
  # symbol table, push it on top of the symbol tables' stack, set it as a CHILD
  # of the previous top table and set the previous top table as a PARENT of the
  # new top

  def addSymbolTable(symTab = nil)
    top		= @stStack.last
    @stStack.push(symTab.nil? ? SymbolTable.new(configuration, top) : symTab)
    @st = @stStack.last
    if symTab.nil?
      top.addInlineSource(@st, :CHILD) unless top.nil?
    end
    @st
  end

  #############################################################################
  # Method: popSymbolTable
  # Pop a symbol table from the symbol tables' stack and set the pointer to the
  # new top

  def popSymbolTable
    @stStack.pop
    @st = @stStack.last
  end

  #############################################################################
  # Method: addSchema
  # All tables are added to the local symbol table with :SCHEMA => nil by default
  # and only when @st.hasFlag?(:SCHEMA) is not nil the table gets seeded with its
  # actual schema name. This is done on purpose to detect this situation and
  # to avoid calling schema name for a table which had been generated with no schema

  def addSchema
    @st.setFlag(:SCHEMA)
    table = @st.addTable
    @st.clearFlag(:SCHEMA)
    table[:SCHEMA]
  end

  #############################################################################
  # Method: addTable
  # Add table to the local symbol table and return a table name.

  def addTable
  # It could be just a temporary solution for inconsistency between fully
  # and partially qualified objects' names before we integrate SymbolTable
  # calls closer to the generation layer.
  # @st.clearFlag(:SCHEMA)
    @st.addTable[:NAME]
  end

  #############################################################################
  # Method: getAlias
  # Return an alias for randomly picked table from symtab

  def getAlias
    @st.getTable[:ALIAS]
  end

  #############################################################################
  # Method: chooseTable
  # Return a table name.
  
  def chooseTable
  # It could be just a temporary solution for inconsistency between fully
  # and partially qualified objects' names before we integrate SymbolTable
  # calls closer to the generation layer.
  # First check if the stack @cursrc is non-empty and has only one element in it
  # (which means we are in the middle of qualified name construction)
    case @cursrc[0][:STATE]
	when 0
	  @cursrc.clear
	  table = @st.getTable
	  @cursrc[0] = {:STATE => 2, :ALIAS => table[:ALIAS], :NAME => table[:NAME]}
	  tableName = table[:NAME]
	when 1
	  table = @st.getTable(@cursrc[0][:ALIAS])
	  @cursrc[0][:NAME] = table[:NAME]
	  @cursrc[0][:STATE] = 2
	  tableName = table[:NAME]
	when 2
	  @cursrc.clear
	  table = @st.getTable
	  @cursrc[0] = {:STATE => 2, :ALIAS => table[:ALIAS], :NAME => table[:NAME]}
	  tableName = table[:NAME]
	when 3
	  @cursrc.clear
	  table = @st.getTable
	  @cursrc[0] = {:STATE => 2, :ALIAS => table[:ALIAS], :NAME => table[:NAME]}
	  tableName = table[:NAME]
	else
	  errorExit("@cursrc is in wrong state #{@cursrc[0][:STATE]} in chooseTable")
    end
    tableName
  end

  #############################################################################
  # Method: chooseAlias
  # Create and return an alias name for table tableName.

  def chooseAlias 
    case @cursrc[0][:STATE]
	when 0
	  tableAlias = @st.getTable[:ALIAS]
	  @cursrc[0][:ALIAS] = tableAlias
	  @cursrc[0][:STATE] = 1
	when 1
	  tableAlias = @cursrc[0][:ALIAS]
	when 2
	  tableAlias = @cursrc[0][:ALIAS]
	  @cursrc.clear
	  @cursrc[0] = {:STATE => 0}
	when 3
	  @cursrc.clear
	  tableAlias = @st.getTable[:ALIAS]
	  @cursrc[0] = {:STATE => 1, :ALIAS => tableAlias}
	else
	  errorExit("@cursrc is in wrong state #{@cursrc[0][:STATE]} in chooseAlias")
    end
    tableAlias
  end

  #############################################################################
  # Method: chooseColumn
  # Return a column name.
  
  def chooseColumn(sourceAlias)
    case @cursrc[0][:STATE]
	when 0
	  @cursrc.clear
	  table = @st.getTable
	  columnName = (@st.getSourceColumn(table[:ALIAS]))[:CNAME]
	  columnName = (@st.addSourceColumn(table[:ALIAS]))[:CNAME] unless columnName
	  @cursrc[0] = {:STATE => 3, :ALIAS => table[:ALIAS], :CNAME => columnName}
	when 1
	  columnName = (@st.getSourceColumn(@cursrc[0][:ALIAS]))[:CNAME]
	  columnName = (@st.addSourceColumn(@cursrc[0][:ALIAS]))[:CNAME] unless columnName
	  @cursrc[0][:STATE] = 3
	  @cursrc[0][:CNAME] = columnName
	when 2
	  columnName = (@st.getSourceColumn(@cursrc[0][:ALIAS]))[:CNAME]
	  columnName = (@st.addSourceColumn(@cursrc[0][:ALIAS]))[:CNAME] unless columnName
	  @cursrc[0][:STATE] = 3
	  @cursrc[0][:CNAME] = columnName
	when 3
	  @cursrc.clear
	  table = @st.getTable
	  columnName = (@st.getSourceColumn(table[:ALIAS]))[:CNAME]
	  columnName = (@st.addSourceColumn(table[:ALIAS]))[:CNAME] unless columnName
	  @cursrc[0] = {:STATE => 3, :ALIAS => table[:ALIAS], :CNAME => columnName}
	else
	  errorExit("@cursrc is in wrong state #{@cursrc[0][:STATE]} in chooseColumn")
    end
    columnName
  end

  #############################################################################
  # Method: chooseColumnAlias
  # Return a column alias.

  def chooseColumnAlias
    case @cursrc[0][:STATE]
	when 3
	  columnAlias = @st.getSourceColAlias(@cursrc[0][:CNAME], @cursrc[0][:ALIAS])
	  @cursrc.clear
	  @cursrc[0] = {:STATE => 0}
	else
	  errorExit("@cursrc is in wrong state #{@cursrc[0][:STATE]} in chooseColumnAlias")
    end
    columnAlias
  end

  #############################################################################
  # Method: chooseView
  # Return a view name.
  
  def chooseView
  # views = choose(@schemas)[1][:views]
  # choose(views)
    @st.addView[:NAME]
  end


  #############################################################################
  # Method: chooseMaterializedView
  # Return a materialized view name.
  
  def chooseMaterializedView
  # views = choose(@schemas)[1][:materialized_views]
  # choose(views)
    @st.addMView[:NAME]
  end


  #############################################################################
  # Method: chooseSequence
  # Return a sequence name.
  
  def chooseSequence
  # sequences = choose(@schemas)[1][:sequences]
  # choose(sequences)
    @st.addSequence[:NAME]
  end


  #############################################################################
  # Method: chooseSchema
  # Return a schema name.
  
  def chooseSchema
    schemas	= []
    @cursrc.clear
    @cursrc[0] = {:STATE => 0}
    unless @st.symtab.keys.empty?
      slot = @st.symtab[choose(@st.symtab.keys)]
      schemas << (slot.has_key?(:SCHEMA) ? slot[:SCHEMA] : "UNKNOWN_SCHEMA")
    # @cursrc[0] = {:STATE => 1, :ALIAS => slot[:ALIAS]}
    else
    # If @st.symtab symbol table has not been populated yet then schemas array
    # will come out empty. In that case we'll search universe directly.
	@st.universe.each do |key, value|
	  schemas << value[:SCHEMA] unless schemas.include?(value[:SCHEMA])
	end
    end
    # Tell SymbolTable object and future callers that schema has been called
  # @st.setFlag(:SCHEMA)
    choose(schemas)
  end


  #############################################################################
  # Method: columnsFromTable
  # Return the columns from a table.

  def columnsFromTable(theTable)
    columns = []
  # @schemas.each do |s|
  #   s[1][:tables].each do |t|
  #     columns.concat(t[1]) if t[0] == theTable
  #   end
  # end
  # columns
    @st.symtab.each do |key, value|
	if value[:ALIAS] == theTable
	  columns = value[:COLUMNS]
	end
    end
    columns
  end

end # Metadata
