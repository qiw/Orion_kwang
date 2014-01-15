# Copyright (c) 2010, 2012, Oracle and/or its affiliates. All rights reserved. 

###############################################################################
# Class: OrionGrammar
# Provide a SQL <Grammar> definition for *Orion*.
#
# Class <OrionGrammar> has only one purpose: to create and return a <Grammar>
# object which represents SQL for *Orion*.

require 'Grammar.rb'
require 'set'

class OrionGrammar < Grammar

  include Report
  include Utility


  ############################################################################
  #
  # Public class methods
  #
  ############################################################################

  ############################################################################
  # Method: new
  # Create a new <OrionGrammar>.
  #
  # Method <new> creates a new <OrionGrammar> object. Of course, it is also a
  # <Grammar> object.
  #
  # Notes:
  #   - Ruby actually doesn't have new methods; rather it allows the user to
  #     initialize storage after the object has been created.

  def initialize
    super
    normalWeight = 1000000
    lowWeight    = (Math.sqrt(normalWeight) + 1).to_i
    logNormal    = Math.log(normalWeight)
    mediumWeight = (lowWeight*logNormal*logNormal).to_i
    oneWeight    = 10
    @weights     = { :N => normalWeight, :M => mediumWeight,
                     :L => lowWeight,    :O => oneWeight }
    @symbols     = addSymbols
    addRules
  end


  ############################################################################
  #
  # Private instance methods
  #
  ############################################################################

  private

  ############################################################################
  # Method: addRules
  # Add <GramRules> to the *Orion* <Grammar>
  #
  # Method <addRules> just adds rules, one by one, to the *Orion* <Grammar>.

  def addRules

    rl = ruleList

    rl.each do |r|

      # Make sure the weight selector is reasonable.

      errorExit("Bad rule kind #{r[0].to_s}") unless @weights.has_key?(r[0])

      lhs = @symbols[r[1]]
      errorExit("Left symbol #{r[1].to_s} unknown") if lhs.nil?
      rhs = []
      r[2].each do |s|
        right = @symbols[s]
        errorExit("Right symbol |#{s.to_s}| unknown") if right.nil?
        rhs << right
      end
      newRule = GramRule.new(lhs, rhs)

      # Add the rule to the grammar.

      rep = r[3].nil? ? nil : self.method(r[3])
      dfn = r[4].nil? ? nil : self.method(r[4])
      addRule(newRule, @weights[r[0]], rep, dfn)

    end

  end


  ############################################################################
  # Method: addSymbols
  # Add <GramSyms> to the *Orion* <Grammar>.
  #
  # Method <addSymbols> adds new <GramSyms> to the *Orion* <Grammar>. We do
  # this so that we can check for errors and attach all representation and
  # generation functions to the <GramSyms>.

  def addSymbols

    theSymbols = Hash.new

    # Get the list of all symbols. Immediately check that no name is in the
    # list twice.

    s     = symbolList
    names = Set.new
    s.each do |a|
      n = a[1]
      errorExit("Name |#{n}| in symbol list twice") if names.include?(n)
      names.add(n)
    end

    # Now process each line into a grammar symbol.

    s.each do |a|
      case a[0] # The kind selector
        when :KW then
          theSym = GramSym.new(a[1]) # This could be an upcase if desired.
        when :NT then
          theSym = GramSym.new(a[1])
        when :T then
          theSym = GramSym.new(a[2])
        else
          errorExit("Unknown symbol kind |#{a[0]}|")
      end

      # Turn the name into a Ruby Symbol.

      theSymbols[a[1].to_sym] = theSym

    end

    return theSymbols

  end


  #############################################################################
  #
  # Definition methods
  #
  #############################################################################

  def schemaNameGen(theTree)
    theTree.myText = @metadata.addSchema
  end

  #############################################################################
  # Method: tableAliasGen
  # Remember a table alias when it is created.
  #
  # Method <tableAliasGen> remembers any table alias that is generated in a
  # FROM clause and puts it into the probe private metadata.

  def tableAliasGen(theTree)
  # theTree.myText = "ta_#{theTree.object_id}"
    theTree.myText = @metadata.getAlias
  # theTree.probeData[:tableAliases].push(theTree.myText)
  end


  #############################################################################
  # Method: tableNameGen
  # Generates a table name from the from_list
  #
  # Method <tableNameGen> generates a table name for (what is effectively) a
  # table definition in the FROM list. This table name can then be used as a
  # table reference. The name also must be remembered in the tree node so it
  # eventually be printed.
  #
  # We also add the columns to the probe metadata as possible bare column name
  # references

  def tableNameGen(theTree)
    theTable = @metadata.addTable
    theTree.myText = theTable
  # theTree.probeData[:tables].push(theTable)
  # theTree.probeData[:columns].concat(@metadata.columnsFromTable(theTable))
  end


  #############################################################################
  # Method: columnAliasRep
  #
  # Method <columnAliasGen> returns a column alias for a randomly picked column
  # from @metadata's coltab structure

  def columnAliasRep(theTree)
  # theTree.myText = "ca_#{theTree.object_id}"
    theTree.myText = @metadata.chooseAlias
  # theTree.probeData[:columnAliases].push(theTree.myText)
  end

  #############################################################################
  # Method: subQueryGen
  # A dummy method which adds a Symbol Table onto the @metadata.@stStack
  # This method is for dummy NTs *select_body* and *subquery*

  def subQueryGen(theTree)
    theTree.symbolTable = @metadata.addSymbolTable
  end

  #############################################################################
  # Method: endOfSubqueryGen
  # A dummy method which pops the current Symbol Table off the @metadata.@stStack
  # at the end of current query block during generation phase.
  # This method is for dummy NT *end_of_subquery*.

  def endOfSubqueryGen(theTree)
    @metadata.popSymbolTable
  end


  #############################################################################
  #
  # Representation methods
  #
  #############################################################################

  #############################################################################
  # Method: subQueryRep
  # A dummy method which pushes a Symbol Table onto the @metadata.@stStack
  # and then calls default representation method for current node.

  def subQueryRep(theTree)
    @metadata.addSymbolTable(theTree.symbolTable)
    defaultRepresent(theTree)
  end

  #############################################################################
  # Method: endOfSubqueryRep
  # A dummy method which pops the current Symbol Table off the @metadata.@stStack
  # at the end of current query block. This method is for dummy NT *end_of_subquery*.

  def endOfSubqueryRep(theTree)
    @metadata.popSymbolTable
    ""
  end

  #############################################################################
  # Method: treeText
  # Provide <GramTree> text as the representation.
  #
  # Method <treeText> provides text stored in a <GramTree> as its own
  # representation. This is generally used when the node represents a whole
  # cloth creation of an identifier or some such.

  def treeText(theTree)
    theTree.myText
  end


  #############################################################################
  # Method: betterCommas
  # Improve the appearance of commas
  #
  # Method <betterCommas> is applied to <GramNodes> which represent things
  # like lists separated by commas. It removes blanks that appear immediately
  # before the commas so that humans like the lists better.

  def betterCommas(theTree)
    theTree.changeRepProc(self.method(:defaultRepresent))
    text = theTree.represent(self)
    text.gsub(/ ,/, ',')
  end


  #############################################################################
  # Method: squeezeBlanks
  # Squeeze blanks out of a representation.
  #
  # Method <squeezeBlanks> generates the default representation for a
  # <GramTree> and then removes all the blanks. This is useful for making
  # things like table.column read nicely for humans.

  def squeezeBlanks(theTree)
    theTree.changeRepProc(self.method(:defaultRepresent))
    text = theTree.represent(self)
    text.tr(' ', '')
  end


  #############################################################################
  # Method: columnRefRep
  # Find a column reference
  #
  # Method <columnRefRep> finds a column reference from the probe metadata.

  def columnRefRep(theTree)
    theTable  = @metadata.chooseAlias
    theCol    = @metadata.chooseColumn(theTable)
    "#{theCol}"
  end


  #############################################################################
  # Method: columnTableRefRep
  # Find column.table reference.
  #
  # Method <columnTableRefRep> finds a table.column reference from the probe
  # metadata

  def columnTableRefRep(theTree)
    theTable = @metadata.chooseAlias
    theCol   = @metadata.chooseColumn(theTable)
    "#{theTable}.#{theCol}"
  end


  #############################################################################
  # Method: columnTableSchemaRefRep
  # Find schema.column.table reference
  #
  # Method <columnTableSchemaRefRep> finds a schema.table.column reference
  # from probe metadata.
  #
  # HACK:
  #   - For the moment, we know we are using "scott"

  def columnTableSchemaRefRep(theTree)
  # 'scott.' + columnTableRefRep(theTree)
    schema = @metadata.chooseSchema
    if schema == "UNKNOWN_SCHEMA"
	columnTableRefRep(theTree)
    else
    	schema + '.' + columnTableRefRep(theTree)
    end
  end

  def tableRefRep(theTree)
    child = theTree.children[0]
    grandKids = child.children
    return grandKids[0].represent(self) if grandKids.length == 1
    return grandKids[0].represent(self) + '.' + grandKids[2].represent(self)
  end


  #############################################################################
  # Method: schemaNameRep
  # Select a "real" schema name.
  #
  # Method <schemaNameRep> returns a schema name from the metadata; thus, this
  # is the name of an object in the database. There always must be at least
  # one.

  def schemaNameRep(theTree)
    @metadata.chooseSchema
  end


  #############################################################################
  # Method: tableNameRep
  # Select a "real" schema name.
  #
  # Method <tableNameRep> returns a table name from the metadata; thus, this
  # is the name of an object in the database. There always must be at least
  # one.

  def tableNameRep(theTree)
    @metadata.chooseTable
  end


  #############################################################################
  # Method: viewNameRep
  # Select a "real" view name.
  #
  # Method <viewNameRep> returns a view name from the metadata; thus, this is
  # the name of an object in the database. There always must be at least one.

  def viewNameRep(theTree)
    @metadata.chooseView
  end


  #############################################################################
  # Method: materializedViewNameRep
  # Select a "real" materialized view name.
  #
  # Method <materializedViewNameRep> returns a materialized view name from the
  # metadata; thus, this is the name of an object in the database. There
  # always must be at least one.

  def materializedViewNameRep(theTree)
    @metadata.chooseMaterializedView
  end


  #############################################################################
  # Method: sequenceNameRep
  # Select a "real" sequence name.
  #
  # Method <sequenceNameRep> returns a sequence name from the metadata; thus,
  # this is the name of an object in the database. There always must be at
  # least one.

  def sequenceNameRep(theTree)
    @metadata.chooseSequence
  end


  #############################################################################
  # Method: tableAliasRep
  # Find a table alias from the probe metadata.
  #
  # Method <tableAliasRep> finds a table alias from the private probe metadata.
  # If there isn't one, it generates a silly name.

  def tableAliasRep(theTree)
  # tas = theTree.probeData[:tableAliases]
  # choose(tas) unless tas.empty?
    @metadata.chooseAlias
  end


  #############################################################################
  # Method: queryRefRep
  # Find a query name from the probe metadata.
  #
  # Method <queryRefRep> finds a query name from the private probe metadata.
  # If none has been defined, a silly one is genererate.

  def queryRefRep(theTree)
  # qas = theTree.probeData[:queryNames]
  # return qas[rand(qas.length)] unless qas.length == 0
    return 'CafeBabe'
  end


  #############################################################################
  # Method: viewRefRep
  # Find a view name from the probe metadata.
  #
  # Method <viewRefRep> finds a view name from the private probe metadata.
  # If none has been defined, a silly one is genererate.

  def viewRefRep(theTree)
  # vas = theTree.probeData[:views]
  # return vas[rand(vas.length)] unless vas.length == 0
  # return 'CafeDead'
    @metadata.chooseView
  end


  #############################################################################
  # Method: materializeViewRefRep
  # Find a materialized view name from the probe metadata.
  #
  # Method <materializedViewRefRep> finds a view name from the private probe
  # metadata.  If none has been defined, a silly one is genererate.

  def materializedViewRefRep(theTree)
  # vas = theTree.probeData[:materializedViews]
  # return vas[rand(vas.length)] unless vas.length == 0
  # return 'AbbeDeed'
    @metadata.chooseMaterializedView
  end


  #############################################################################
  # Method: tickKeywordRep
  # Form a ticked string for an Oracle required quoted keyword.
  #
  # Method <tickKeywordRep> represents a keywork K as the string literal
  # 'K' because the RDBMS requires some mechanisms to have specific string
  # arguments. The actual text of the terminal will be &q'something' because
  # this is the representation for the output grammar used by other tools. The
  # text representation for generation simply strips the leading &q.

  def tickKeywordRep(theTree)
    inside = theTree.children[0].represent(self)
    return inside.sub('&q', '')
  end


  #############################################################################
  # Method: ordIdentRep
  # Generate a *SQL* ordinary identifier.
  
  def ordIdentRep(theTree)
    value = String.new
    1.upto(rand(10)+1) do |i|
      value << 'abcdefghijklmnopqrstuvwxyz0123456789'[rand(36)]
    end
    'abcdefghijklmnopqrstuvwxyz'[rand(26)] + value
  end


  #############################################################################
  # Method: quoteIdentRep
  # Generate a *SQL* quoted identifier

  def quoteIdentRep(theTree)
    value = String.new
    1.upto(rand(10)+1) do |i|
      value << 'abcdefghijklmnopqrstuvwxyz0123456789~!@#$%^&*()_+'[rand(49)]
    end
    '"' + value + '"'
  end


  #############################################################################
  # Method: tickStringRep
  # Generate a *SQL* ticked string literal.
  #
  # Method <tickStringRep> generates a string literal like 'xyz' by random
  # selection of characters to go into the literal.
  #
  # Value:
  #   A String of the form '...'.
  #
  # Notes:
  #   - The empty (and thus *NULL*) *SQL* string '' is explicitly allowed as
  #     a value.

  def tickStringRep(theTree)
    value = String.new
    1.upto(rand(20)+1) do |i|
      value << 'abcdefghijklmnopqrstuvwxyz0123456789'[rand(36)]
    end
    "'" + value + "'"
  end


  #############################################################################
  # Method: integerLitRep
  # Generate a *SQL* integer literal.
  #
  # Method <integerLitRep> generates a random *SQL* integer literal.
  #
  # Value:
  #   A non-empty String that conforms to the syntax of a *SQL* integer
  #   literal.
  #
  # Notes:
  #   - Literals like 01 and 000 are explicitly allowed.
  #   - Literals do not have signs; these are provided by the expression
  #     syntax.

  def integerLitRep(theTree)
    value  = String.new
    0.upto(rand(40)) { |i| value << rand(10).to_s }
    value
  end


  #############################################################################
  # Method: smallIntRep
  # Generate a *SQL* integer literal suitable for small constraints.
  #
  # Method <smallIntRep> generates integer literals that are appropriate for 
  # small precisions (like NUMBER). We allow it to go over a bit to test if the
  # routines that check size deal correctly with "close" values.
  
  def smallIntRep(theTree)
    (rand > 0.5 ? '0' : '') + rand(41).to_s 
  end


  #############################################################################
  # Method: mediumIntRep
  # Generate a *SQL* integer literal suitable for medium constraints.
  #
  # Method <mediumIntRep> generates integer literals that are appropriate for
  # medium precisions (like VARCHAR2). We allow it to go over a bit to test if
  # the routines that check size deal correctly with "close" values.
  
  def mediumIntRep(theTree)
    (rand > 0.5 ? '0' : '') + rand(4010).to_s 
  end


  #############################################################################
  # Method: numberLitRep
  # Generate a *SQL* Number literal.

  def numberLitRep(theTree)
    rand(100).to_s + '.' + rand(100).to_s
  end


  #############################################################################
  # Method: ieeeLitRep
  # Generate a *SQL* floating pointer number literal.

  def ieeeLitRep(theTree)
    rand(100).to_s + '.' +
      rand(100).to_s +
      [ 'E', 'E+', 'E-'][rand(3)] +
      rand(10).to_s
  end


  #############################################################################
  # Method: formatRep
  # Generate a *SQL* string appropriate as a format.

  def formatRep(theTree)
    "'%d'" % 999
  end


  #############################################################################
  # Method: nlsParamRep
  # Generate a *SQL* string appropriate for some NLS functions.

  def nlsParamRep(theTree)
    "'NLS_NUMERIC_CHARACTERS = ''%s'''" % ',.'
  end


  #############################################################################
  # Method: tightParenRep
  # Make a parenthesized contruct attractive to humans.
  #
  # Method <tightParenRep> takes a <GramTree> of three elements which
  # represents some sort of parenthesized construct and produces a string in
  # which the outer parentheses are "tight" to the inner content.
  #
  # Value:
  #   A String with nicely formatted parentheses.
  #
  # Notes:
  #   - The two outside elements of the <GramTree> should be a left and
  #     right parenthesis. This will not be checked.

  def tightParenRep(theTree)
    inside = theTree.children[1].represent(self)
    '(' + inside.lstrip.strip + ')'
  end


  #############################################################################
  # Method: tightOperRep
  # Squeeze space out of an infix operation representation.
  #
  # Method <tightOperRep> takes a <GramTree> of three elements and returns
  # a representation with white space removed on either side of the central
  # element.
  #
  # Value:
  #   A String with the inner operator "tight" to its operands.
  #
  # Notes:
  #   - This method is intended for use on <GramTrees> for operators like
  #     multiplication where 'a*b', not 'a * b', is the better string
  #     representation. There are no checks that the inputs are of this form.

  def tightOperRep(theTree)
    left  = theTree.children[0].represent(self)
    oper  = theTree.children[1].represent(self)
    right = theTree.children[2].represent(self)
    left.lstrip.rstrip + oper.lstrip.rstrip + right.lstrip.rstrip
  end


  #############################################################################
  # Method: tightUnaryRep
  # Squeeze space out of a prefix operator representation.
  #
  # Method <tightUnaryRep> takes a <GramTree> of two elements and returns a
  # representation in which the space between the elements has been removed.
  #
  # Value:
  #   A String with the two operands "tight" to one another.
  #
  # Notes:
  #   - This method is intended for use in cases like '- num' or 'f (...)'
  #     where the normal convention would be '+num' or 'f(...)'. There is no
  #     check on the operands.

  def tightUnaryRep(theTree)
    oper  = theTree.children[0].represent(self)
    right = theTree.children[1].represent(self)
    oper.lstrip.rstrip + right.lstrip.rstrip
  end


  ############################################################################
  #
  # Terminal symbol definitions
  #
  ############################################################################

  private

  ############################################################################
  # Method: reservedWords
  # List of all the *SQL* reserved words.
  #
  # Method <reservedWords> returns a list of all the Oracle *SQL* reserved
  # words. These cannot ever be used as unquoted identifiers. The method 
  # returns the same structure as <keywordList>. They are kept separate from
  # keywords so that keywords but not reserved words can turn into identifiers.
  # Otherwise the grammar makes no distinction.

  def reservedWords
    %w[
      access
      add
      all
      alter
      and
      any
      as
      asc
      audit
      between
      by
      char
      check
      cluster
      column
      column_value
      comment
      compress
      connect
      create
      current
      date
      decimal
      default
      delete
      desc
      distinct
      drop
      else
      exclusive
      exists
      file
      float
      for
      from
      grant
      group
      having
      identified
      immediate
      in
      increment
      index
      initial
      insert
      integer
      intersect
      into
      is
      level
      like
      lock
      long
      maxextents
      minus
      mlslabel
      mode
      modify
      nested_table_id
      noaudit
      nocompress
      not
      nowait
      null
      number
      of
      offline
      on
      online
      option
      or
      order
      pctfree
      prior
      privileges
      public
      raw
      rename
      resource
      revoke
      row
      rowid
      rownum
      rows
      select
      session
      set
      share
      size
      smallint
      start
      successful
      synonym
      sysdate
      table
      then
      to
      trigger
      uid
      union
      unique
      update
      user
      validate
      values
      varchar
      varchar2
      view
      whenever
      where
      with
    ].collect! { |a| [ :KW, a ] }

  end


  ############################################################################
  # Method: keywordList
  # List of all the *SQL* keywords.
  #
  # Method <keywordList> returns a list of all the *SQL* keywords as an array
  # of pairs. Each pair is of the form [ :KW, <text of keyword> ]. A keyword
  # may (generally, although there may be some specific semantic restrictions)
  # be used as an identifier.
  #
  # NOTES:
  #   - The layout is designed to make it easy to add new keywords as
  #     development goes on. There is no particular ordering, but it is easier
  #     to add keywords if they are kept in sorted order.
  #   - The collect! at the end does the actual work of constructing the pairs.
  #   - See also <reservedWords>.

  def keywordList
    %w[
       anydata
       anydataset
       anytype
       at
       avg
       bfile
       binary_double
       binary_float
       bitand
       blob
       byte
       case
       cast
       character
       clob
       constraint
       count
       cross
       cube
       currval
       day
       dbtimezone
       dec
       decode
       dimension
       double
       end
       escape
       first
       first_value
       following
       front
       full
       grouping
       ignore
       inner
       int
       interval
       join
       last
       last_day
       left
       like2
       like4
       likec
       local
       locked
       loop
       lower
       ltrim
       max
       measures
       min
       model
       month
       multiset
       national
       natural
       nchar
       nclob
       nextval
       nocycle
       nulls
       numeric
       nvarchar2
       nvl
       nvl2
       only
       ordaudio
       orddicom
       orddoc
       ordimage
       ordvideo
       outer
       over
       partition
       preceding
       precision
       range
       rank
       read
       real
       respect
       right
       rollup
       round
       sdo_geometry
       sdo_georaster
       sdo_topo_geometry
       second
       sessiontimezone
       sets
       si_averagecolor
       si_color
       si_colorhistogram
       si_featurelist
       si_positionalcolor
       si_stillimage
       si_texture
       siblings
       skip
       sum
       sys
       sys_context
       sys_op_countchg
       sys_op_map_nonnull
       sys_op_trtb
       time
       timestamp
       to_char
       to_date
       to_nchar
       to_number
       trunc
       unbounded
       upper
       uritype
       urowid
       userenv
       using
       varying
       wait
       when
       xmltype
       year
       zone
    ].collect! { |a| [ :KW, a ] }
  end


  ############################################################################
  # Method: nonterminalList
  # List of all the *SQL* nonterminals.
  #
  # Method <nonterminalList> returns a list of all the *SQL* nonterminals as
  # an array of pairs. Each pair is of the form [ :NT, <text of nonterminal> ].
  #
  # NOTES:
  #   - See the notes on <keywordList>

  def nonterminalList
    %w[
       ac_query_partition_clause
       aggregage_func_over_clause
       aggregate_arg_list
       aggregate_argument
       aggregate_func_over_clause
       aggregate_function
       analytic_clause
       analytic_function
       ansi_char_size
       ansi_char_type
       ansi_character_type
       ansi_national_type
       ansi_numeric_type
       ansi_supported_datatype
       ansi_varchar_type
       ansi_vary_clause
       between_condition
       bitand_function
       ca_item
       ca_item_list
       case_expression
       cast_argument
       cast_argument_list
       cast_function
       cast_type_name
       cell_assignment
       cell_assignment_list
       cell_item
       char_datatype
       character_datatype
       character_function
       column_alias_definition
       column_ident
       column_ref
       column_ref_plus
       common_aggr_head
       common_aggr_name
       common_aggregate
       compound_expr
       condition
       constraint_name
       conversion_function
       count_function
       count_head
       count_tail
       cv_size_spec
       cv_size_value
       datatype
       datetime_datatype
       datetime_expression
       day_part
       day_precision
       decode_args
       decode_function
       decode_pair_list
       decode_tail
       else_clause
       environment_function
       end_of_subquery
       equality_operator
       exists_condition
       expr
       expr_column
       expr_comparison
       expr_list
       first_value_function
       first_value_lower
       first_value_lower_arg
       first_value_lower_item
       first_value_upper
       first_value_upper_head
       flashback_query_clause
       float_prec
       float_type
       for_update_clause
       format
       from_clause
       from_item
       from_list
       from_part
       fu_item
       fu_list
       fu_option
       function
       function_expression
       group_by_clause
       group_by_part
       grouping_expression_list
       grouping_sets_clause
       grouping_sets_list
       having_clause
       hierarchical_query_clause
       hqc_condition
       hqc_connect_by
       hqc_start
       ident
       ieee_lit
       ieee_value
       in_condition
       inequality_operator
       inner_cross_join_clause
       int_day_type
       int_year_type
       integer_lit
       integer_value
       join_clause
       join_clause_element
       join_clause_list
       large_limit
       large_object_datatype
       last_day_function
       left_mcc_list
       like_condition
       like_operator
       logical_condition
       long_and_raw_datatype
       long_size
       lower_function
       lower_icjc
       ltrim_function
       main_model
       materialized_view_name
       materialized_view_ref
       mcc_item
       mcc_list
       measure_column
       medium_limit
       model_clause
       model_column_clauses
       model_rules_clause
       national_char_part
       nchar_datatype
       nchar_size_spec
       nls_param
       null_condition
       null_related_function
       number_datatype
       number_lit
       number_prec_scale
       number_ps_values
       number_type
       number_value
       numeric_value
       nvarchar2_datatype
       nvl_function
       ojc_part2
       ojc_part3
       ojc_part4
       oracle_built_in_datatype
       oracle_supplied_type
       order_by_clause
       order_by_head
       order_by_item
       order_by_part1
       order_by_part2
       order_by_position
       order_by_tail
       ordering_operator
       outer_join_clause
       outer_join_type
       parened_aggregate_argument
       parened_analytic_clause
       parened_expr
       parened_expr_list
       parened_expr_list2
       parened_expr_list2_body
       parened_expr_list2_element
       parened_four_exprs
       parened_four_exprs_body
       parened_four_exprs_list
       parened_subquery
       parened_three_exprs
       parened_three_exprs_body
       parened_three_exprs_list
       parened_two_exprs
       parened_two_exprs_body
       parened_two_exprs_list
       pattern_matching_condition
       pivot_clause
       qb_tail
       qb_tail1
       qb_tail2
       qb_tail3
       qb_tail4
       qtab_expr_name_use
       qtab_expr_part2
       qtab_expr_part2_head
       qtab_expr_part3
       query_block
       query_name
       query_name_def
       query_partition_clause
       query_ref
       query_table_expression
       rank_analytic_function
       remote_db_name
       right_mcc_list
       rollup_cube_clause
       round_function
       rowid_datatype
       sample_clause
       scalar_subquery_expression
       schema_name
       schema_name_use
       schema_ref
       scp_keyword
       scp_other_params
       scp_userenv
       scp_userenv_params
       searched_case_clause
       searched_case_expression
       second_part
       select_body
       select_expr_item
       select_list
       select_list_item
       select_list_schema_item
       select_list_star_item
       select_part
       select_section
       select_statement
       sequence_expr
       sequence_name
       simple_case_clause
       simple_case_expression
       simple_comparison_condition
       simple_expression
       simple_subquery
       single_row_function
       small_limit
       sqf_item
       sqf_list
       sql_statement
       star_select
       string
       string_lit
       subquery
       subquery_comparison
       subquery_expr_operator
       subquery_factoring_clause
       subquery_item
       subquery_restriction_clause
       sum_function
       sum_head
       sys_context_function
       sys_context_params
       sys_op_countchg_function
       sys_op_map_nonnull_function
       sys_op_trtb_function
       table_alias
       table_alias_definition
       table_collection_expression
       table_name
       table_name_use
       table_ref
       table_reference
       table_reference_head
       table_reference_tail
       tce_head
       tce_plus
       tick_string
       timestamp_head
       timestamp_prec
       timestamp_type
       to_char_arglist
       to_char_args
       to_char_function
       to_char_name
       trunc_function
       type_identifier
       udf_arg
       udf_args
       udf_call
       udf_list
       udf_name
       unpivot_clause
       upper_function
       upper_icjc
       upper_icjc_column_ref_list
       upper_icjc_head
       upper_icjc_on_condition
       upper_icjc_using_condition
       user_defined_function
       user_defined_type
       userenv_function
       userenv_param
       userenv_parens
       varchar2_datatype
       view_name
       view_ref
       wc_expr
       wc_front
       wc_lower
       wc_upper
       wc_upper1
       wc_upper2
       where_clause
       windowing_clause
       year_part
       year_precision
     ].collect! { |a| [:NT, a] }
  end


  ############################################################################
  # Method: terminalList
  # List of all the *SQL* terminals.
  #
  # Method <terminalList> returns a list of all the *SQL* terminals as an
  # array of triples. Each triple is of the form
  #  > [ :T, <text of name>, <actual text> ].
  #
  # NOTES:
  #   - See the notes on <keywordList>
  #   - The terminal texts that are surrounded in angle brackets will not be
  #     expanded further. They have to be terminals in the *PLParser* lexer.

  def terminalList
    [
     %w[ asterisk      *        ],
     %w[ at_sign       @        ],
     %w[ bang_equal    !=       ],
     %w[ box           <>       ],
     %w[ comma         ,        ],
     %w[ dot           .        ],
     %w[ equals        =        ],
     %w[ greater       >        ],
     %w[ greater_equal >=       ],
     %w[ hat_equal     ^=       ],
     %w[ less          <        ],
     %w[ less_equal    <=       ],
     %w[ lparen        (        ],
     %w[ lbracket      \[       ],
     %w[ minus_sign    -        ],
     %w[ plus          +        ],
     %w[ rparen        )        ],
     %W[ rbracket      \]       ],
     %w[ slash         /        ],
     %w[ strokestroke  ||       ],
     %w[ plparser_ident    <id>                ],
     %w[ plparser_qident   <quoted_identifier> ],
     %w[ plparser_number   <numeric_literal>   ],
     %w[ plparser_string   <string_literal>    ],
    ].collect! { |a| a.unshift(:T) } +

    [
     %w[ action                     ],
     %w[ audited_cursorid           ],
     %w[ authenticated_identity     ],
     %w[ authentication_data        ],
     %w[ authentication_method      ],
     %w[ authentication_type        ],
     %w[ bg_job_id                  ],
     %w[ client_identifier          ],
     %w[ client_info                ],
     %w[ current_bind               ],
     %w[ current_edition_id         ],
     %w[ current_edition_name       ],
     %w[ current_schema             ],
     %w[ current_schema_id          ],
     %w[ current_sql                ],
     %w[ current_sql_length         ],
     %w[ current_user               ],
     %w[ current_userid             ],
     %w[ database_role              ],
     %w[ db_domain                  ],
     %w[ db_name                    ],
     %w[ db_unique_name             ],
     %w[ dblink_info                ],
     %w[ enterprise_identity        ],
     %w[ entryid                    ],
     %w[ external_name              ],
     %w[ fg_job_id                  ],
     %w[ global_context_memory      ],
     %w[ global_uid                 ],
     %w[ host                       ],
     %w[ identification_type        ],
     %w[ instance                   ],
     %w[ instance_name              ],
     %w[ ip_address                 ],
     %w[ isdba                      ],
     %w[ lang                       ],
     %w[ language                   ],
     %w[ module                     ],
     %w[ network_protocol           ],
     %w[ nls_calendar               ],
     %w[ nls_currency               ],
     %w[ nls_date_format            ],
     %w[ nls_date_language          ],
     %w[ nls_sort                   ],
     %w[ nls_territory              ],
     %w[ os_user                    ],
     %w[ policy_enterprise_identity ],
     %w[ policy_invoker             ],
     %w[ proxy_global_uid           ],
     %w[ proxy_user                 ],
     %w[ proxy_userid               ],
     %w[ server_host                ],
     %w[ service_name               ],
     %w[ session_edition_id         ],
     %w[ session_edition_name       ],
     %w[ sessionid                  ],
     %w[ sid                        ],
     %w[ statementid                ],
     %w[ terminal                   ],
     %w[ userenv                    ],
    ].collect! { |a| [ :T, ('qt' + a[0]).to_sym, "&q'%s'" % a[0] ] }

  end


  ############################################################################
  # Method: symbolList
  # Returns the basic dictionary of <GramSyms> for the *Orion* <Grammar>.
  #
  # Method <symbolList> is nothing but a compendium of the defintions of the
  # the symbols needed for the *Orion* <Grammar>. It returns an *Array* of
  # *Array*s. Each internal *Array* describes one potential <GramSym>.

  def symbolList
    reservedWords + keywordList + nonterminalList + terminalList
  end


  ############################################################################
  #
  # Rule definitions
  #
  ############################################################################

  private

  ############################################################################
  # Method: ruleList
  # Returns the list of grammar rules for the *Orion* <Grammar>.
  #
  # Method <ruleList> is nothing but a compendium of all the <GramRules> for
  # the *Orion* <Grammar>. It operates by collecting all the other rule
  # defining methods and then returning their sum.
  #
  # Notes:
  #   - The layout is intentional. The first entry, <sql_statement>, is special
  #     because it defines the whole goal (normally) of the grammar. The last
  #     entry, <metaItems>, deals with the generation interface with the
  #     *SQL* database under test. Ruby rules would regard the expression as
  #     finished (Ruby is line-oriented) if we didn't put the "+" signs at the
  #     end of the lines. The interior entries can be sorted to keep track of
  #     the major entries in the grammar.

  def ruleList
    sql_statement +
      condition +
      expr +
      literals +
      query_block +
      select_statement +
      subquery +
      datatype +
      metaItems +
      plparserLexicalItems
  end


  ############################################################################
  # Method: condition
  # The productions for *SQL* conditions
  #
  # Method <condition> returns the productions for *SQL* conditions.
  #
  # Status:
  #   *INCOMPLETE*
  #
  # Manual Pages:
  #   - Chapter 7

  def condition
    [
      [ :N, :condition, [ :simple_comparison_condition ] ],
      [ :N, :condition, [ :logical_condition ] ],
      [ :N, :condition, [ :in_condition ] ],
      [ :L, :condition, [ :exists_condition ] ],
      [ :M, :condition, [ :between_condition ] ],
      [ :N, :condition, [ :pattern_matching_condition ] ],
      [ :N, :condition, [ :null_condition ] ],
      [ :M, :condition, [ :lparen, :condition, :rparen ], :tightParenRep ],

      [ :N, :simple_comparison_condition, [ :expr_comparison ] ],
      [ :L, :simple_comparison_condition, [ :subquery_comparison ] ],

      [ :N, :expr_comparison, [ :expr, :ordering_operator, :expr ] ],

      [ :N, :subquery_comparison,
            [ :expr, :equality_operator, :parened_subquery ] ],
      [ :N, :subquery_comparison,
            [ :parened_expr_list, :equality_operator, :parened_subquery ] ],

      [ :N, :ordering_operator, [ :equality_operator ] ],
      [ :N, :ordering_operator, [ :inequality_operator ] ],

      [ :N, :equality_operator, [ :equals ] ],
      [ :N, :equality_operator, [ :bang_equal ] ],
      [ :N, :equality_operator, [ :hat_equal ] ],
      [ :N, :equality_operator, [ :box ] ],

      [ :N, :inequality_operator, [ :greater ] ],
      [ :N, :inequality_operator, [ :less ] ],
      [ :N, :inequality_operator, [ :greater_equal ] ],
      [ :N, :inequality_operator, [ :less_equal ] ],

      [ :N, :logical_condition, [ :not, :condition ] ],
      [ :N, :logical_condition, [ :condition, :and, :condition ] ],
      [ :N, :logical_condition, [ :condition, :or,  :condition ] ],

      [ :N, :in_condition,
        [ :expr, :not, :in, :lparen, :expr_list, :rparen ] ],
      [ :L, :in_condition,
        [ :expr, :not, :in, :lparen, :subquery, :rparen ] ],
      [ :N, :in_condition,
        [ :expr,       :in, :lparen, :expr_list, :rparen ] ],
      [ :L, :in_condition,
        [ :expr,       :in, :lparen, :subquery, :rparen ] ],
      [ :N, :in_condition,
        [:parened_expr_list, :not, :in, :lparen, :parened_expr_list, :rparen]],
      [ :L, :in_condition,
        [ :parened_expr_list, :not, :in, :lparen, :subquery, :rparen ] ],
      [ :N, :in_condition,
        [:parened_expr_list,       :in, :lparen, :parened_expr_list, :rparen]],
      [ :L, :in_condition,
        [ :parened_expr_list,       :in, :lparen, :subquery, :rparen ] ],

      [ :N, :between_condition, [ :expr,       :between, :expr, :and, :expr ]],
      [ :N, :between_condition, [ :expr, :not, :between, :expr, :and, :expr ]],

      [ :N, :exists_condition, [ :exists, :parened_subquery ] ],

      # Pattern matching conditions

      [ :N, :pattern_matching_condition, [ :like_condition ] ],

      [ :N, :like_condition,
        [ :expr, :not, :like_operator, :expr, :escape, :expr ] ],
      [ :N, :like_condition,
        [ :expr,       :like_operator, :expr, :escape, :expr ] ],
      [ :N, :like_condition,
        [ :expr, :not, :like_operator, :expr                 ] ],
      [ :N, :like_condition,
        [ :expr,       :like_operator, :expr,                ] ],

      [ :N, :like_operator, [ :like  ] ],
      [ :N, :like_operator, [ :likec ] ],
      [ :N, :like_operator, [ :like2 ] ],
      [ :N, :like_operator, [ :like4 ] ],

      # Null condition

      [ :N, :null_condition, [ :expr, :is, :not, :null ] ],
      [ :N, :null_condition, [ :expr, :is,       :null ] ],

    ]
  end


  ############################################################################
  # Method: expr
  # The productions for *SQL* expressions
  #
  # Method <expr> returns the productions for *SQL* expressions.
  #
  # Status:
  #   *INCOMPLETE*
  #
  # Manual Pages:
  #   - Chapter 6

  def expr
    [
      [ :N, :expr, [ :simple_expression          ] ],
      [ :M, :expr, [ :compound_expr              ] ],
      [ :N, :expr, [ :function_expression        ] ],
      [ :L, :expr, [ :case_expression            ] ],
      [ :L, :expr, [ :scalar_subquery_expression ] ],
      [ :L, :expr, [ :datetime_expression        ] ],


      # Simple expressionsxs

      [ :N, :simple_expression, [ :expr_column   ], :squeezeBlanks ],
      [ :L, :simple_expression, [ :rownum        ] ],
      [ :M, :simple_expression, [ :string        ] ],
      [ :M, :simple_expression, [ :numeric_value ] ],
      [ :L, :simple_expression, [ :null          ] ],
      [ :L, :simple_expression, [ :sequence_expr ] ],

      [ :L, :expr_column, [ :query_ref, :dot, :column_ref ] ],
      [ :L, :expr_column, [ :query_ref, :dot, :rowid      ] ],
      [ :N, :expr_column, [ :column_ref                    ], :columnRefRep ],
      [ :L, :expr_column, [ :rowid                         ] ],
      [ :N, :expr_column, [ :table_ref, :dot, :column_ref  ],
            :columnTableRefRep],
      [ :L, :expr_column, [ :table_ref, :dot, :rowid       ] ],
      [ :L, :expr_column, [ :view_ref,  :dot, :column_ref      ] ],
      [ :L, :expr_column, [ :view_ref,  :dot, :rowid       ] ],
      [ :L, :expr_column, [ :materialized_view_ref, :dot, :column_ref ] ],
      [ :L, :expr_column, [ :materialized_view_ref, :dot, :rowid  ] ],
      [ :N, :expr_column,
            [ :schema_ref, :dot, :table_ref, :dot, :column_ref  ],
            :columnTableSchemaRefRep ],
      [ :L, :expr_column,
            [ :schema_ref, :dot, :table_ref, :dot, :rowid       ] ],
      [ :L, :expr_column,
            [ :schema_ref, :dot, :view_ref,  :dot, :column_ref      ] ],
      [ :L, :expr_column,
            [ :schema_ref, :dot, :view_ref,  :dot, :rowid       ] ],
      [ :L, :expr_column,
            [ :schema_ref, :dot, :materialized_view_ref, :dot, :column_ref ] ],
      [ :L, :expr_column,
            [ :schema_ref, :dot, :materialized_view_ref, :dot, :rowid  ] ],

      [ :N, :query_ref, [ :ident ], :queryRefRep ],
      [ :N, :view_ref, [ :ident ], :viewRefRep ],
      [ :N, :materialized_view_ref, [ :ident ] ],

      [ :N, :sequence_expr, [ :sequence_name, :dot, :currval ],
            :squeezeBlanks],
      [ :N, :sequence_expr, [ :sequence_name, :dot, :nextval ],
            :squeezeBlanks],

      # Compound expressions

      [ :N, :compound_expr, [ :parened_expr               ] ],
      [ :M, :compound_expr, [ :expr, :plus, :expr         ] ],
      [ :M, :compound_expr, [ :expr, :minus_sign, :expr   ] ],
      [ :M, :compound_expr, [ :expr, :asterisk, :expr     ], :tightOperRep ],
      [ :M, :compound_expr, [ :expr, :slash, :expr        ], :tightOperRep ],
      [ :M, :compound_expr, [ :expr, :strokestroke, :expr ] ],
      [ :L, :compound_expr, [ :plus, :expr                ], :tightUnaryRep ],
      [ :L, :compound_expr, [ :minus_sign, :expr          ], :tightUnaryRep ],
      [ :L, :compound_expr, [ :prior, :expr               ] ],

      [ :N, :parened_expr, [ :lparen, :expr, :rparen ], :tightParenRep ],

      [ :N, :expr_list, [ :expr ] ],
      [ :L, :expr_list, [ :expr_list, :comma, :expr_list ], :betterCommas ],

      [ :N, :parened_expr_list, [ :lparen, :expr_list, :rparen ],
            :tightParenRep ],

      [ :N, :parened_expr_list2_element, [ :expr_list ] ],
      [ :N, :parened_expr_list2_element, [ :parened_expr_list ] ],

      [ :N, :parened_expr_list2_body, [ :parened_expr_list2_element ] ],
      [ :L, :parened_expr_list2_body,
        [ :parened_expr_list2_body, :comma, :parened_expr_list2_element ] ],

      [ :N, :parened_expr_list2,
        [ :lparen, :parened_expr_list2_body, :rparen ], :tightParenRep ],

      # Function expressions

      [ :N, :function_expression, [ :function ] ],

      # CASE expressions

      [ :N, :case_expression,
        [ :case, :simple_case_expression,   :else_clause, :end ] ],
      [ :N, :case_expression,
        [ :case, :simple_case_expression,                 :end ] ],
      [ :N, :case_expression,
        [ :case, :searched_case_expression, :else_clause, :end ] ],
      [ :N, :case_expression,
        [ :case, :searched_case_expression,               :end ] ],

      [ :N, :simple_case_expression, [ :expr, :simple_case_clause ] ],
      [ :L, :simple_case_expression,
        [ :simple_case_expression, :simple_case_clause ] ],

      [ :N, :simple_case_clause, [ :when, :expr, :then, :expr ] ],

      [ :N, :searched_case_expression, [ :searched_case_clause ] ],
      [ :L, :searched_case_expression,
        [ :searched_case_expression, :searched_case_clause ] ],

      [ :N, :searched_case_clause, [ :when, :condition, :then, :expr ] ],

      [ :N, :else_clause, [ :else, :expr ] ],

      [ :N, :scalar_subquery_expression, [ :parened_subquery ] ],

      # Date time expressions

      [ :N, :datetime_expression, [ :expr, :at, :local ] ],
      [ :N, :datetime_expression, [ :expr, :at, :time, :zone, :dbtimezone ] ],
      [ :N, :datetime_expression,
        [ :expr, :at, :time, :zone, :sessiontimezone ] ],
      [ :N, :datetime_expression, [ :expr, :at, :time, :zone, :expr ] ],

      # Special cases of expr lists

      [ :N, :parened_two_exprs, [ :parened_two_exprs_list ], :betterCommas ],
      [ :N, :parened_two_exprs_body, [ :expr, :comma, :expr ] ],
      [ :N, :parened_two_exprs_list,
        [ :lparen, :parened_two_exprs_body, :rparen ], :tightParenRep ],

      [ :N, :parened_three_exprs,
        [ :parened_three_exprs_list ], :betterCommas],
      [ :N, :parened_three_exprs_body,
        [ :expr, :comma, :expr, :comma, :expr ] ],
      [ :N, :parened_three_exprs_list,
        [ :lparen, :parened_three_exprs_body, :rparen ], :tightParenRep ],

      [ :N, :parened_four_exprs,
        [ :parened_four_exprs_list ], :betterCommas],
      [ :N, :parened_four_exprs_body,
        [ :expr, :comma, :expr, :comma, :expr, :comma, :expr ] ],
      [ :N, :parened_four_exprs_list,
        [ :lparen, :parened_four_exprs_body, :rparen ], :tightParenRep ],

    ] +

      function
  end


  ############################################################################
  # Method: from_part
  # Productions for the *Orion* nonterminal from_part.
  #
  # Method <from_part> contains the productions for the nonterminals from_part
  # that has been introduced by *Orion*.

  def from_part
    [
      [ :N, :from_part, [ :from, :from_clause ], :betterCommas ],

      [ :N, :from_clause, [ :from_list ] ],

      [ :N, :from_list, [ :from_item ] ],
      [ :L, :from_list, [ :from_list, :comma, :from_item ] ],

      [ :N, :from_item, [ :table_reference ] ],
      [ :L, :from_item, [ :join_clause ] ],
      [ :L, :from_item, [ :lparen, :join_clause, :rparen ], :tightParenRep ],

      # Definition of table_refernence

      [ :N, :table_reference, [ :table_reference_head ] ],
      [ :N, :table_reference,
        [ :table_reference_head, :table_reference_tail ] ],
      [ :L, :table_reference, [ :table_name, :at_sign, :remote_db_name ] ],
      [ :L, :table_reference,
        [ :table_name, :at_sign, :remote_db_name, :table_reference_tail ] ],

      # HACK: Remote db names are certainly more complicated than this.

      [ :N, :remote_db_name, [ :loop ] ],

      [ :L, :table_reference_head,
        [ :only, :lparen, :query_table_expression, :rparen ], :tightParenRep ],
      [ :N, :table_reference_head, [ :query_table_expression ] ],

      # HACK: Until pivot clauses are defined.

      # [ :N, :table_reference_head, 
      #  [ :query_table_expression, :pivot_clause ] ],
      # [ :N, :table_reference_head,
      #  [ :query_table_expression, :unpivot_clause ] ],

      # HACK: Pivot clauses need definition.

      # [ :N, :pivot_clause,   [ ] ],
      # [ :N, :unpivot_clause, [ ] ],

      # HACK: Definition for flashback_query_clause needed.

      # [ :N, :table_reference_tail, [ :flashback_query_clause ] ],
      [ :N, :table_reference_tail, [ :table_alias_definition ] ],
      # [ :N, :table_reference_tail,
      #  [ :flashback_query_clause, :table_alias_definition ] ],

      # HACK: Flashback query clause needs definition.

      # [ :N, :flashback_query_clause, [ ] ],

      [ :N, :table_alias_definition, [:ident], :tableAliasRep, :tableAliasGen ],

      # Definition of query_table_expression

      [ :L, :query_table_expression, [ :query_name], :queryRefRep ],
      [ :N, :query_table_expression, [ :qtab_expr_part2 ] ],
      [ :L, :query_table_expression, [ :qtab_expr_part3 ] ],
      [ :L, :query_table_expression, [ :table_collection_expression ] ],

      # HACK: Sample clause needs definitions

      [ :N, :qtab_expr_part2, [ :qtab_expr_part2_head ] ],
      # [ :M, :qtab_expr_part2, [ :qtab_expr_part2_head, :sample_clause ] ],

      [ :N, :qtab_expr_part2_head, [ :qtab_expr_name_use ], :squeezeBlanks ],

      [ :N, :qtab_expr_name_use, [ :table_name_use ] ],
      [ :N, :qtab_expr_name_use, [ :schema_name_use, :dot, :table_name_use ] ],

      [ :N, :table_name_use, [ :ident ], :tableNameRep, :tableNameGen ],
      [ :N, :schema_name_use, [ :ident ], :schemaNameRep, :schemaNameGen ],

      # HACK: Sample clause needs definition

      # [ :N, :sample_clause, [ ] ],

      [ :N, :qtab_expr_part3,
        [ :lparen, :subquery, :rparen ], :tightParenRep ],
      [ :N, :qtab_expr_part3,
        [ :lparen, :subquery, :subquery_restriction_clause, :rparen ] ],

      [ :N, :subquery_restriction_clause, [ :with, :read, :only ] ],
      [ :N, :subquery_restriction_clause, [ :with, :check, :option ] ],
      [ :N, :subquery_restriction_clause,
        [ :with, :read, :only, :constraint, :constraint_name ] ],
      [ :N, :subquery_restriction_clause,
        [ :with, :check, :option, :constraint, :constraint_name ] ],

      [ :N, :constraint_name, [ :ident ] ],

      # Table collection expression

      [ :N, :table_collection_expression, [ :tce_head ] ],
      [ :N, :table_collection_expression,
        [ :tce_head, :tce_plus ], :tightUnaryRep ],

      [ :N, :tce_head, [ :table, :parened_expr ], :tightUnaryRep ],

      [ :N, :tce_plus, [ :lparen, :plus, :rparen ], :tightParenRep ],

      # Join clause definitioin

      [ :N, :join_clause, [ :table_reference, :join_clause_list ] ],

      [ :N, :join_clause_list, [ :join_clause_element ] ],
      [ :L, :join_clause_list, [ :join_clause_list, :join_clause_element ] ],

      [ :N, :join_clause_element, [ :inner_cross_join_clause ] ],
      [ :N, :join_clause_element, [ :outer_join_clause ] ],

      [ :N, :inner_cross_join_clause, [ :upper_icjc ] ],
      [ :N, :inner_cross_join_clause, [ :lower_icjc ] ],

      [ :N, :upper_icjc, [ :upper_icjc_head, :upper_icjc_on_condition    ] ],
      [ :N, :upper_icjc, [ :upper_icjc_head, :upper_icjc_using_condition ] ],

      [ :N, :upper_icjc_head, [ :inner, :join, :table_reference ] ],
      [ :N, :upper_icjc_head, [         :join, :table_reference ] ],

      [ :N, :upper_icjc_on_condition, [ :on, :condition ] ],

      [ :N, :upper_icjc_using_condition,
        [ :using, :lparen, :upper_icjc_column_ref_list, :rparen ] ],

      [ :N, :upper_icjc_column_ref_list, [ :column_ref ] ],
      [ :L, :upper_icjc_column_ref_list,
        [ :upper_icjc_column_ref_list, :comma, :column_ref ] ],

      [ :N, :outer_join_clause, [ :cross, :join, :table_reference ] ],
      [ :N, :outer_join_clause, [ :natural, :join, :table_reference ] ],
      [ :N, :outer_join_clause,
        [ :natural, :inner, :join, :table_reference ] ],

      [ :N, :outer_join_clause, [ :ojc_part2, :ojc_part3 ] ],
      [ :N, :outer_join_clause,
        [ :query_partition_clause, :ojc_part2, :ojc_part3 ] ],
      [ :N, :outer_join_clause, [ :ojc_part2, :ojc_part3, :ojc_part4 ] ],
      [ :N, :outer_join_clause,
        [ :query_partition_clause, :ojc_part2, :ojc_part3, :ojc_part4 ] ],

      [ :N, :ojc_part2, [ :outer_join_type, :join ] ],
      [ :N, :ojc_part2, [ :natural, :join         ] ],
      [ :N, :ojc_part2, [ :natural, :outer_join_type, :join ] ],

      [ :N, :ojc_part3, [ :table_reference ] ],
      [ :N, :ojc_part3, [ :table_reference, :query_partition_clause ] ],

      [ :N, :ojc_part4, [ :upper_icjc_on_condition ] ],
      [ :N, :ojc_part4, [ :upper_icjc_using_condition ] ],

      [ :N, :outer_join_type, [ :full,  :outer ] ],
      [ :N, :outer_join_type, [ :left,  :outer ] ],
      [ :N, :outer_join_type, [ :right, :outer ] ],
      [ :N, :outer_join_type, [ :full  ] ],
      [ :N, :outer_join_type, [ :left  ] ],
      [ :N, :outer_join_type, [ :right ] ],

      [ :N, :query_partition_clause, [ :partition, :by, :parened_expr_list ] ],

    ]

  end


  ############################################################################
  # Method: function
  # The productions for the *SQL* builtin functions
  #
  # Method <function> returns the productions for the *SQL* builtin functions
  # (and special cases like PL/SQL calls).

  def function
    [
      [ :N, :function, [ :aggregate_function    ] ],
      [ :L, :function, [ :analytic_function     ] ],
      [ :N, :function, [ :character_function    ] ],
      [ :N, :function, [ :conversion_function   ] ],
      [ :N, :function, [ :null_related_function ] ],
      [ :N, :function, [ :environment_function  ] ],
      [ :N, :function, [ :single_row_function   ] ],
      [ :O, :function, [ :user_defined_function ] ],

      # User defined functions

      [ :N, :user_defined_function, [ :udf_call ] ],
      [ :N, :user_defined_function,
        [ :udf_call, :udf_args ], :tightUnaryRep ],

      # HACK: The <ident> in the second production is some kind of dblink.
      #       The syntax in the reference manual is probably messed up. This
      #       will have to do for now.
      # HACK: We need package names for these to make sense in generated code.

      [ :N, :udf_call, [ :udf_name ] ],
      [ :N, :udf_call, [ :udf_name, :at_sign, :ident, :dot ], :squeezeBlanks ],

      [ :N, :udf_name, [ :ident ] ],
      [ :N, :udf_name, [ :ident, :dot, :ident ], :squeezeBlanks ],
      [ :N, :udf_name,
        [ :ident, :dot, :ident, :dot, :ident ], :squeezeBlanks ],

      [ :N, :udf_args, [ :lparen, :rparen ], :squeezeBlanks ],
      [ :N, :udf_args, [ :lparen, :udf_list, :rparen ], :tightParenRep ],

      [ :N, :udf_list, [ :udf_arg ] ],
      [ :N, :udf_list, [ :udf_list, :comma, :udf_arg ], :betterCommas ],

      [ :N, :udf_arg, [ :expr ] ],
      [ :N, :udf_arg, [ :distinct, :expr ] ],
      [ :N, :udf_arg, [ :all, :expr ] ],      

    ] +
      aggregate_function +
      analytic_function +
      character_function +
      conversion_function +
      environment_function +
      null_related_function +
      single_row_function
  end


  ############################################################################
  # Method: aggregate_function
  # The methods for *SQL* aggregate functions.
  #
  # Method <aggregate_function> returns the productions for the *SQL* aggreate
  # functions. These are full of special cases, odd argument patterns, and
  # keywords.

  def aggregate_function
    [
      [ :N, :aggregate_function, [ :count_function ] ],
      [ :N, :aggregate_function, [ :common_aggregate ] ],
      [ :L, :aggregate_function, [ :sys_op_countchg_function ] ],
      [ :L, :aggregate_function, [ :sys_op_trtb_function ] ],

      [ :N, :aggregate_argument, [            :expr ] ],
      [ :N, :aggregate_argument, [ :distinct, :expr ] ],
      [ :N, :aggregate_argument, [ :all,      :expr ] ],

      [ :N, :parened_aggregate_argument,
        [ :lparen, :aggregate_argument, :rparen], :tightParenRep ],

      # HACK: not used for now.

#      [ :N, :aggregate_arg_list, [ :aggregate_argument ] ],
#      [ :M, :aggregate_arg_list,
#            [ :aggregate_arg_list, :comma, :aggregate_argument ] ],

      [ :N, :aggregate_func_over_clause,
        [ :over, :parened_analytic_clause ], :tightUnaryRep ],

      # COUNT function. Notice * version of argument.

      [ :N, :count_function, [ :count_head ] ],
      [ :N, :count_function, [ :count_head, :aggregate_func_over_clause ] ],

      [ :N, :count_head, [ :count, :count_tail ], :tightUnaryRep ],

      [ :N, :count_tail, [ :parened_aggregate_argument ] ],
      [ :N, :count_tail, [ :lparen, :asterisk, :rparen ], :tightParenRep ],

      # Common aggregate functions:
      #  AVG, MAX, MIN, SUM

      [ :N, :common_aggregate, [ :common_aggr_head ] ],
      [ :M, :common_aggregate,
        [ :common_aggr_head, :aggregate_func_over_clause ] ],

      [ :N, :common_aggr_head,
        [ :common_aggr_name, :parened_aggregate_argument ], :tightUnaryRep ],

      [ :N, :common_aggr_name, [ :avg ] ],
      [ :N, :common_aggr_name, [ :max ] ],
      [ :N, :common_aggr_name, [ :min ] ],
      [ :N, :common_aggr_name, [ :sum ] ],

      # SYS_OP_COUNTCHG function

      [ :N, :sys_op_countchg_function,
        [ :sys_op_countchg, :parened_two_exprs ], :tightUnaryRep ],

      # SYS_OP_TRTB function

      [ :N, :sys_op_trtb_function,
        [ :sys_op_trtb, :parened_two_exprs ], :tightUnaryRep ],
      [ :L, :sys_op_trtb_function,
        [ :sys_op_trtb, :parened_three_exprs ], :tightUnaryRep ],
      [ :L, :sys_op_trtb_function,
        [ :sys_op_trtb, :parened_four_exprs ], :tightUnaryRep ],

    ]
  end


  ############################################################################
  # Method: analytic_function
  # The methods for *SQL* analytic functions.
  #
  # Method <analytic_function> returns the productions for the *SQL*
  # analytic functions.

  def analytic_function
    [
      [ :N, :analytic_function, [ :first_value_function ] ],
      [ :N, :analytic_function, [ :rank_analytic_function ] ],

      # Definitions of analytic clauses used in analytic and aggregate functs.

      [ :N, :analytic_clause,  [ :query_partition_clause ] ],
      [ :N, :analytic_clause,  [ :order_by_clause ] ],
      [ :N, :analytic_clause,  [ :order_by_clause, :windowing_clause ] ],
      [ :N, :analytic_clause,
        [ :ac_query_partition_clause, :order_by_clause ] ],
      [ :N, :analytic_clause,
        [ :ac_query_partition_clause, :order_by_clause, :windowing_clause ] ],

      [ :N, :parened_analytic_clause,
        [ :lparen, :analytic_clause, :rparen ], :tightParenRep ],

      # HACK: Clauses needs completion.

      [ :N, :ac_query_partition_clause, [ :partition, :by, :expr_list ] ],

      [ :N, :windowing_clause, [ :wc_front, :wc_upper ] ],
      [ :N, :windowing_clause, [ :wc_front, :wc_lower ] ],

      [ :N, :wc_front, [ :rows  ] ],
      [ :N, :wc_front, [ :range ] ],

      [ :N, :wc_upper, [ :between, :wc_upper1, :and, :wc_upper2 ] ],

      [ :N, :wc_upper1, [ :wc_lower ] ],
      [ :N, :wc_upper1, [ :wc_expr, :following ] ],

      [ :N, :wc_upper2, [ :unbounded, :following ] ],
      [ :N, :wc_upper2, [ :current,   :row       ] ],
      [ :N, :wc_upper2, [ :wc_expr,   :preceding ] ],
      [ :N, :wc_upper2, [ :wc_expr,   :following ] ],

      [ :N, :wc_lower, [ :unbounded, :preceding ] ],
      [ :N, :wc_lower, [ :current,   :row       ] ],
      [ :N, :wc_lower, [ :wc_expr,   :preceding ] ],

      [ :N, :wc_expr, [ :expr ] ],

      # The FIRST_VALUE function

      [ :N, :first_value_function,
        [ :first_value_upper, :aggregate_func_over_clause ] ],
      [ :N, :first_value_function,
        [ :first_value_upper_head, :aggregate_func_over_clause ] ],
      [ :N, :first_value_function,
        [ :first_value_lower, :aggregate_func_over_clause ] ],

      [ :N, :first_value_upper_head,
        [ :first_value, :parened_expr ], :tightUnaryRep ],

      [ :N, :first_value_upper, [ :first_value_upper_head, :respect, :nulls ]],
      [ :N, :first_value_upper, [ :first_value_upper_head, :ignore,  :nulls ]],

      [ :N, :first_value_lower,
         [:first_value, :first_value_lower_item ], :tightUnaryRep ],

      [ :N, :first_value_lower_arg, [ :expr, :respect, :nulls ] ],
      [ :N, :first_value_lower_arg, [ :expr, :ignore,  :nulls ] ],
      [ :N, :first_value_lower_arg, [ :expr                   ] ],

      [ :N, :first_value_lower_item,
        [ :lparen, :first_value_lower_arg, :rparen ], :tightParenRep ],

     # The RANK analytic function

      [ :N, :rank_analytic_function,
        [ :rank, :lparen, :rparen, :over,
          :lparen, :query_partition_clause, :order_by_clause, :rparen ] ],

      [ :N, :rank_analytic_function,
        [ :rank, :lparen, :rparen, :over,
          :lparen,                          :order_by_clause, :rparen ] ],
    ]

  end


  ############################################################################
  # Method: character_function
  # The rules for *SQL* character functions.
  #
  # Method <character_function> returns the productions for the *SQL*
  # character functions.

  def character_function
    [
      [ :N, :character_function, [ :ltrim_function ] ],

      [ :N, :ltrim_function, [ :ltrim, :parened_expr      ], :tightUnaryRep ],
      [ :N, :ltrim_function, [ :ltrim, :parened_two_exprs ], :tightUnaryRep ],
    ]
  end


  ############################################################################
  # Method: conversion_function
  # The rules for *SQL* conversion functions.
  #
  # Method <conversion_function> returns the productions for the *SQL*
  # conversion functions.

  def conversion_function
    [
      [ :N, :conversion_function, [ :to_char_function ] ],
      [ :L, :conversion_function, [ :last_day_function ] ],

      # TO_CHAR/TO_NCHAR/TO_DATE/TO_NUMBER function

      [ :N, :to_char_function,
        [ :to_char_name, :to_char_arglist ], :tightUnaryRep ],

      [ :N, :to_char_name, [ :to_char   ] ],
      [ :N, :to_char_name, [ :to_nchar  ] ],
      [ :N, :to_char_name, [ :to_number ] ],
      [ :L, :to_char_name, [ :to_date   ] ],

      [ :N, :to_char_arglist,
        [ :lparen, :to_char_args, :rparen ], :tightParenRep ],

      [ :N, :to_char_args, [ :expr ] ],
      [ :L, :to_char_args, [ :expr, :comma, :format ], :betterCommas ],
      [ :L, :to_char_args,
        [ :expr, :comma, :format, :comma, :nls_param ], :betterCommas ],

      # Formats and NLS parameters.

      [ :N, :format,    [ :plparser_string ], :formatRep ],
      [ :L, :format,    [ :expr            ] ],
      [ :N, :nls_param, [ :plparser_string ], :nlsParamRep ],
      [ :L, :nls_param, [ :expr            ] ],

      # LAST_DAY function

      [ :N, :last_day_function, [ :last_day, :parened_expr ], :tightUnaryRep ],

    ]
  end


  ############################################################################
  # Method: environment_function
  # The rules for *SQL* environment functions.

  def environment_function
    [
      [ :N, :environment_function, [ :userenv_function ] ],
      [ :N, :environment_function, [ :sys_context_function ] ],

      # USERENV function

      [ :N, :userenv_function, [ :userenv, :userenv_parens ], :tightUnaryRep ],

      [ :N, :userenv_parens,
        [ :lparen, :userenv_param, :rparen ], :tightParenRep],

      [ :L, :userenv_param, [ :expr ] ],
      [ :N, :userenv_param, [ :qtclient_info ], :tickKeywordRep ],
      [ :N, :userenv_param, [ :qtentryid     ], :tickKeywordRep ],
      [ :N, :userenv_param, [ :qtisdba       ], :tickKeywordRep ],
      [ :N, :userenv_param, [ :qtlang        ], :tickKeywordRep ],
      [ :N, :userenv_param, [ :qtlanguage    ], :tickKeywordRep ],
      [ :N, :userenv_param, [ :qtsessionid   ], :tickKeywordRep ],
      [ :N, :userenv_param, [ :qtsid         ], :tickKeywordRep ],
      [ :N, :userenv_param, [ :qtterminal    ], :tickKeywordRep ],

      # SYS_CONTEXT function

      [ :N, :sys_context_function,
            [ :sys_context, :sys_context_params ], :tightUnaryRep ] ,

      [ :N, :sys_context_params,
        [ :lparen, :scp_userenv_params, :rparen ], :tightParenRep ],
      [ :L, :sys_context_params, [ :parened_two_exprs ] ],
      [ :L, :sys_context_params, [ :parened_three_exprs ] ],

      [ :N, :scp_userenv_params,
        [ :scp_userenv, :comma, :scp_keyword ], :betterCommas ],
      [ :M, :scp_userenv_params,
        [ :scp_userenv, :comma, :scp_keyword, :comma, :expr ],
        :betterCommas ],

      [ :N, :scp_userenv, [ :qtuserenv ], :tickKeywordRep ],

      [ :O, :scp_keyword, [ :string ] ],
      [ :N, :scp_keyword, [ :qtaction ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtaudited_cursorid ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtauthenticated_identity ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtauthentication_data ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtauthentication_method ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtbg_job_id ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtclient_identifier ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtclient_info ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtcurrent_bind ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtcurrent_edition_id ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtcurrent_edition_name ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtcurrent_schema ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtcurrent_schema_id ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtcurrent_sql ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtcurrent_sql_length ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtcurrent_user ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtcurrent_userid ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtdatabase_role ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtdb_domain ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtdb_name ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtdb_unique_name ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtdblink_info ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtentryid ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtenterprise_identity ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtfg_job_id ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtglobal_context_memory ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtglobal_uid ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qthost ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtidentification_type ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtinstance ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtinstance_name ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtip_address ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtisdba ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtlang ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtlanguage ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtmodule ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtnetwork_protocol ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtnls_calendar ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtnls_currency ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtnls_date_format ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtnls_date_language ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtnls_sort ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtnls_territory ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtos_user ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtpolicy_invoker ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtpolicy_enterprise_identity ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtproxy_global_uid ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtproxy_user ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtproxy_userid ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtserver_host ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtservice_name ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtsession_edition_id ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtsession_edition_name ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtsessionid ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtsid ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtstatementid ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtterminal ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtauthentication_type ], :tickKeywordRep ],
      [ :N, :scp_keyword, [ :qtexternal_name ], :tickKeywordRep ],

    ]
  end


  ############################################################################
  # Method: null_related_function
  # The rules for *SQL* null related functions.

  def null_related_function
    [
      [ :M, :null_related_function, [ :decode_function ] ],
      [ :M, :null_related_function, [ :nvl_function ] ],
      [ :O, :null_related_function, [ :sys_op_map_nonnull_function ] ],

      # Decode function

      [ :N, :decode_function, [ :decode, :decode_tail ], :tightUnaryRep ],

      [ :N, :decode_tail, [ :lparen, :decode_args, :rparen ], :tightParenRep ],

      [ :N, :decode_args, [ :expr, :comma, :decode_pair_list ] ],
      [ :M, :decode_args, [ :expr, :comma, :decode_pair_list, :comma, :expr ]],

      [ :N, :decode_pair_list, [ :expr, :comma, :expr ], :betterCommas ],
      [ :L, :decode_pair_list,
        [ :decode_pair_list, :comma, :expr, :comma, :expr ], :betterCommas ],

      # NVL functions

      [ :N, :nvl_function, [ :nvl,  :parened_two_exprs   ], :tightUnaryRep ],
      [ :N, :nvl_function, [ :nvl2, :parened_three_exprs ], :tightUnaryRep ],

      # SYS_OP_MAP_NONNULL is undocumented.

      [ :N, :sys_op_map_nonnull_function,
        [ :sys_op_map_nonnull, :parened_expr ], :tightUnaryRep ],

    ]
  end


  ############################################################################
  # Method: single_row_function
  # The rules for *SQL* single row functions.

  def single_row_function
    [
      [ :N, :single_row_function, [ :bitand_function ] ],
      [ :N, :single_row_function, [ :cast_function   ] ],
      [ :N, :single_row_function, [ :lower_function  ] ],
      [ :N, :single_row_function, [ :round_function  ] ],
      [ :N, :single_row_function, [ :trunc_function  ] ],
      [ :N, :single_row_function, [ :upper_function  ] ],

      [ :N, :bitand_function,
        [ :bitand, :parened_two_exprs ], :tightUnaryRep ],

      [ :N, :cast_function, [ :cast, :cast_argument_list ], :tightUnaryRep ],

      [ :N, :cast_argument_list,
        [ :lparen, :cast_argument, :rparen ], :tightParenRep ],

      [ :N, :cast_argument, [ :expr, :as, :cast_type_name ] ],
      [ :N, :cast_argument,
        [ :multiset, :lparen, :subquery , :rparen, :as, :cast_type_name ] ],

      [ :N, :cast_type_name, [ :datatype ] ],

      # HACK: We don't have a good way to generate user defined types yet.

      [ :L, :cast_type_name, [ :type_identifier ] ],
      [ :N, :type_identifier, [ :ident ] ],

      [ :N, :lower_function, [ :lower, :parened_expr ], :tightUnaryRep ],

      [ :N, :round_function, [ :round, :parened_expr      ], :tightUnaryRep ],
      [ :N, :round_function, [ :round, :parened_two_exprs ], :tightUnaryRep ],

      [ :N, :trunc_function, [ :trunc, :parened_expr      ], :tightUnaryRep ],
      [ :N, :trunc_function, [ :trunc, :parened_two_exprs ], :tightUnaryRep ],

      [ :N, :upper_function, [ :upper, :parened_expr ], :tightUnaryRep ],
    ]
  end


  ############################################################################
  # Method: datatype
  # The productions for the *SQL* datatypes

  def datatype
    [
     [ :N, :datatype, [ :oracle_built_in_datatype ] ],
     [ :N, :datatype, [ :ansi_supported_datatype  ] ],
     [ :O, :datatype, [ :user_defined_type        ] ],
     [ :N, :datatype, [ :oracle_supplied_type     ] ],

     # Built in types

     [ :N, :oracle_built_in_datatype, [ :character_datatype    ] ],
     [ :N, :oracle_built_in_datatype, [ :number_datatype       ] ],
     [ :N, :oracle_built_in_datatype, [ :long_and_raw_datatype ] ],
     [ :N, :oracle_built_in_datatype, [ :datetime_datatype     ] ],
     [ :N, :oracle_built_in_datatype, [ :large_object_datatype ] ],
     [ :N, :oracle_built_in_datatype, [ :rowid_datatype        ] ],

     # Character types

     [ :N, :character_datatype, [ :char_datatype      ] ],
     [ :N, :character_datatype, [ :varchar2_datatype  ] ],
     [ :N, :character_datatype, [ :nchar_datatype     ] ],
     [ :N, :character_datatype, [ :nvarchar2_datatype ] ],

     [ :N, :char_datatype, [ :char ] ],
     [ :N, :char_datatype, [ :char, :cv_size_spec ], :tightUnaryRep ],

     [ :N, :cv_size_spec, [:lparen, :cv_size_value, :rparen], :tightParenRep ],
      
     [ :N, :cv_size_value, [ :medium_limit        ] ],
     [ :N, :cv_size_value, [ :medium_limit, :byte ] ],
     [ :N, :cv_size_value, [ :medium_limit, :char ] ],

     [ :N, :varchar2_datatype, [ :varchar2, :cv_size_spec ], :tightUnaryRep ],

     [ :N, :nchar_datatype, [ :nchar ] ],
     [ :N, :nchar_datatype, [ :nchar, :nchar_size_spec ], :tightUnaryRep ],

     [ :N, :nvarchar2_datatype,
       [ :nvarchar2, :nchar_size_spec ], :tightUnaryRep ],

     [ :N, :nchar_size_spec,
       [ :lparen, :medium_limit, :rparen ], :tightParenRep ],

     # Number types

     [ :N, :number_datatype, [ :number_type   ] ],
     [ :N, :number_datatype, [ :float_type    ] ],
     [ :N, :number_datatype, [ :binary_float  ] ],
     [ :N, :number_datatype, [ :binary_double ] ],

     [ :N, :number_type, [ :number ] ],
     [ :N, :number_type, [ :number, :number_prec_scale ], :tightUnaryRep ],

     [ :N, :number_prec_scale,
       [ :lparen, :number_ps_values, :rparen ], :tightParenRep ],

     [ :N, :number_ps_values, [ :small_limit] ],
     [ :N, :number_ps_values,
       [ :small_limit, :comma, :small_limit ], :betterCommas ],

     [ :N, :float_type, [ :float ] ],
     [ :N, :float_type, [ :float, :float_prec ], :tightUnaryRep ],
     
     [ :N, :float_prec, [ :lparen, :small_limit, :rparen ], :tightParenRep ],

     # Long and raw datatypes

     [ :N, :long_and_raw_datatype, [ :long ] ],
     [ :N, :long_and_raw_datatype, [ :long, :raw ] ],
     [ :N, :long_and_raw_datatype, [ :long, :long_size ], :tightUnaryRep ],

     [ :N, :long_size, [ :lparen, :large_limit, :rparen ], :tightParenRep ],

     # Date/time data types.

     [ :N, :datetime_datatype, [ :date ] ],
     [ :N, :datetime_datatype, [ :timestamp_type ] ],
     [ :N, :datetime_datatype, [ :int_year_type ] ],
     [ :N, :datetime_datatype, [ :int_day_type ] ],

     [ :N, :timestamp_type, [ :timestamp_head ] ],
     [ :N, :timestamp_type, [ :timestamp_head, :with,         :time, :zone ] ],
     [ :N, :timestamp_type, [ :timestamp_head, :with, :local, :time, :zone ] ],

     [ :N, :timestamp_head, [ :timestamp ] ],
     [ :N, :timestamp_head, [ :timestamp, :timestamp_prec ], :tightUnaryRep ],
     
     [ :N, :timestamp_prec, [:lparen, :small_limit, :rparen], :tightParenRep ],

     [ :N, :int_year_type, [ :interval, :year_part, :to, :month ] ],

     [ :N, :year_part, [ :year ] ],
     [ :N, :year_part, [ :year, :year_precision ], :tightUnaryRep ],

     [ :N, :year_precision, [:lparen, :small_limit, :rparen], :tightParenRep ],

     [ :N, :int_day_type, [ :interval, :day_part, :to, :second_part ] ],

     [ :N, :day_part, [ :day ] ],
     [ :N, :day_part, [ :day, :day_precision ], :tightUnaryRep ],

     [ :N, :day_precision, [:lparen, :small_limit, :rparen], :tightParenRep ],

     [ :N, :second_part, [ :second ] ],
     [ :N, :second_part, [ :second, :timestamp_prec ], :tightUnaryRep ],

     # Large object types

     [ :N, :large_object_datatype, [ :blob  ] ],
     [ :N, :large_object_datatype, [ :clob  ] ],
     [ :N, :large_object_datatype, [ :nclob ] ],
     [ :N, :large_object_datatype, [ :bfile ] ],

     # Rowid types

     [ :N, :rowid_datatype, [ :rowid ] ],
     [ :N, :rowid_datatype, [ :urowid ] ],
     [ :N, :rowid_datatype, [ :urowid, :float_prec ], :tightUnaryRep ],

     # ANSI supported datatypes

     [ :N, :ansi_supported_datatype, [ :ansi_character_type ] ],
     [ :N, :ansi_supported_datatype, [ :ansi_char_type      ] ],
     [ :N, :ansi_supported_datatype, [ :ansi_varchar_type   ] ],
     [ :N, :ansi_supported_datatype, [ :ansi_national_type  ] ],
     [ :N, :ansi_supported_datatype, [ :ansi_numeric_type   ] ],
     [ :N, :ansi_supported_datatype, [ :integer             ] ],
     [ :N, :ansi_supported_datatype, [ :int                 ] ],
     [ :N, :ansi_supported_datatype, [ :smallint            ] ],
     [ :N, :ansi_supported_datatype, [ :float_type          ] ],
     [ :N, :ansi_supported_datatype, [ :double, :precision  ] ],
     [ :N, :ansi_supported_datatype, [ :real                ] ],

     # ANSI character type

     [ :N, :ansi_char_size, [:lparen, :medium_limit, :rparen], :tightParenRep],
     
     [ :N, :ansi_vary_clause, [ :varying, :ansi_char_size ], :tightUnaryRep ],

     [ :N, :ansi_character_type,
       [ :character, :ansi_char_size ], :tightUnaryRep ],
     [ :N, :ansi_character_type, [ :character, :ansi_vary_clause ] ],

     # ANSI char type

     [ :N, :ansi_char_type, [ :char,  :ansi_vary_clause ] ],
     [ :N, :ansi_char_type, [ :nchar, :ansi_vary_clause ] ],

     # ANSI varchar type

     [ :N, :ansi_varchar_type, [ :varchar, :ansi_char_size ], :tightUnaryRep ],

     # ANSI national character type

     [ :N, :ansi_national_type, [ :national, :ansi_character_type ] ],
     [ :N, :ansi_national_type, [ :national, :char, :ansi_vary_clause ] ],
     [ :N, :ansi_national_type, [ :national, :national_char_part ] ],

     [ :N, :national_char_part, [ :char, :ansi_char_size ], :tightUnaryRep ],

     # ANSI numeric types

     [ :N, :ansi_numeric_type, [ :numeric ] ],
     [ :N, :ansi_numeric_type,
       [ :numeric, :number_prec_scale ], :tightUnaryRep ],
     [ :N, :ansi_numeric_type, [ :decimal ] ],
     [ :N, :ansi_numeric_type,
       [ :decimal, :number_prec_scale ], :tightUnaryRep ],
     [ :N, :ansi_numeric_type, [ :dec ] ],
     [ :N, :ansi_numeric_type,
       [ :dec, :number_prec_scale], :tightUnaryRep ],

     # Oracle supplied types

     [ :N, :oracle_supplied_type, [ :sys, :dot, :anydata],    :squeezeBlanks ],
     [ :N, :oracle_supplied_type, [ :sys, :dot, :anytype],    :squeezeBlanks ],
     [ :N, :oracle_supplied_type, [ :sys, :dot, :anydataset], :squeezeBlanks ],

     [ :N, :oracle_supplied_type, [ :xmltype ] ],
     [ :N, :oracle_supplied_type, [ :uritype ] ],

     [ :N, :oracle_supplied_type, [ :sdo_geometry      ] ],
     [ :N, :oracle_supplied_type, [ :sdo_topo_geometry ] ],
     [ :N, :oracle_supplied_type, [ :sdo_georaster     ] ],

     [ :N, :oracle_supplied_type, [ :ordaudio ] ],
     [ :N, :oracle_supplied_type, [ :ordimage ] ],
     [ :N, :oracle_supplied_type, [ :ordvideo ] ],
     [ :N, :oracle_supplied_type, [ :orddoc   ] ],
     [ :N, :oracle_supplied_type, [ :orddicom ] ],

     [ :N, :oracle_supplied_type, [ :si_stillimage      ] ],
     [ :N, :oracle_supplied_type, [ :si_averagecolor    ] ],
     [ :N, :oracle_supplied_type, [ :si_positionalcolor ] ],
     [ :N, :oracle_supplied_type, [ :si_colorhistogram  ] ],
     [ :N, :oracle_supplied_type, [ :si_texture         ] ],
     [ :N, :oracle_supplied_type, [ :si_featurelist     ] ],
     [ :N, :oracle_supplied_type, [ :si_color           ] ],     

     # User defined types
     # HACK: need to get these from metadata.

     [ :N, :user_defined_type, [ :ident ] ],

     # Integer literals for the various scale/precision/size slots.

     [ :N, :small_limit,  [ :integer_lit ], :smallIntRep  ],
     [ :N, :medium_limit, [ :integer_lit ], :mediumIntRep ],
     [ :N, :large_limit,  [ :integer_lit ] ], # default rep is OK.

    ]
  end


  ############################################################################
  # Method: literals
  # The productions for the various *SQL* literal forms.
  #
  # Method <literals> returns the productions for *SQL* literals. These are
  # unusual because they are described in text and in examples as well as in
  # productions. Beyond that, this method needs to be concerned with choosing
  # useful representations for generated statements and for a grammar structure
  # that *PLParser* can deal with.
  #
  # Notes:
  #   - Unlike most of the production named methods, there is actually no
  #     nonterminal named "literal".
  #
  # Status:
  #   *INCOMPLETE*
  #
  # Manual Pages:
  #   - Chapter 3

  def literals
    [
     ### HACK: The PLParser grammar needs all the &q'xxx' symbols to also
     ###       become strings. So we list them all here. Eventually, we need
     ###       to find a way to avoid having that listing in two places, one
     ###       here and one up in symbol definition.

     [ :N, :string, [ :tick_string ] ],
     [ :L, :string, [ :qtaction                     ], :tickKeywordRep ],
     [ :L, :string, [ :qtaudited_cursorid           ], :tickKeywordRep ],
     [ :L, :string, [ :qtauthenticated_identity     ], :tickKeywordRep ],
     [ :L, :string, [ :qtauthentication_data        ], :tickKeywordRep ],
     [ :L, :string, [ :qtauthentication_method      ], :tickKeywordRep ],
     [ :L, :string, [ :qtauthentication_type        ], :tickKeywordRep ],
     [ :L, :string, [ :qtbg_job_id                  ], :tickKeywordRep ],
     [ :L, :string, [ :qtclient_identifier          ], :tickKeywordRep ],
     [ :L, :string, [ :qtclient_info                ], :tickKeywordRep ],
     [ :L, :string, [ :qtcurrent_bind               ], :tickKeywordRep ],
     [ :L, :string, [ :qtcurrent_edition_id         ], :tickKeywordRep ],
     [ :L, :string, [ :qtcurrent_edition_name       ], :tickKeywordRep ],
     [ :L, :string, [ :qtcurrent_schema             ], :tickKeywordRep ],
     [ :L, :string, [ :qtcurrent_schema_id          ], :tickKeywordRep ],
     [ :L, :string, [ :qtcurrent_sql                ], :tickKeywordRep ],
     [ :L, :string, [ :qtcurrent_sql_length         ], :tickKeywordRep ],
     [ :L, :string, [ :qtcurrent_user               ], :tickKeywordRep ],
     [ :L, :string, [ :qtcurrent_userid             ], :tickKeywordRep ],
     [ :L, :string, [ :qtdatabase_role              ], :tickKeywordRep ],
     [ :L, :string, [ :qtdb_domain                  ], :tickKeywordRep ],
     [ :L, :string, [ :qtdb_name                    ], :tickKeywordRep ],
     [ :L, :string, [ :qtdb_unique_name             ], :tickKeywordRep ],
     [ :L, :string, [ :qtdblink_info                ], :tickKeywordRep ],
     [ :L, :string, [ :qtenterprise_identity        ], :tickKeywordRep ],
     [ :L, :string, [ :qtentryid                    ], :tickKeywordRep ],
     [ :L, :string, [ :qtexternal_name              ], :tickKeywordRep ],
     [ :L, :string, [ :qtfg_job_id                  ], :tickKeywordRep ],
     [ :L, :string, [ :qtglobal_context_memory      ], :tickKeywordRep ],
     [ :L, :string, [ :qtglobal_uid                 ], :tickKeywordRep ],
     [ :L, :string, [ :qthost                       ], :tickKeywordRep ],
     [ :L, :string, [ :qtidentification_type        ], :tickKeywordRep ],
     [ :L, :string, [ :qtinstance                   ], :tickKeywordRep ],
     [ :L, :string, [ :qtinstance_name              ], :tickKeywordRep ],
     [ :L, :string, [ :qtip_address                 ], :tickKeywordRep ],
     [ :L, :string, [ :qtisdba                      ], :tickKeywordRep ],
     [ :L, :string, [ :qtlang                       ], :tickKeywordRep ],
     [ :L, :string, [ :qtlanguage                   ], :tickKeywordRep ],
     [ :L, :string, [ :qtmodule                     ], :tickKeywordRep ],
     [ :L, :string, [ :qtnetwork_protocol           ], :tickKeywordRep ],
     [ :L, :string, [ :qtnls_calendar               ], :tickKeywordRep ],
     [ :L, :string, [ :qtnls_currency               ], :tickKeywordRep ],
     [ :L, :string, [ :qtnls_date_format            ], :tickKeywordRep ],
     [ :L, :string, [ :qtnls_date_language          ], :tickKeywordRep ],
     [ :L, :string, [ :qtnls_sort                   ], :tickKeywordRep ],
     [ :L, :string, [ :qtnls_territory              ], :tickKeywordRep ],
     [ :L, :string, [ :qtos_user                    ], :tickKeywordRep ],
     [ :L, :string, [ :qtpolicy_enterprise_identity ], :tickKeywordRep ],
     [ :L, :string, [ :qtpolicy_invoker             ], :tickKeywordRep ],
     [ :L, :string, [ :qtproxy_global_uid           ], :tickKeywordRep ],
     [ :L, :string, [ :qtproxy_user                 ], :tickKeywordRep ],
     [ :L, :string, [ :qtproxy_userid               ], :tickKeywordRep ],
     [ :L, :string, [ :qtserver_host                ], :tickKeywordRep ],
     [ :L, :string, [ :qtservice_name               ], :tickKeywordRep ],
     [ :L, :string, [ :qtsession_edition_id         ], :tickKeywordRep ],
     [ :L, :string, [ :qtsession_edition_name       ], :tickKeywordRep ],
     [ :L, :string, [ :qtsessionid                  ], :tickKeywordRep ],
     [ :L, :string, [ :qtsid                        ], :tickKeywordRep ],
     [ :L, :string, [ :qtstatementid                ], :tickKeywordRep ],
     [ :L, :string, [ :qtterminal                   ], :tickKeywordRep ],
     [ :L, :string, [ :qtuserenv                    ], :tickKeywordRep ],

     ### HACK: Leave more compilicated string literals for later.

     [ :N, :tick_string, [ :string_lit ], :tickStringRep ],

     [ :N, :numeric_value, [ :integer_value ] ],
     [ :N, :numeric_value, [ :number_value ] ],
     [ :N, :numeric_value, [ :ieee_value ] ],

     [ :N, :integer_value, [ :integer_lit ], :integerLitRep ],
     [ :N, :number_value,  [ :number_lit  ], :numberLitRep  ],
     [ :N, :ieee_value,    [ :ieee_lit    ], :ieeeLitRep ],
    ]
  end


  ############################################################################
  # Method: metaItems
  # Productions for the *SQL* metadata items.
  #
  # Method <metaItems> contains the rules for the *SQL* items that are
  # governed, one way and another, by metadata. This is a special method
  # because it manages the metadata interaction as well as defining rules and
  # nonterminals. Many of these nonterminals don't actually appear in the
  # *SQL* grammar; they are special-cased to help *Orion* generate better
  # probes.
  #
  # Notes:
  #   - Unlike most of the production methods, there isn't any nonterminal
  #     named metaItems.
  #
  # Status:
  #   *INCOMPLETE*

  def metaItems
    [
      # These are the productions for actual object names. They are defined
      # by the schema(s) under test and are found by simply selecting among
      # those.

      [ :N, :schema_name,            [ :ident ], :schemaNameRep ],
      [ :N, :table_name,             [ :ident ], :tableNameRep ],
      [ :N, :view_name,              [ :ident ], :viewNameRep ],
      [ :N, :materialized_view_name, [ :ident ], :materializedViewNameRep ],
      [ :N, :sequence_name,          [ :ident ], :sequenceNameRep ],
    ]
  end


  ############################################################################
  # Method: query_block
  # The productions for the *SQL* nonterminals query_block.
  #
  # Method <query_block> returns the productions that define the *SQL*
  # nonterminal query_block.
  #
  # Status
  #   *INCOMPLETE*
  #
  # Manual Pages:
  #   - 19-5

  def query_block
    [
      [ :N, :query_block, [ :select_part, :from_part                ] ],
      [ :N, :query_block, [ :select_part, :from_part, :qb_tail ] ],

      [ :N, :qb_tail, [ :where_clause            ] ],
      [ :N, :qb_tail, [ :where_clause, :qb_tail2 ] ],
      [ :N, :qb_tail, [                :qb_tail2 ] ],
      
      [ :N, :qb_tail2, [ :hierarchical_query_clause            ] ],
      [ :N, :qb_tail2, [ :hierarchical_query_clause, :qb_tail3 ] ],
      [ :N, :qb_tail2, [                             :qb_tail3 ] ],
      
      [ :N, :qb_tail3, [ :group_by_clause            ] ],
      [ :N, :qb_tail3, [ :group_by_clause, :qb_tail4 ] ],
      [ :N, :qb_tail3, [                   :qb_tail4 ] ],

      [ :N, :qb_tail4, [ :having_clause                 ] ],
      [ :N, :qb_tail4, [                 :model_clause  ] ],
      [ :N, :qb_tail4, [ :having_clause, :model_clause  ] ],

      [ :N, :where_clause, [ :where, :condition ] ],

      [ :N, :having_clause, [ :having, :condition ] ],

      # Group by clause

      [ :N, :group_by_clause, [ :group, :by, :group_by_part ] ],
      [ :N, :group_by_clause,
        [ :group, :by, :group_by_part, :having, :condition ] ],

      [ :N, :group_by_part, [ :expr ] ],
      [ :N, :group_by_part, [ :rollup_cube_clause ] ],
      [ :N, :group_by_part, [ :grouping_sets_clause ] ],
      [ :M, :group_by_part, [ :group_by_part, :comma, :expr ] ],
      [ :M, :group_by_part, [ :group_by_part, :comma, :rollup_cube_clause ] ],
      [ :M, :group_by_part, [ :group_by_part, :comma, :grouping_sets_clause ]],

      [ :N, :grouping_expression_list, [ :parened_expr_list2 ] ],

      [ :N, :rollup_cube_clause, [ :rollup, :grouping_expression_list ] ],
      [ :N, :rollup_cube_clause, [ :cube,   :grouping_expression_list ] ],

      [ :N, :grouping_sets_clause,
        [ :grouping, :sets, :lparen, :grouping_sets_list, :rparen ] ],

      [ :N, :grouping_sets_list, [ :rollup_cube_clause ] ],
      [ :N, :grouping_sets_list, [ :parened_expr_list2_body ] ],
      [ :L, :grouping_sets_list,
        [ :grouping_sets_list, :comma, :rollup_cube_clause ] ],
      [ :L, :grouping_sets_list,
        [ :grouping_sets_list, :comma, :parened_expr_list2_body ] ],

      # Hierarchical query clause

      [ :N, :hierarchical_query_clause, [ :hqc_connect_by ] ],
      [ :N, :hierarchical_query_clause, [ :hqc_connect_by, :hqc_start ] ],
      [ :N, :hierarchical_query_clause, [ :hqc_start, :hqc_connect_by ] ],

      [ :L, :hqc_connect_by, [ :connect, :by, :nocycle, :hqc_condition ] ],
      [ :N, :hqc_connect_by, [ :connect, :by,           :hqc_condition ] ],

      # A connect by condition must have a PRIOR somewhere.
      # HACK: For the moment, we also have to allow a general condition because
      #       the PRIOR can be way down on a part of an expression and we 
      #       don't have any way to know it's there. THis is unfortunately
      #       terribly ambiguous for recognition but not for generation where
      #       we can force the weight low.

      [ :N, :hqc_condition, [ :prior, :condition ] ],
      [ :M, :hqc_condition, [ :condition,     :and, :hqc_condition ] ],
      [ :M, :hqc_condition, [ :hqc_condition, :and, :condition     ] ],
      [ :O, :hqc_condition, [ :condition ] ],

      [ :N, :hqc_start, [ :start, :with, :condition ] ],

      ### HACK: Most of model clause is not defined yet.

      [ :N, :model_clause, [ :model, :main_model ] ],

      [ :N, :main_model, [ :model_column_clauses, :model_rules_clause ] ],

      [ :N, :model_column_clauses,
        [ :dimension, :by, :left_mcc_list, :measures, :right_mcc_list ] ],

      [ :N, :left_mcc_list,  [ :lparen, :mcc_list, :rparen ], :tightParenRep ],
      [ :N, :right_mcc_list, [ :lparen, :mcc_list, :rparen ], :tightParenRep ],

      [ :N, :mcc_list, [ :mcc_item ] ],
      [ :M, :mcc_list, [ :mcc_list, :comma, :mcc_item ], :betterCommas ],

      [ :N, :mcc_item, [ :expr         ] ], 
      [ :N, :mcc_item, [ :expr, :ident ] ],

      [ :N, :model_rules_clause,
        [ :lparen, :cell_assignment_list, :rparen ], :tightParenRep ],

      [ :N, :cell_assignment_list, [ :cell_item ] ],
      [ :M, :cell_assignment_list,
        [ :cell_assignment_list, :comma, :cell_item ], :betterCommas ],

      [ :N, :cell_item, [ :cell_assignment, :equals, :expr ] ],
      
      [ :N, :cell_assignment,
        [ :measure_column, :lbracket, :ca_item_list, :rbracket ] ],

      [ :N, :measure_column, [ :column_ident ] ],

      [ :N, :ca_item_list, [ :ca_item ] ],
      [ :M, :ca_item_list,
        [ :ca_item_list, :comma, :ca_item ], :betterCommas ],

      [ :N, :ca_item, [ :condition ] ],
      [ :N, :ca_item, [ :expr      ] ],

    ] +
      select_part +
      from_part
  end


  ############################################################################
  # Method: select_part
  # Productions for the *SQL* select_part nonterminal
  #
  # Method <select_part> provides the rules that define the *SQL* select_part
  # nonterminal. Notice that this is a nonterminal introduced by *Orion* to
  # make construction of a query_block more modular
  #
  # Status:
  #   *INCOMPLETE*
  #
  # Manual Pages:
  #   - 19-6

  def select_part
    [
      [ :N, :select_part, [ :select, :select_section ] ],

      [ :N, :select_section, [            :star_select ] ],
      [ :N, :select_section, [ :distinct, :star_select ] ],
      [ :N, :select_section, [ :all,      :star_select ] ],
      [ :N, :select_section, [ :unique,   :star_select ] ],
      [ :N, :select_section, [            :select_list ], :betterCommas ],
      [ :N, :select_section, [ :distinct, :select_list ], :betterCommas ],
      [ :N, :select_section, [ :all,      :select_list ], :betterCommas ],
      [ :N, :select_section, [ :unique,   :select_list ], :betterCommas ],

      [ :N, :star_select, [ :table_alias, :dot, :asterisk ],
            :squeezeBlanks],
      [ :N, :star_select, [ :asterisk ] ],
      [ :N, :table_alias, [ :ident ], :tableAliasRep ],

      [ :N, :select_list, [ :select_list_item ] ],
      [ :L, :select_list, [ :select_list, :comma, :select_list_item ] ],

      [ :L, :select_list_item, [ :select_list_star_item, :dot, :asterisk ],
            :squeezeBlanks ],
      [ :N, :select_list_item, [ :select_expr_item ] ],

      [ :N, :select_list_star_item, [ :query_name ], :queryRefRep ],
      [ :N, :select_list_star_item, [ :select_list_schema_item ] ],

      [ :N, :select_list_schema_item, [ :table_name             ] ],
      [ :N, :select_list_schema_item, [ :view_name              ] ],
      [ :N, :select_list_schema_item, [ :materialized_view_name ] ],
      [ :N, :select_list_schema_item, [ :schema_name, :dot, :table_name ] ],
      [ :N, :select_list_schema_item, [ :schema_name, :dot, :view_name  ] ],
      [ :N, :select_list_schema_item,
            [ :schema_name, :dot, :materialized_view_name ] ],

      [ :N, :select_expr_item, [ :expr ] ],
      [ :N, :select_expr_item, [ :expr, :column_alias_definition ] ],
      [ :N, :select_expr_item, [ :expr, :as, :column_alias_definition ] ],

      [ :N, :column_alias_definition, [ :ident ], :columnAliasRep ],
    ]
  end


  ############################################################################
  # Method: select_statement
  # The list of productions that define the *SELECT* statement.
  #
  # Method <select_statement> simply returns the productions that define the
  # *SQL* *SELECT* statement.
  #
  # Status
  #   *INCOMPLETE*
  #
  # Manual Pages:
  #   - 19-4
  #   - 19-5
  #   - 19-13

  def select_statement
    [
      [ :N, :select_statement, [ :select_body, :end_of_subquery ], :subQueryRep, :subQueryGen ],
      [ :L, :select_statement, [ :subquery_factoring_clause, :select_body, :end_of_subquery ], :subQueryRep, :subQueryGen ],
      [ :L, :select_statement, [ :select_body, :for_update_clause, :end_of_subquery ], :subQueryRep, :subQueryGen ],
      [ :L, :select_statement,
            [ :subquery_factoring_clause, :select_body, :for_update_clause, :end_of_subquery ], :subQueryRep, :subQueryGen ],

      [ :N, :select_body, [ :simple_subquery ] ],
      [ :N, :select_body, [ :simple_subquery, :order_by_clause ] ],

      # For update clause

      [ :N, :for_update_clause, [ :for, :update                       ] ],
      [ :N, :for_update_clause, [ :for, :update, :fu_list             ] ],
      [ :N, :for_update_clause, [ :for, :update, :fu_option           ] ],
      [ :N, :for_update_clause, [ :for, :update, :fu_list, :fu_option ] ],
     
      [ :N, :fu_list, [ :of, :fu_item ] ],
      [ :N, :fu_list, [ :fu_list, :comma, :fu_item ], :betterCommas ],

      [ :N, :fu_item,
        [ :schema_ref, :dot, :table_ref, :dot, :column_ref ], :squeezeBlanks],
      [ :N, :fu_item,
        [ :schema_ref, :dot, :view_ref,  :dot, :column_ref ], :squeezeBlanks],
      [ :N, :fu_item, [ :table_ref, :dot, :column_ref ], :squeezeBlanks],
      [ :N, :fu_item, [ :view_ref,  :dot, :column_ref ], :squeezeBlanks],
      [ :N, :fu_item, [ :column_ref ] ],

      [ :N, :fu_option, [ :nowait        ] ],
      [ :N, :fu_option, [ :wait, :expr   ] ],
      [ :N, :fu_option, [ :skip, :locked ] ],


      # HACK: Incomplete: need full definition.

      [ :N, :subquery_factoring_clause, [ :with, :sqf_list ] ],

      [ :N, :sqf_list, [ :sqf_item ] ],
      [ :L, :sqf_list, [ :sqf_list, :comma, :sqf_item ], :betterCommas ],

      [ :N, :sqf_item, [ :query_name_def, :as, :parened_subquery ] ],
      
      [ :N, :query_name_def, [ :ident ] ],

    ]
  end


  ############################################################################
  # Method: sql_statements
  # The list of productions that define *SQL* statements
  #
  # Method <sql_statement> simply returns the list of the legal statements. The
  # reference sections for these are scattered throughout the manual.
  #
  # Status
  #   *INCOMPLETE*

  def sql_statement
    [
      [ :N, :sql_statement, [ :select_statement ] ],
    ]
  end


  ############################################################################
  # Method: subquery
  # The production list for *SQL* subquerys.
  #
  # Method <subquery> returns the list of productions that define the
  # nonterminal subquery. This method includes rules for those nonterminals
  # that are really just consitutents of a subquery.
  #
  # Status
  #   *INCOMPLETE*
  #
  # Manual Pages:
  #  - 19-5
  #  - 19-13

  def subquery
    [
      [ :N, :subquery, [ :simple_subquery, :end_of_subquery ], :subQueryRep, :subQueryGen ], 
      [ :M, :subquery, [ :simple_subquery, :order_by_clause, :end_of_subquery ], :subQueryRep, :subQueryGen ],

      [ :N, :end_of_subquery, [], :endOfSubqueryRep, :endOfSubqueryGen ],

      [ :N, :simple_subquery, [ :subquery_item ] ],
      [ :M, :simple_subquery,
        [ :simple_subquery, :subquery_expr_operator, :subquery_item ] ],

      [ :N, :subquery_item, [ :query_block ] ],
      [ :N, :subquery_item,
        [ :lparen, :simple_subquery, :rparen ], :tightParenRep ],
 
      [ :N, :subquery_expr_operator, [ :union       ] ],
      [ :N, :subquery_expr_operator, [ :union, :all ] ],
      [ :N, :subquery_expr_operator, [ :intersect   ] ],
      [ :N, :subquery_expr_operator, [ :minus       ] ],

      [ :N, :parened_subquery,
        [ :lparen, :subquery, :rparen ], :tightParenRep ],

      [ :N, :order_by_clause, [ :order_by_part1, :order_by_part2 ] ],

      [ :L, :order_by_part1, [ :order, :siblings, :by ] ],
      [ :N, :order_by_part1, [ :order,            :by ] ],

      [ :N, :order_by_part2, [ :order_by_item ] ],
      [ :M, :order_by_part2, [ :order_by_part2, :comma, :order_by_item ] ],

      [ :N, :order_by_item, [ :order_by_head ] ],
      [ :N, :order_by_item, [ :order_by_head, :order_by_tail ] ],

      [ :N, :order_by_head, [ :expr                ] ],
      [ :N, :order_by_head, [ :order_by_position   ] ],
      [ :N, :order_by_head, [ :column_ref          ] ],

      [ :N, :order_by_tail, [ :asc,  :nulls, :first ] ],
      [ :N, :order_by_tail, [ :desc, :nulls, :first ] ],
      [ :N, :order_by_tail, [        :nulls, :first ] ],
      [ :N, :order_by_tail, [ :asc,  :nulls, :last  ] ],
      [ :N, :order_by_tail, [ :desc, :nulls, :last  ] ],
      [ :N, :order_by_tail, [        :nulls, :last  ] ],
      [ :N, :order_by_tail, [ :asc                  ] ],
      [ :N, :order_by_tail, [ :desc                 ] ],

      [ :N, :order_by_position, [ :integer_lit ] ],
    ]
  end



  ############################################################################
  # Method: plparserLexicalItems
  # The production list to allow *PLParser* to work.
  #
  # Method <plparserLexicalItems> provide the definitions for the lexical terms
  # known by *PLParser*. This ensures that the grammar can be used as a
  # parsing as well as generating grammar. None of these rules have any
  # representation; that should already have been taken care of.

  def plparserLexicalItems

    # Begin by creating a vector of rules for every reserved word. These will
    # define an identifier as a reserved word. For generation purposes we
    # will give these very low probabilities. These rules will be tacked on
    # to the end of the explicit rules.

    idRules = Array.new
    keywordList.each { |p| idRules << [ :L, :ident, [ p[1].to_sym ] ] }

    # Now we have the array of manual rules.

    [
      # HACK: For the time being, we won't try to generate many quoted ID's.

      [ :N, :ident,       [ :plparser_ident  ], :ordIdentRep   ],
      [ :M, :ident,       [ :plparser_qident ], :quoteIdentRep ],

      [ :N, :ieee_lit,    [ :plparser_number ], :ieeeLitRep ],
      [ :N, :integer_lit, [ :plparser_number ], :integerLitRep ],
      [ :N, :number_lit,  [ :plparser_number ], :numberLitRep],
      [ :N, :string_lit,  [ :plparser_string ] ],

      # HACK:
      #   The Oracle join operator (+) is a deprecated feature (more or less).
      #   It can only be attached to columns and only in some special places.
      #   But these places are not really context free and so we just make it
      #   a low probability event so that parser can deal with them.

      [ :N, :column_ref,  [ :column_ident ] ],
      [ :O, :column_ref,
        [ :column_ident, :column_ref_plus ], :tightUnaryRep ],

      [ :N, :column_ref_plus, [ :lparen, :plus, :rparen ], :tightParenRep ],

      [ :N, :column_ident, [ :ident ], :columnRefRep ],

      [ :N, :query_name,  [ :ident ] ],
      [ :N, :schema_ref,  [ :ident ] ],
      [ :N, :table_ref,   [ :ident ] ],
    ] +
    idRules

  end # plparserLexicalItems

end
