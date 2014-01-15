# Copyright (c) 2010, 2011, Oracle and/or its affiliates. All rights reserved. 

###############################################################################
# Class: SQLGrammar
# Provide a SGL <Grammar> definition.
#
# Class <SQLGrammar> has only one purpose: to create and return a <Grammar>
# object which represents SQL.

class SQLGrammar

  #############################################################################
  # Private class methods

  private

  def addNT(text)
    GramSym.new(text)
  end

  def addT(name, alternate=nil) # alternate ignored
    GramSym.new(name)
  end

  def ruleN(lhs, rhs, repProc = nil, genProc = nil)
    @gram.addRule(GramRule.new(lhs, rhs), @normalWeight, repProc, genProc)
  end

  def ruleW(lhs, rhs, repProc = nil, genProc = nil)
    @gram.addRule(GramRule.new(lhs, rhs), @lowWeight, repProc, genProc)
  end

  def addStub(name)
    nonce = addT("<#{name.name}>")
    #nonce = addT('?')
    ruleN(name, [ nonce ])
  end

  def addStubID(name)
    ruleN(name, [ addT('ID') ] )
  end

  def literalRepresent(theTree, theGram)
    theLine = ''
    theTree.children.each { |c| theLine << c.represent(theGram) }
    return theLine.delete(' ')
  end

  def tightRepresent(theTree, theGram)
    theLine = ''
    theTree.children.each { |c| theLine << c.represent(theGram) }
    theLine
  end

  def qStringRep(theTree, theGram)
    # HACK: this needs special cases for bracketing chars.
    theTrees = theTree.children
    theLine  = theTrees[0].represent(theGram) << "'" # leading Q'
    theChar  = theTrees[2].represent(theGram)        # the tag char c
    theLine << theChar << theTrees[3].represent(theGram) # the inside
    theLine << theChar << "'"                        # the final c'
  end

  def tableRep(theTree, theGram)
    theGram.chooseTable
  end

  def tableAliasDefGen(theTree, theGram)
    raise RuntimeError, "Defining a table alias"
  end

  def tableAliasRep(theTree, theGram)
    theGram.chooseTableAlias
  end

  def columnRep(theTree, theGram)
    theGram.chooseColumn
  end

  def columnAliasDefGen(theTree, theGram)
    raise RuntimeError, "Defining a column alias"
  end

  def columnAliasRep(theTree, theGram)
    theGram.chooseColumnAlias
  end

  def schemaRep(theTree, theGram)
    theGram.chooseSchema
  end

  def queryNameDefGen(theTree, theGram)
    raise RuntimeError, "Defining a query name"
  end

  def queryNameRep(theTree, theGram)
    theGram.chooseQueryName
  end

  def unimplementedRep(theTree, theGram)
    raise SyntaxError, theTree.sym.name
  end


  #----------------------------------------------------------------------------
  # Public class methods

  public

  def initialize
    @normalWeight = 1000
    @lowWeight    = (Math.sqrt(@normalWeight) + 1).to_i
    @gram         = Grammar.new
  end

  def build

    #-------------------------------------------------------------------------
    # Nonterminals

    aggregate_function          = addNT('aggregate_function')
    alias_hack                  = addNT('alias_hack')
    analytic_call               = addNT('analytic_call')
    analytic_clause             = addNT('analytic_clause')
    analytic_function           = addNT('analytic_function')
    any_list                    = addNT('any_list')
    attribute                   = addNT('attribute')
    attribute_chain             = addNT('attribute_chain')
    avg_func                    = addNT('avg_func')
    between_condition           = addNT('between_condition')
    c_alias                     = addNT('c_alias')
    c_alias_list                = addNT('c_alias_list')
    ca_part1                    = addNT('ca_part1')
    case_expression             = addNT('case_expression')
    cell_assignment             = addNT('cell_assignment')
    cell_reference              = addNT('cell_reference')
    cell_reference_options      = addNT('cell_reference_options')
    char_expr                   = addNT('char_expr')
    col_or_paren_col_list       = addNT('col_or_paren_col_list')
    collect_func                = addNT('collect_func')
    collection_expression       = addNT('collection_expression')
    column                      = addNT('column')
    column_alias_definition     = addNT('column_alias_definition')
    column_expression           = addNT('column_expression')
    column_list                 = addNT('column_list')
    compare_stack               = addNT('compare_stack')
    comparison_condition        = addNT('comparison_condition')
    compound_expression         = addNT('compound_expression')
    condition                   = addNT('condition')
    condition_and_list          = addNT('condition_and_list')
    condition_or_expr_list      = addNT('condition_or_expr_list')
    const_or_paren_const_list   = addNT('const_or_paren_const_list')
    constant_list               = addNT('constant_list')
    constraint                  = addNT('constraintNT')
    corr_func                   = addNT('corr_func')
    correlation_integer         = addNT('correlation_integer')
    cro_part1                   = addNT('cro_part1')
    cro_part2                   = addNT('cro_part2')
    cursor_expression           = addNT('cursor_expression')
    cycle_clause                = addNT('cycle_clause')
    cycle_mark_c_alias          = addNT('cycle_mark_c_alias')
    cycle_value                 = addNT('cycle_value')
    datetime_expression         = addNT('datetime_expression')
    dimension_column            = addNT('dimension_column')
    dimension_column_list       = addNT('dimension_column_list')
    dte_part                    = addNT('dte_part')
    else_clause                 = addNT('else_clause')
    equal_like                  = addNT('equal_like')
    equals_path_condition       = addNT('equals_path_condition')
    exists_condition            = addNT('exists_condition')
    expr                        = addNT('expr')
    expr_list                   = addNT('expr_list')
    expr_or_paren_expr_list     = addNT('expr_or_paren_expr_list')
    expression_list             = addNT('expression_list')
    expression_list_list        = addNT('expression_list_list')
    flashback_query_clause      = addNT('flashback_query_clause')
    floating_point_condition    = addNT('floating_point_condition')
    for_update_clause           = addNT('for_update_clause')
    fractional_second_precision = addNT('fractional_second_precision')
    fu_part1                    = addNT('fu_part1')
    fu_part1A                   = addNT('fu_part1A')
    fu_part2                    = addNT('fu_part2')
    function_arglist            = addNT('function_arglist')
    function_expression         = addNT('function_expression')
    gb_part                     = addNT('gb_part')
    group_by_clause             = addNT('group_by_clause')
    group_comparison_condition  = addNT('group_comparison_condition')
    group_stack                 = addNT('group_stack')
    grouping_expression_list    = addNT('grouping_expression_list')
    grouping_sets_clause        = addNT('grouping_sets_clause')
    gs_part                     = addNT('gs_part')
    hierarchical_query_clause   = addNT('hierarchical_query_clause')
    hint                        = addNT('hint')
    hint_comment                = addNT('hint_comment')
    hint_list                   = addNT('hint_list')
    hint_string                 = addNT('hint_string')
    hint_string_chunk           = addNT('hint_string_chunk')
    hqc_part1                   = addNT('hqc_part1')
    hqc_part2                   = addNT('hqc_part2')
    icj_part1                   = addNT('icj_part1')
    icj_part2                   = addNT('icj_part2')
    ie_part1                    = addNT('ie_part1')
    ie_part2                    = addNT('ie_part2')
    in_condition                = addNT('in_condition')
    inc_part1                   = addNT('inc_part1')
    inc_part2                   = addNT('inc_part2')
    inner_cross_join_clause     = addNT('inner_cross_join_clause')
    integer                     = addNT('integer')
    interval_expression         = addNT('interval_expression')
    iot_part1                   = addNT('iot_part1')
    iot_part2                   = addNT('iot_part2')
    iot_part2A                  = addNT('iot_part2A')
    is_a_set_condition          = addNT('is_a_set_condition')
    is_empty_condition          = addNT('is_empty_condition')
    is_of_type_condition        = addNT('is_of_type_condition')
    join_clause                 = addNT('join_clause')
    leading_field_precision     = addNT('leading_field_precision')
    levels                      = addNT('levels')
    like_condition              = addNT('like_condition')
    like_stack                  = addNT('like_stack')
    literal                     = addNT('literal')
    literal_list                = addNT('literal_list')
    literal_list_list           = addNT('literal_list_list')
    logical_condition           = addNT('logical_condition')
    main_model                  = addNT('main_model')
    main_model_name             = addNT('main_model_name')
    materialized_view           = addNT('materialized_view')
    me_part1                    = addNT('me_part1')
    me_part2                    = addNT('me_part2')
    measure_column              = addNT('measure_column')
    member_condition            = addNT('member_condition')
    method                      = addNT('method')
    model_alias                 = addNT('model_alias')
    model_alias_list            = addNT('model_alias_list')
    model_clause                = addNT('model_clause')
    model_column                = addNT('model_column')
    model_column_clauses        = addNT('model_column_clauses')
    model_condition             = addNT('model_condition')
    model_expression            = addNT('model_expression')
    model_iterate_clause        = addNT('model_iterate_clause')
    model_iterate_condition     = addNT('model_iterate_condition')
    model_rules_clause          = addNT('model_rules_clause')
    mrc_part1                   = addNT('mrc_part1')
    mrc_part1A                  = addNT('mrc_part1A')
    mrc_part1B                  = addNT('mrc_part1B')
    mrc_part1C                  = addNT('mrc_part1C')
    mrc_part2                   = addNT('mrc_part2')
    mrc_part2A                  = addNT('mrc_part2A')
    mrc_part2Ai                 = addNT('mrc_part2Ai')
    multi_column_for_loop       = addNT('multi_column_for_loop')
    multiset_condition          = addNT('multiset_condition')
    nested_table                = addNT('nested_table')
    no_cycle_value              = addNT('no_cycle_value')
    not_equal                   = addNT('not_equal')
    null_condition              = addNT('null_condition')
    number                      = addNT('number')
    oa_part1                    = addNT('oa_part1')
    oa_part2                    = addNT('oa_part2')
    ob_part1                    = addNT('ob_part1')
    ob_part2                    = addNT('ob_part2')
    ob_part2A                   = addNT('ob_part2A')
    ob_part2B                   = addNT('ob_part2B')
    ob_part2C                   = addNT('ob_part2C')
    object_access_expression    = addNT('object_access_expression')
    object_table_alias          = addNT('object_table_alias')
    ojc_part1                   = addNT('ojc_part1')
    ojc_part2                   = addNT('ojc_part2')
    ojc_part3                   = addNT('ojc_part3')
    ojc_part4                   = addNT('ojc_part4')
    order_by_clause             = addNT('order_by_clause')
    ordering_column             = addNT('ordering_column')
    outer_join_clause           = addNT('outer_join_clause')
    outer_join_type             = addNT('outer_join_type')
    path_string                 = addNT('path_string')
    pattern                     = addNT('pattern')
    pattern_matching_condition  = addNT('pattern_matching_condition')
    pc_part1                    = addNT('pc_part1')
    pc_part2                    = addNT('pc_part2')
    pi_part1                    = addNT('pi_part1')
    pi_part2                    = addNT('pi_part2')
    pivot_clause                = addNT('pivot_clause')
    pivot_for_clause            = addNT('pivot_for_clause')
    pivot_in_clause             = addNT('pivot_in_clause')
    position                    = addNT('position')
    qb_part1                    = addNT('query_block_part1')
    qb_part2                    = addNT('query_block_part2')
    qb_part2A                   = addNT('query_block_part2A')
    qb_part2B                   = addNT('query_block_part2B')
    qb_part2C                   = addNT('query_block_part2C')
    qb_part2D                   = addNT('query_block_part2D')
    qb_part3                    = addNT('query_block_part3')
    query_block                 = addNT('query_block')
    query_name                  = addNT('query_name')
    query_name_definition       = addNT('query_name_definition')
    query_partition_clause      = addNT('query_partition_clause')
    query_table_expression      = addNT('query_table_expression')
    reference_column_clause     = addNT('reference_column_clauses')
    reference_model             = addNT('reference_model')
    reference_model_list        = addNT('reference_model_list')
    reference_model_name        = addNT('reference_model_name')
    regexp_like_condition       = addNT('regexp_like_condition')
    return_rows_clause          = addNT('return_rows_clause')
    rollup_cube_clause          = addNT('rollup_cube_clause')
    sc_part                     = addNT('sc_part')
    sc_part_list                = addNT('sc_part_list')
    scalar_subquery_expression  = addNT('scalar_subquery_expression')
    scf_part1                   = addNT('scf_part1')
    scf_part2                   = addNT('scf_part2')
    scfl_list                   = addNT('scfl_list')
    schema                      = addNT('schema')
    search_clause               = addNT('search_clause')
    searched_case_expression    = addNT('searched_case_expression')
    select_list                 = addNT('select_list')
    select_statement            = addNT('select_statement')
    sequence                    = addNT('sequence')
    simple_case_expression      = addNT('simple_case_expression')
    simple_comparison_condition = addNT('simple_comparison_condition')
    simple_expression           = addNT('simple_expression')
    single_column_for_loop      = addNT('single_column_for_loop')
    sl_part                     = addNT('sl_part')
    sl_part1                    = addNT('sl_part1')
    spread_name                 = addNT('spread_name')
    sq_factor                   = addNT('sq_factor')
    sqf_part1                   = addNT('sqf_part1')
    sqf_part1A                  = addNT('sqf_part1A')
    sqf_part2                   = addNT('sqf_part2')
    sqf_part3                   = addNT('sqf_part3')
    sql_statement               = addNT('sql_statement')
    submultiset_condition       = addNT('submultiset_condition')
    subquery                    = addNT('subquery')
    subquery_factoring_clause   = addNT('subquery_factoring_clause')
    subquery_restriction_clause = addNT('subquery_restriction_clause')
    table                       = addNT('tableNT')
    table_alias                 = addNT('table_alias')
    table_alias_definition      = addNT('table_alias_definition')
    table_collection_expression = addNT('table_collection_expression')
    table_reference             = addNT('table_reference')
    time_constant               = addNT('time_constant')
    time_zone_name              = addNT('time_zone_name')
    tr_part1                    = addNT('tr_part1')
    type                        = addNT('typeNT')
    type_constructor_expression = addNT('type_constructor_expression')
    type_name                   = addNT('type_name')
    uc_part1                    = addNT('uc_part1')
    uc_part2                    = addNT('uc_part2')
    uic_part                    = addNT('uic_part')
    uic_partA                   = addNT('uic_partA')
    uic_partA1                  = addNT('uic_partA1')
    under_path_condition        = addNT('under_path_condition')
    unpivot_clause              = addNT('unpivot_clause')
    unpivot_in_clause           = addNT('unpivot_in_clause')
    variable_expression         = addNT('variable_expression')
    view                        = addNT('view')
    where_clause                = addNT('where_clause')
    windowing_clause            = addNT('windowing_clause')
    xml_condition               = addNT('XML_condition')
    wc_part1                    = addNT('wc_part1')
    wc_part1A                   = addNT('wc_part1A')
    wc_part2                    = addNT('wc_part2')
    value_expr                  = addNT('value_expr')
    digit                       = addNT('digit')
    integer_part                = addNT('integer_part')
    exponent_part               = addNT('exponent_part')
    a_or_A                      = addNT('a_or_A')
    b_or_B                      = addNT('b_or_B')
    c_or_C                      = addNT('c_or_C')
    d_or_D                      = addNT('d_or_D')
    e_or_E                      = addNT('e_or_E')
    f_or_F                      = addNT('f_or_F')
    g_or_G                      = addNT('g_or_G')
    h_or_H                      = addNT('h_or_H')
    i_or_I                      = addNT('i_or_I')
    j_or_J                      = addNT('j_or_J')
    k_or_K                      = addNT('k_or_K')
    l_or_L                      = addNT('l_or_L')
    m_or_M                      = addNT('m_or_M')
    n_or_N                      = addNT('n_or_N')
    o_or_O                      = addNT('o_or_O')
    p_or_P                      = addNT('p_or_P')
    q_or_Q                      = addNT('q_or_Q')
    r_or_R                      = addNT('r_or_R')
    s_or_S                      = addNT('s_or_S')
    t_or_T                      = addNT('t_or_T')
    u_or_U                      = addNT('u_or_U')
    v_or_V                      = addNT('v_or_V')
    w_or_W                      = addNT('w_or_W')
    x_or_X                      = addNT('x_or_X')
    y_or_Y                      = addNT('y_or_Y')
    z_or_Z                      = addNT('z_or_Z')

    letter                      = addNT('letter')
    graphic_char                = addNT('graphic_char')
    graphic_char_no_tick        = addNT('graphic_char_no_tick')
    ordinary_graphic            = addNT('ordinary_graphic')
    whitespace                  = addNT('whitespace')

    rwA                         = addNT('rwA')

    string                      = addNT('string')
    ordinary_string             = addNT('ordinary_string')
    q_string                    = addNT('q_string')
    inner_string                = addNT('inner_string')

    cache_hint                  = addNT('cache_hint')
    at_queryspec                = addNT('at_queryspec')
    tablespec                   = addNT('tablespec')
    queryblock                  = addNT('queryblock')
    identifier                  = addNT('identifier')
    ordinary_id                 = addNT('ordinary_id')
    quoted_id                   = addNT('quoted_id')
    identifier_char             = addNT('identifier_char')
    tablespec                   = addNT('tablespec')


    #-------------------------------------------------------------------------
    # Terminals

    blank      = addT(' ')

    digit0     = addT('0')
    digit1     = addT('1')
    digit2     = addT('2')
    digit3     = addT('3')
    digit4     = addT('4')
    digit5     = addT('5')
    digit6     = addT('6')
    digit7     = addT('7')
    digit8     = addT('8')
    digit9     = addT('9')

    letter_a    = addT('a')
    letter_b    = addT('b')
    letter_c    = addT('c')
    letter_d    = addT('d')
    letter_e    = addT('e')
    letter_f    = addT('f')
    letter_g    = addT('g')
    letter_h    = addT('h')
    letter_i    = addT('i')
    letter_j    = addT('j')
    letter_k    = addT('k')
    letter_l    = addT('l')
    letter_m    = addT('m')
    letter_n    = addT('n')
    letter_o    = addT('o')
    letter_p    = addT('p')
    letter_q    = addT('q')
    letter_r    = addT('r')
    letter_s    = addT('s')
    letter_t    = addT('t')
    letter_u    = addT('u')
    letter_v    = addT('v')
    letter_w    = addT('w')
    letter_x    = addT('x')
    letter_y    = addT('y')
    letter_z    = addT('z')

    letter_A    = addT('A')
    letter_B    = addT('B')
    letter_C    = addT('C')
    letter_D    = addT('D')
    letter_E    = addT('E')
    letter_F    = addT('F')
    letter_G    = addT('G')
    letter_H    = addT('H')
    letter_I    = addT('I')
    letter_J    = addT('J')
    letter_K    = addT('K')
    letter_L    = addT('L')
    letter_M    = addT('M')
    letter_N    = addT('N')
    letter_O    = addT('O')
    letter_P    = addT('P')
    letter_Q    = addT('Q')
    letter_R    = addT('R')
    letter_S    = addT('S')
    letter_T    = addT('T')
    letter_U    = addT('U')
    letter_V    = addT('V')
    letter_W    = addT('W')
    letter_X    = addT('X')
    letter_Y    = addT('Y')
    letter_Z    = addT('Z')

    langle     = addT('<', 'langle')
    rangle     = addT('>', 'rangle')
    bangequal  = addT('!=', 'bang_equal')
    hatequal   = addT('^=', 'hat_equal')
    box        = addT('<>', 'box')
    gtrequal   = addT('>=', 'greater_equal')
    lessequal  = addT('<=', 'less_equal')
    asterisk   = addT('*',  'asterisk')
    comma      = addT(',',  'comma')
    doublebar  = addT('||', 'bar_bar')
    equals     = addT('=',  'equal')
    ident      = addT('ID', 'generic_ID')
    lbracket   = addT('[',  'lbracket')
    lparen     = addT('(',  'lparen')
    minus      = addT('-',  'minus')
    period     = addT('.',  'period')
    plus       = addT('+',  'plus')
    rbracket   = addT(']',  'rbracket')
    rparen     = addT(')',  'rparen')
    semicolon  = addT(';',  'semicolon')
    slash      = addT('/',  'slash')
    underscore = addT('_')
    tick       = addT("'")
    dollar     = addT('$')
    pound_sign = addT('#')
    double_quote = addT('"')
    tALL       = addT('all')
    tAND       = addT('and')
    tANY       = addT('any')
    tAS        = addT('as')
    tASC       = addT('asc')
    tAT        = addT('at')
    tAUTOMATIC = addT('automatic')
    tAVG       = addT('avg')
    tBETWEEN   = addT('between')
    tBREADTH   = addT('breadth')
    tBY        = addT('by')
    tCASE      = addT('case')
    tCHECK     = addT('check')
    tCOLLECT   = addT('collect')
    tCONNECT   = addT('connect')
    tCONSTRAINT = addT('constraint')
    tCROSS     = addT('cross')
    tCUBE      = addT('cube')
    tCURRENT   = addT('current')
    tCURRVAL   = addT('currval')
    tCURSOR    = addT('cursor')
    tCYCLE     = addT('cycle')
    tDAY       = addT('day')
    tDBTIMEZONE = addT('dbtimezone')
    tDECREMENT = addT('decrement')
    tDEFAULT   = addT('default')
    tDEPTH     = addT('depth')
    tDESC      = addT('desc')
    tDIMENSION = addT('dimension')
    tDISTINCT  = addT('distinct')
    tELSE      = addT('else')
    tEMPTY     = addT('empty')
    tEND       = addT('end')
    tEQUALS_PATH = addT('equals_path')
    tESCAPE    = addT('escape')
    tEXCLUDE   = addT('exclude')
    tEXISTS    = addT('exists')
    tFIRST     = addT('first')
    tFOLLOWING = addT('following')
    tFOR       = addT('for')
    tFROM      = addT('from')
    tFULL      = addT('full')
    tGROUP     = addT('group')
    tGROUPING  = addT('grouping')
    tHAVING    = addT('having')
    tIGNORE    = addT('ignore')
    tIN        = addT('in')
    tINCLUDE   = addT('include')
    tINCREMENT = addT('increment')
    tINFINITE  = addT('infinite')
    tINNER     = addT('inner')
    tINTERSECT = addT('intersect')
    tIS        = addT('is')
    tITERATE   = addT('iterate')
    tJOIN      = addT('join')
    tKEEP      = addT('keep')
    tLAST      = addT('last')
    tLEFT      = addT('left')
    tLIKE      = addT('like')
    tLIKEC     = addT('likec')
    tLIKE2     = addT('like2')
    tLIKE4     = addT('like4')
    tLOCAL     = addT('local')
    tLOCKED    = addT('locked')
    tMAIN      = addT('main')
    tMAXVALUE  = addT('maxvalue')
    tMEASURES  = addT('measures')
    tMEMBER    = addT('member')
    tMINUS     = addT('minus')
    tMINVALUE  = addT('minvalue')
    tMODEL     = addT('model')
    tMONTH     = addT('month')
    tNAN       = addT('nan')
    tNATURAL   = addT('natural')
    tNAV       = addT('nav')
    tNEW       = addT('new')
    tNEXTVAL   = addT('nextval')
    tNOCYCLE   = addT('nocycle')
    tNOT       = addT('not')
    tNOWAIT    = addT('nowait')
    tNULL      = addT('NULL')
    tNULLS     = addT('nulls')
    tOF        = addT('of')
    tON        = addT('on')
    tONLY      = addT('only')
    tOPTION    = addT('option')
    tOR        = addT('or')
    tORDER     = addT('order')
    tOUTER     = addT('outer')
    tOVER      = addT('over')
    tPARTITION = addT('partition')
    tPRECEDING = addT('preceding')
    tPIVOT     = addT('pivot')
    tPRESENT   = addT('present')
    tPRIOR     = addT('prior')
    tRANGE     = addT('range')
    tREAD      = addT('read')
    tREFERENCE = addT('reference')
    tREGEXP_LIKE = addT('regexp_like')
    tRETURN    = addT('return')
    tRIGHT     = addT('right')
    tROLLUP    = addT('rollup')
    tROWID     = addT('rowid')
    tROWNUM    = addT('rownum')
    tROW       = addT('row')
    tROWS      = addT('rows')
    tRULES     = addT('rules')
    tSCN       = addT('scn')
    tSEARCH    = addT('search')
    tSECOND    = addT('second')
    tSELECT    = addT('select')
    tSEQUENTIAL = addT('sequential')
    tSESSIONTIMEZONE = addT('SESSIONTIMEZONE')
    tSET       = addT('set')
    tSETS      = addT('sets')
    tSIBLINGS  = addT('siblings')
    tSINGLE    = addT('single')
    tSKIP      = addT('skip')
    tSOME      = addT('some')
    tSTART     = addT('start')
    tSUBMULTISET = addT('submultiset')
    tTABLE     = addT('table')
    tTHEN      = addT('then')
    tTIME      = addT('time')
    tTIMESTAMP = addT('timestamp')
    tTO        = addT('to')
    tTYPE      = addT('type')
    tUNBOUNDED = addT('unbouded')
    tUNDER_PATH = addT('under_path')
    tUNION     = addT('union')
    tUNIQUE    = addT('unique')
    tUNPIVOT   = addT('unpivot')
    tUNTIL     = addT('until')
    tUPDATE    = addT('update')
    tUPDATED   = addT('updated')
    tUPSERT    = addT('upsert')
    tUSING     = addT('using')
    tVERSIONS  = addT('versions')
    tWAIT      = addT('wait')
    tWHEN      = addT('when')
    tWHERE     = addT('where')
    tWITH      = addT('with')
    tXML       = addT('xml')
    tYEAR      = addT('year')
    tZONE      = addT('zone')
    tALL_ROWS  = addT('all_rows')
    tAPPEND    = addT('append')
    tAPPEND_VALUES = addT('append_values')
    tCACHE     = addT('cache')
    tFIRST_ROWS = addT('first_rows')
    at_sign    = addT('@')

    hint_opener = addT('/*+')
    hint_closer = addT('*/')


    #-------------------------------------------------------------------------
    # SELECT statement

    ruleN(sql_statement, [ select_statement ])

    ruleN(select_statement, [ subquery ])
    ruleW(select_statement, [ subquery_factoring_clause, subquery ])
    ruleN(select_statement, [ subquery, for_update_clause ])
    ruleW(select_statement, [ subquery_factoring_clause, subquery,
                             for_update_clause ])

    ruleN(subquery, [ query_block ])
    ruleN(subquery, [ query_block, order_by_clause ])

    ruleW(subquery, [ lparen, subquery, rparen ])
    ruleW(subquery, [ lparen, subquery, rparen, order_by_clause ])

    ruleW(subquery, [ subquery, tUNION, subquery ])
    ruleW(subquery, [ subquery, tUNION, tALL, subquery ])
    ruleW(subquery, [ subquery, tINTERSECT, subquery ])
    ruleW(subquery, [ subquery, tMINUS, subquery ])
    ruleW(subquery, [ subquery, tUNION, subquery, order_by_clause ])
    ruleW(subquery, [ subquery, tUNION, tALL, subquery, order_by_clause ])
    ruleW(subquery, [ subquery, tINTERSECT, subquery, order_by_clause ])
    ruleW(subquery, [ subquery, tMINUS, subquery, order_by_clause ])

    ruleN(query_block, [ qb_part1, qb_part2, qb_part3 ])

    ruleN(qb_part1, [ tSELECT, select_list ])
    ruleN(qb_part1, [ tSELECT, tALL, select_list ])
    ruleN(qb_part1, [ tSELECT, tDISTINCT, select_list ])
    ruleN(qb_part1, [ tSELECT, tUNIQUE, select_list ])
    ruleN(qb_part1, [ tSELECT, hint_comment, select_list ])
    ruleN(qb_part1, [ tSELECT, hint_comment, tALL, select_list ])
    ruleN(qb_part1, [ tSELECT, hint_comment, tDISTINCT, select_list ])
    ruleN(qb_part1, [ tSELECT, hint_comment, tUNIQUE, select_list ])

    ruleN(qb_part2, [ qb_part2A, qb_part2B, qb_part2C, qb_part2D ])
    ruleN(qb_part2A, [ tFROM, table_reference ])
    ruleN(qb_part2A, [ tFROM, join_clause ])
    ruleN(qb_part2A, [ tFROM, lparen, join_clause, rparen ])
    ruleW(qb_part2A, [ qb_part2A, comma, qb_part2A ])

    ruleN(qb_part2B, [])
    ruleN(qb_part2B, [ where_clause ])
    ruleN(qb_part2C, [])
    ruleN(qb_part2C, [ hierarchical_query_clause ])
    ruleN(qb_part2D, [])
    ruleN(qb_part2D, [ group_by_clause ])

    ruleN(qb_part3, [])
    ruleN(qb_part3, [ tHAVING, condition ])
    ruleN(qb_part3, [ model_clause ])
    ruleN(qb_part3, [ tHAVING, condition, model_clause] )

    ruleN(select_list, [ table_alias, period, asterisk ],
                       self.method(:tightRepresent))
    ruleN(select_list, [ asterisk ])
    ruleN(select_list, [ sl_part ])

    ruleW(sl_part, [ sl_part, comma, sl_part])
    ruleN(sl_part, [ sl_part1 ])

    ruleW(sl_part1, [ expr ] )
    ruleN(sl_part1, [ expr, column_alias_definition ])
    ruleN(sl_part1, [ expr, tAS, column_alias_definition ])
    ruleN(sl_part1, [ query_name, period, asterisk ],
                    self.method(:tightRepresent))
    ruleN(sl_part1, [ table, period, asterisk ],
                    self.method(:tightRepresent))
    ruleN(sl_part1, [ view, period, asterisk ],
                    self.method(:tightRepresent))
    ruleN(sl_part1, [ materialized_view, period, asterisk ],
                    self.method(:tightRepresent))
    ruleN(sl_part1, [ schema, period, table, period, asterisk ],
                    self.method(:tightRepresent))
    ruleN(sl_part1, [ schema, period, view, period, asterisk ],
                    self.method(:tightRepresent))
    ruleN(sl_part1, [ schema, period, materialized_view, period, asterisk ],
                    self.method(:tightRepresent))

    ruleN(column_alias_definition, [ ordinary_id ], nil, 
                                   self.method(:columnAliasDefGen))

    ruleW(table_reference, [ tr_part1 ])
    ruleW(table_reference, [ tr_part1, flashback_query_clause ])
    ruleN(table_reference, [ tr_part1, table_alias_definition ])
    ruleW(table_reference, 
          [ tr_part1, flashback_query_clause, table_alias_definition ])

    ruleN(table_alias_definition, [ ordinary_id ], nil, 
                                  self.method(:tableAliasDefGen))

    ruleN(tr_part1, [ tONLY, lparen, query_table_expression, rparen ])
    ruleN(tr_part1, [ query_table_expression ])
    ruleN(tr_part1, [ query_table_expression, pivot_clause ])
    ruleN(tr_part1, [ query_table_expression, unpivot_clause ])

    ruleN(subquery_factoring_clause, [ tWITH, sq_factor ])
    ruleW(subquery_factoring_clause,
          [ subquery_factoring_clause, comma, sq_factor ])

    ruleN(sq_factor, [ query_name_definition, sqf_part1, tAS,
                       lparen, subquery, rparen, sqf_part2, sqf_part3 ])

    ruleN(query_name_definition, [ ordinary_id ], nil, 
                                 self.method(:queryNameDefGen))

    ruleN(sqf_part1, [])
    ruleN(sqf_part1, [ lparen, sqf_part1A, rparen ])
    ruleN(sqf_part1A, [ column_alias_definition ])
    ruleN(sqf_part1A, [ sqf_part1A, comma, column_alias_definition ])
    ruleN(sqf_part2, [])
    ruleN(sqf_part2, [ search_clause ] )
    ruleN(sqf_part3, [])
    ruleN(sqf_part3, [ cycle_clause ] )

    ruleN(where_clause, [ tWHERE, condition ])

    ruleN(order_by_clause, [ob_part1, ob_part2] )
    ruleN(ob_part1, [ tORDER, tBY ])
    ruleN(ob_part1, [ tORDER, tSIBLINGS, tBY ])

    ruleN(ob_part2, [ ob_part2A, ob_part2B, ob_part2C ])
    ruleW(ob_part2, [ ob_part2, comma, ob_part2 ])

    ruleN(ob_part2A, [ expr ])
    ruleN(ob_part2A, [ position ])
    ruleN(ob_part2A, [ c_alias ])

    ruleN(ob_part2B, [])
    ruleN(ob_part2B, [ tASC ])
    ruleN(ob_part2B, [ tDESC ])

    ruleN(ob_part2C, [])
    ruleN(ob_part2C, [ tNULLS, tFIRST ])
    ruleN(ob_part2C, [ tNULLS, tLAST ])

    ruleN(flashback_query_clause, [ tAS, tOF, tSCN, expr])
    ruleN(flashback_query_clause, [ tAS, tOF, tTIMESTAMP, expr])
    ruleN(flashback_query_clause,
         [ tVERSIONS, tBETWEEN, tSCN, expr, tAND, expr ])
    ruleN(flashback_query_clause,
         [ tVERSIONS, tBETWEEN, tSCN, expr, tAND, tMAXVALUE ])
    ruleN(flashback_query_clause,
         [ tVERSIONS, tBETWEEN, tSCN, tMINVALUE, tAND, expr ])
    ruleN(flashback_query_clause,
         [ tVERSIONS, tBETWEEN, tSCN, tMINVALUE, tAND, tMAXVALUE ])
    ruleN(flashback_query_clause,
         [ tVERSIONS, tBETWEEN, tTIMESTAMP, expr, tAND, expr ])
    ruleN(flashback_query_clause,
         [ tVERSIONS, tBETWEEN, tTIMESTAMP, expr, tAND, tMAXVALUE ])
    ruleN(flashback_query_clause,
         [ tVERSIONS, tBETWEEN, tTIMESTAMP, tMINVALUE, tAND, expr ])
    ruleN(flashback_query_clause,
         [ tVERSIONS, tBETWEEN, tTIMESTAMP, tMINVALUE, tAND, tMAXVALUE ])

    ruleN(join_clause, [ table_reference, inner_cross_join_clause ])
    ruleN(join_clause, [ table_reference, outer_join_clause ])
    ruleW(join_clause, [ join_clause, inner_cross_join_clause ])
    ruleW(join_clause, [ join_clause, outer_join_clause ])

    ruleN(inner_cross_join_clause, [ icj_part1 ])
    ruleN(inner_cross_join_clause, [ icj_part2 ])

    ruleN(icj_part1, [ tJOIN, table_reference, tON, condition ])
    ruleN(icj_part1, [ tINNER, tJOIN, table_reference, tON, condition ])
    ruleN(icj_part1, [ tJOIN, table_reference, tUSING,
                      lparen, column_list, rparen ])
    ruleN(icj_part1, [ tINNER, tJOIN, table_reference, tUSING,
                      lparen, column_list, rparen ])

    ruleN(icj_part2, [ tCROSS, tJOIN, table_reference ])
    ruleN(icj_part2, [ tNATURAL, tJOIN, table_reference ])
    ruleN(icj_part2, [ tNATURAL, tINNER, tJOIN, table_reference ])

    ruleN(outer_join_clause, [ ojc_part1, ojc_part2, ojc_part3, ojc_part4 ])

    ruleN(ojc_part1, [])
    ruleN(ojc_part1, [ query_partition_clause ])

    ruleN(ojc_part2, [ outer_join_type, tJOIN ])
    ruleN(ojc_part2, [ tNATURAL, tJOIN ])
    ruleN(ojc_part2, [ tNATURAL, outer_join_type, tJOIN ])

    ruleN(ojc_part3, [ table_reference ] )
    ruleN(ojc_part3, [ table_reference, query_partition_clause ])

    ruleN(ojc_part4, [] )
    ruleN(ojc_part4, [ tON, condition ])
    ruleN(ojc_part4, [ tUSING, lparen, column_list, rparen ])

    ruleN(query_partition_clause, [ tPARTITION, tBY, expr_list ])
    ruleN(query_partition_clause, [ tPARTITION, tBY,
                                   lparen, expr_list, rparen ])

    ruleN(query_table_expression, [ query_name ])
    ruleN(query_table_expression, [ table_collection_expression ])
    ruleW(query_table_expression, [ lparen, subquery, rparen ])
    ruleW(query_table_expression,
          [ lparen, subquery, subquery_restriction_clause, rparen])

    ruleN(outer_join_type, [ tFULL ])
    ruleN(outer_join_type, [ tFULL, tOUTER ])
    ruleN(outer_join_type, [ tLEFT ])
    ruleN(outer_join_type, [ tLEFT, tOUTER ])
    ruleN(outer_join_type, [ tRIGHT ])
    ruleN(outer_join_type, [ tRIGHT, tOUTER ])

    ruleN(table_collection_expression,
         [ tTABLE, lparen, collection_expression, rparen])
    ruleN(table_collection_expression,
         [ tTABLE, lparen, collection_expression, rparen,
           lparen, plus, rparen ])

    ruleN(collection_expression, [ column ] )
    ruleW(collection_expression, [ subquery ] )

    ruleN(unpivot_clause, [ uc_part1, uc_part2 ])

    ruleN(uc_part1, [ tUNPIVOT ])
    ruleN(uc_part1, [ tUNPIVOT, tINCLUDE, tNULLS ])
    ruleN(uc_part1, [ tUNPIVOT, tEXCLUDE, tNULLS ])

    ruleN(uc_part2, [ lparen, col_or_paren_col_list,
                     pivot_for_clause, unpivot_in_clause, rparen ])

    ruleN(col_or_paren_col_list, [ column ])
    ruleN(col_or_paren_col_list, [ lparen, column_list, rparen ])
    ruleN(column_list, [ column ])
    ruleW(column_list, [ column_list, comma, column_list ])

    ruleN(pivot_for_clause, [ tFOR, col_or_paren_col_list ])

    ruleN(expr_or_paren_expr_list, [ expr ])
    ruleN(expr_or_paren_expr_list, [ lparen, expr_list, rparen])

    ruleN(expr_list, [ expr ])
    ruleW(expr_list, [ expr_list, comma, expr_list])

    ruleN(unpivot_in_clause, [ tIN, lparen, uic_part, rparen])
    ruleN(uic_part, [ uic_partA ])
    ruleW(uic_part, [ uic_part, comma, uic_part ])

    ruleN(uic_partA, [ col_or_paren_col_list, uic_partA1 ])

    ruleN(uic_partA1, [])
    ruleN(uic_partA1, [ tAS, const_or_paren_const_list ])

    ruleN(const_or_paren_const_list, [ literal ])
    ruleN(const_or_paren_const_list, [ lparen, constant_list, rparen])

    ruleN(constant_list, [ literal ])
    ruleW(constant_list, [ constant_list, comma, constant_list])

    ruleN(group_by_clause, [ tGROUP, tBY, gb_part ])
    ruleN(group_by_clause, [ tGROUP, tBY, gb_part, tHAVING, condition ])

    ruleN(gb_part, [ expr ])
    ruleN(gb_part, [ rollup_cube_clause ])
    ruleN(gb_part, [ grouping_sets_clause ])
    ruleW(gb_part, [ gb_part, comma, gb_part ])

    ruleN(rollup_cube_clause,
         [ tROLLUP, lparen, grouping_expression_list, rparen ])
    ruleN(rollup_cube_clause,
         [ tCUBE, lparen, grouping_expression_list, rparen ])

    ruleN(grouping_expression_list, [ expression_list ] )
    ruleW(grouping_expression_list,
          [ grouping_expression_list, comma, grouping_expression_list ])

    ruleN(expression_list, [ expr_list ])
    ruleN(expression_list, [ lparen, expr_list, rparen ])

    ruleN(grouping_sets_clause, [ tGROUPING, tSETS, lparen, gs_part, rparen ])
    ruleN(gs_part, [ rollup_cube_clause ])
    ruleN(gs_part, [ grouping_expression_list ])
    ruleW(gs_part, [ gs_part, comma, gs_part ])

    ruleN(hierarchical_query_clause, [ hqc_part1 ] )
    ruleN(hierarchical_query_clause, [ hqc_part2 ] )

    ruleN(hqc_part1, [ tCONNECT, tBY, condition_and_list ])
    ruleN(hqc_part1, [ tCONNECT, tBY, tNOCYCLE, condition_and_list ])
    ruleN(hqc_part1, [ tCONNECT, tBY, condition_and_list,
                      tSTART, tWITH, condition ])
    ruleN(hqc_part1, [ tCONNECT, tBY, tNOCYCLE, condition_and_list,
                      tSTART, tWITH, condition ])

    ruleN(hqc_part2, [ tSTART, tWITH, condition,
                      tCONNECT, tBY, condition_and_list ])
    ruleN(hqc_part2, [ tSTART, tWITH, condition,
                      tCONNECT, tBY, tNOCYCLE, condition_and_list ])

    ruleN(condition_and_list, [ condition ])
    ruleW(condition_and_list,
          [ condition_and_list, tAND, condition_and_list ])

    ruleN(pivot_clause, [ tPIVOT, lparen, pc_part1, rparen ])
    ruleN(pivot_clause, [ tPIVOT, tXML, lparen, pc_part1, rparen ])

    ruleN(pc_part1, [ pc_part2, pivot_for_clause, pivot_in_clause ])

    ruleN(pc_part2,
         [ aggregate_function, lparen, expr, rparen ])
    ruleN(pc_part2,
         [ aggregate_function, lparen, expr, rparen, alias_hack ])
    ruleN(pc_part2,
         [ aggregate_function, lparen, expr, rparen, tAS, alias_hack ])
    ruleW(pc_part2, [ pc_part2, comma, pc_part2 ])

    ruleN(pivot_in_clause, [ tIN, lparen, pi_part1, rparen ])
    ruleW(pi_part1, [ subquery ])
    ruleN(pi_part1, [ any_list ])
    ruleN(pi_part1, [ pi_part2 ])

    ruleN(pi_part2, [ expr_or_paren_expr_list ])
    ruleN(pi_part2, [ expr_or_paren_expr_list, alias_hack ])
    ruleN(pi_part2, [ expr_or_paren_expr_list, tAS, alias_hack ])
    ruleW(pi_part2, [ pi_part2, comma, pi_part2 ])

    ruleN(any_list, [ tANY ])
    ruleW(any_list, [ any_list, comma, any_list ])

    ruleN(for_update_clause, [ tFOR, tUPDATE ])
    ruleN(for_update_clause, [ tFOR, tUPDATE, fu_part1 ])
    ruleN(for_update_clause, [ tFOR, tUPDATE, fu_part2 ])
    ruleN(for_update_clause, [ tFOR, tUPDATE, fu_part1, fu_part2 ])

    ruleN(fu_part1A, [ column ])
    ruleN(fu_part1A, [ table, period, column ],
                     self.method(:tightRepresent))
    ruleN(fu_part1A, [ view, period, column ],
                     self.method(:tightRepresent))
    ruleN(fu_part1A, [ schema, period, column ],
                     self.method(:tightRepresent))
    ruleN(fu_part1A, [ schema, period, table, period, column ],
                     self.method(:tightRepresent))
    ruleN(fu_part1A, [ schema, period, view, period, column ],
                     self.method(:tightRepresent))

    ruleN(fu_part1, [ tOF, fu_part1A ])
    ruleW(fu_part1, [ fu_part1, comma, fu_part1A ])

    ruleN(fu_part2, [ tNOWAIT ])
    ruleN(fu_part2, [ tWAIT, integer ])
    ruleN(fu_part2, [ tSKIP, tLOCKED ])

    ruleN(position, [ integer ])

    ruleW(model_clause,
         [ tMODEL,
           cell_reference_options, return_rows_clause, reference_model_list,
           main_model ])
    ruleW(model_clause,
         [ tMODEL, return_rows_clause, reference_model_list, main_model ])
    ruleN(model_clause,
         [ tMODEL, cell_reference_options, return_rows_clause, main_model ])
    ruleW(model_clause,
          [ tMODEL, cell_reference_options, reference_model_list, main_model ])
    ruleW(model_clause, [ tMODEL, reference_model_list, main_model ])
    ruleN(model_clause, [ tMODEL, main_model ])
    ruleN(model_clause, [ tMODEL, cell_reference_options, main_model ])
    ruleN(model_clause, [ tMODEL, return_rows_clause, main_model ])

    ruleN(reference_model_list, [ reference_model ])
    ruleW(reference_model_list, [ reference_model_list, reference_model ])

    ruleN(cell_reference_options, [cro_part1, cro_part2 ])

    ruleN(cro_part1, [])
    ruleN(cro_part1, [ tIGNORE, tNAV ])
    ruleN(cro_part1, [ tKEEP, tNAV ])

    ruleN(cro_part2, [])
    ruleN(cro_part2, [ tUNIQUE, tDIMENSION ])
    ruleN(cro_part2, [ tUNIQUE, tSINGLE, tREFERENCE ])

    ruleN(return_rows_clause, [ tRETURN, tUPDATED, tROWS ])
    ruleN(return_rows_clause, [ tRETURN, tALL, tROWS ])

    ruleN(reference_model,
         [ tREFERENCE, reference_model_name, tON, lparen, subquery, rparen,
           model_column_clauses, cell_reference_options ])
    ruleN(reference_model,
         [ tREFERENCE, reference_model_name, tON, lparen, subquery, rparen,
           model_column_clauses ])

    ruleN(main_model,
         [ tMAIN, main_model_name, model_column_clauses,
           cell_reference_options, model_rules_clause ])
    ruleN(main_model,
         [ tMAIN, main_model_name, model_column_clauses, model_rules_clause ])
    ruleN(main_model,
         [ model_column_clauses, cell_reference_options, model_rules_clause ])
    ruleN(main_model, [ model_column_clauses, model_rules_clause ])

    ruleN(model_column, [ expr ])
    ruleN(model_column, [ expr, column_alias_definition ])
    ruleN(model_column, [ expr, tAS, column_alias_definition ])

    ruleN(model_alias_list, [ expr ])
    ruleN(model_alias_list, [ expr, column_alias_definition ])
    ruleW(model_alias_list, [ model_alias_list, comma, model_alias_list ])

    ruleN(model_column_clauses,
         [ tPARTITION, tBY, lparen, model_alias_list, rparen,
           tDIMENSION, tBY, lparen, model_alias_list, rparen,
           tMEASURES,  tBY, lparen, model_alias_list, rparen ])
    ruleN(model_column_clauses,
         [ tDIMENSION, tBY, lparen, model_alias_list, rparen,
           tMEASURES,  tBY, lparen, model_alias_list, rparen ])

    ruleN(model_rules_clause, [ mrc_part1, mrc_part2 ])

    ruleN(mrc_part1, [])
    ruleN(mrc_part1, [ tRULES, mrc_part1A, mrc_part1B, mrc_part1C ])

    ruleN(mrc_part1A, [])
    ruleN(mrc_part1A, [ tUPDATE ])
    ruleN(mrc_part1A, [ tUPSERT, tALL ])

    ruleN(mrc_part1B, [])
    ruleN(mrc_part1B, [ tAUTOMATIC, tORDER ])
    ruleN(mrc_part1B, [ tSEQUENTIAL, tORDER ])

    ruleN(mrc_part1C, [])
    ruleN(mrc_part1C, [ model_iterate_clause ])

    ruleN(model_iterate_clause, [])
    ruleN(model_iterate_clause,
       [ tITERATE, lparen, number, rparen, tUNTIL,
         lparen, model_iterate_condition, rparen ])
    ruleN(model_iterate_clause, [ tITERATE, lparen, number, rparen ])

    ruleN(model_iterate_condition, [ condition] )
    ruleN(model_iterate_condition, [ model_condition ] )

    ruleN(mrc_part2, [ lparen, mrc_part2A, rparen ])

    ruleN(mrc_part2A, [ mrc_part2Ai, cell_assignment, equals, expr ])
    ruleN(mrc_part2A, [ mrc_part2Ai, cell_assignment,
                       order_by_clause, equals, expr ])
    ruleW(mrc_part2A, [ mrc_part2A, comma, mrc_part2A ])

    ruleN(mrc_part2Ai, [ tUPDATE ])
    ruleN(mrc_part2Ai, [ tUPSERT ])
    ruleN(mrc_part2Ai, [ tUPSERT, tALL ])

    ruleN(cell_assignment, [ measure_column, lbracket, ca_part1, rbracket ])
    ruleN(cell_assignment,
         [ measure_column, lbracket, multi_column_for_loop, rbracket ])

    ruleN(ca_part1, [ condition ])
    ruleN(ca_part1, [ expr ])
    ruleN(ca_part1, [ single_column_for_loop ])
    ruleW(ca_part1, [ ca_part1, comma, ca_part1 ])

    ruleN(single_column_for_loop, [ tFOR, dimension_column, scf_part1 ])
    ruleN(single_column_for_loop, [ tFOR, dimension_column, scf_part2 ])

    ruleN(scf_part1, [ tIN, lparen, literal_list, rparen ])
    ruleW(scf_part1, [ tIN, lparen, subquery, rparen ])

    ruleN(literal_list, [ literal ])
    ruleW(literal_list, [ literal_list, comma, literal_list ])

    ruleN(scf_part2,
         [ tLIKE, pattern, tFROM, literal, tTO, literal, tINCREMENT, literal ])
    ruleN(scf_part2,
         [ tLIKE, pattern, tFROM, literal, tTO, literal, tDECREMENT, literal ])
    ruleN(scf_part2, [ tFROM, literal, tTO, literal, tINCREMENT, literal ])
    ruleN(scf_part2, [ tFROM, literal, tTO, literal, tDECREMENT, literal ])

    ruleW(multi_column_for_loop,
          [ tFOR, lparen, dimension_column_list, rparen, tIN,
            lparen, subquery, rparen ])
    ruleN(multi_column_for_loop,
         [ tFOR, lparen, dimension_column_list, rparen, tIN,
           lparen, literal_list_list, rparen ])

    ruleN(dimension_column_list, [ dimension_column ])
    ruleW(dimension_column_list,
       [ dimension_column_list, dimension_column, dimension_column_list ])

    ruleN(literal_list_list, [ lparen, literal_list, rparen ])
    ruleW(literal_list_list,
          [ literal_list_list, comma, literal_list_list ])

    ruleN(subquery_restriction_clause,
         [ tWITH, tREAD, tONLY, tCONSTRAINT, constraint ])
    ruleN(subquery_restriction_clause,
         [ tWITH, tCHECK, tOPTION, tCONSTRAINT, constraint ])
    ruleN(subquery_restriction_clause, [ tWITH, tREAD, tONLY ])
    ruleN(subquery_restriction_clause, [ tWITH, tCHECK, tOPTION ])

    ruleN(cycle_clause,
         [ tCYCLE, c_alias_list, tSET, cycle_mark_c_alias, tTO, cycle_value,
           tDEFAULT, no_cycle_value ])

    ruleN(c_alias_list, [ c_alias ])
    ruleW(c_alias_list, [ c_alias_list, comma, c_alias_list ])

    ruleN(cycle_mark_c_alias, [ c_alias ])
    ruleN(cycle_value, [ expr ])
    ruleN(no_cycle_value, [ expr ])

    ruleN(search_clause,
       [ tSEARCH, tDEPTH, tFIRST, tBY, sc_part_list, tSET, ordering_column ])
    ruleN(search_clause,
       [ tSEARCH, tBREADTH, tFIRST, tBY, sc_part_list, tSET, ordering_column ])

    ruleN(sc_part, [ c_alias, tASC, tNULLS, tFIRST ])
    ruleN(sc_part, [ c_alias, tDESC, tNULLS, tFIRST ])
    ruleN(sc_part, [ c_alias, tNULLS, tFIRST ])
    ruleN(sc_part, [ c_alias, tASC, tNULLS, tLAST ])
    ruleN(sc_part, [ c_alias, tDESC, tNULLS, tLAST ])
    ruleN(sc_part, [ c_alias, tNULLS, tLAST ])
    ruleN(sc_part, [ c_alias, tASC ])
    ruleN(sc_part, [ c_alias, tDESC ])
    ruleN(sc_part, [ c_alias ])

    ruleN(sc_part_list, [ sc_part ])
    ruleW(sc_part_list, [ sc_part_list, comma, sc_part_list ])

    ruleN(ordering_column, [ column ])

    #-------------------------------------------------------------------------
    # Expressions
    #
    # HACK: Expressions can include bind variables (placeholder expressions in
    #       SQL), but we are skipping them for now on the grounds that the
    #       initial experiments will not have any way to provide values for
    #       binds nor will they present SQL from either PL/SQL or OCI.

    ruleN(expr, [ simple_expression ])
    ruleW(expr, [ compound_expression ])
    ruleW(expr, [ case_expression ])
    ruleW(expr, [ cursor_expression ])
    ruleW(expr, [ datetime_expression ])
    ruleW(expr, [ function_expression ])
    ruleW(expr, [ interval_expression ])
    ruleW(expr, [ object_access_expression ])
    ruleW(expr, [ scalar_subquery_expression ])
    ruleW(expr, [ model_expression ])
    ruleW(expr, [ type_constructor_expression ])

    ruleN(scalar_subquery_expression, [ lparen, subquery, rparen ])

    ruleN(compound_expression, [ lparen, expr, rparen ])
    ruleN(compound_expression, [ plus, expr ])
    ruleN(compound_expression, [ minus, expr ])
    ruleN(compound_expression, [ tPRIOR, expr ])
    ruleN(compound_expression, [ expr, asterisk, expr ])
    ruleN(compound_expression, [ expr, slash, expr ])
    ruleN(compound_expression, [ expr, plus, expr ])
    ruleN(compound_expression, [ expr, minus, expr ])
    ruleN(compound_expression, [ expr, doublebar, expr ])

    ruleN(simple_expression, [ query_name, period, column ],
                             self.method(:tightRepresent))
    ruleN(simple_expression, [ query_name, period, tROWID ],
                             self.method(:tightRepresent))
    ruleN(simple_expression, [ schema, period, table, period, column ],
                             self.method(:tightRepresent))
    ruleN(simple_expression, [ schema, period, table, period, tROWID ],
                             self.method(:tightRepresent))
    ruleN(simple_expression, [ schema, period, view, period, column ],
                             self.method(:tightRepresent))
    ruleN(simple_expression, [ schema, period, view, period, tROWID ],
                             self.method(:tightRepresent))
    ruleN(simple_expression, 
          [ schema, period, materialized_view, period, column ],
          self.method(:tightRepresent))
    ruleN(simple_expression,
          [ schema, period, materialized_view, period, tROWID ],
          self.method(:tightRepresent))
    ruleN(simple_expression, [ table, period, column ],
                             self.method(:tightRepresent))
    ruleN(simple_expression, [ table, period, tROWID ],
                             self.method(:tightRepresent))
    ruleN(simple_expression, [ view, period, column ],
                             self.method(:tightRepresent))
    ruleN(simple_expression, [ view, period, tROWID ],
                             self.method(:tightRepresent))
    ruleN(simple_expression, [ materialized_view, period, column ],
                             self.method(:tightRepresent))
    ruleN(simple_expression, [ materialized_view, period, tROWID ],
                             self.method(:tightRepresent))

    ruleN(simple_expression, [ tROWNUM ])
    ruleN(simple_expression, [ string ])
    ruleN(simple_expression, [ number ])
    ruleN(simple_expression, [ tNULL ])

    ruleN(simple_expression, [ sequence, period, tCURRVAL ],
                             self.method(:tightRepresent))
    ruleN(simple_expression, [ sequence, period, tNEXTVAL ],
                             self.method(:tightRepresent))

    ruleN(case_expression, [ tCASE, simple_case_expression, else_clause, tEND ])
    ruleN(case_expression, [ tCASE, simple_case_expression, tEND ])
    ruleN(case_expression,
         [ tCASE, searched_case_expression, else_clause, tEND ])
    ruleN(case_expression, [ tCASE, searched_case_expression, tEND ])

    ruleN(simple_case_expression, [ expr, tWHEN, expr, tTHEN, expr ])
    ruleW(simple_case_expression,
          [ simple_case_expression, tWHEN, expr, tTHEN, expr ])

    ruleN(searched_case_expression, [ tWHEN, condition, tTHEN, expr ])
    ruleW(searched_case_expression,
          [ searched_case_expression, tWHEN, condition, tTHEN, expr ])

    ruleN(else_clause, [ tELSE, expr ])

    ruleN(column_expression, [ simple_expression ] )
    ruleN(column_expression, [ compound_expression ] )
    ruleN(column_expression, [ function_expression ] )
    ruleN(column_expression, [ expression_list ] )

    ruleN(cursor_expression, [ tCURSOR, lparen, subquery, rparen ])

    ruleN(datetime_expression, [ expr, tAT, tLOCAL ])
    ruleW(datetime_expression, [ expr, tAT, tTIME, tZONE, dte_part ])

    ruleN(dte_part, [ time_constant ])
    ruleN(dte_part, [ tDBTIMEZONE ])
    ruleN(dte_part, [ tSESSIONTIMEZONE ])
    ruleN(dte_part, [ time_zone_name ])
    ruleW(dte_part, [ expr ])

    ruleN(function_expression, [ ident ])
    ruleN(function_expression, [ ident, lparen, rparen ])
    ruleN(function_expression, [ ident, lparen, function_arglist, rparen ])

    ruleN(function_arglist, [ expr ])
    ruleN(function_arglist, [ ident, equals, expr ])
    ruleW(function_arglist, [ function_arglist, comma, function_arglist ])

    ruleN(interval_expression, [ lparen, expr, minus, expr, rparen, ie_part1 ])
    ruleN(interval_expression, [ lparen, expr, minus, expr, rparen, ie_part2 ])

    ruleN(ie_part1,
         [ tDAY, lparen, leading_field_precision, rparen,
           tTO, tSECOND, lparen, fractional_second_precision, rparen ])
    ruleN(ie_part1,
         [ tDAY, tTO, tSECOND, lparen, fractional_second_precision, rparen ])
    ruleN(ie_part1,
         [ tDAY, lparen, leading_field_precision, rparen, tTO, tSECOND ])
    ruleN(ie_part1, [ tDAY, tTO, tSECOND ])

    ruleN(ie_part2,
         [ tYEAR, lparen, leading_field_precision, rparen, tTO, tMONTH ])
    ruleN(ie_part2, [ tYEAR, tTO, tMONTH ])

    ruleN(leading_field_precision, [ integer ])
    ruleN(fractional_second_precision, [ integer ])

    ruleN(model_expression, [ me_part1 ])
    ruleN(model_expression, [ me_part2 ])
    ruleN(model_expression, [ analytic_function ])

    ruleN(me_part1,
         [ measure_column, lbracket, condition_or_expr_list, rbracket ])

    ruleN(me_part2,
         [ aggregate_function, lbracket, condition_or_expr_list, rbracket ])
    ruleN(me_part2, [ aggregate_function, lbracket, scfl_list, rbracket ])
    ruleN(me_part2,
         [ aggregate_function, lbracket, multi_column_for_loop, rbracket ])

    ruleN(condition_or_expr_list, [ expr ])
    ruleN(condition_or_expr_list, [ condition ])
    ruleW(condition_or_expr_list,
          [ condition_or_expr_list, comma, condition_or_expr_list ])

    ruleN(scfl_list, [ single_column_for_loop ])
    ruleW(scfl_list, [ scfl_list, comma, scfl_list ])

    ruleN(object_access_expression, [ oa_part1, oa_part2 ])

    ruleN(oa_part1, [ table_alias, period, column, period ],
                    self.method(:tightRepresent))
    ruleN(oa_part1, [ object_table_alias, period ],
                    self.method(:tightRepresent))
    ruleN(oa_part1, [ lparen, expr, rparen, period ],
                    self.method(:tightRepresent))

    ruleN(oa_part2, [ attribute_chain ])
    ruleN(oa_part2,
         [ attribute_chain, period, method, lparen, function_arglist, rparen ])
    ruleN(oa_part2, [ method, lparen, function_arglist, rparen ])

    ruleN(attribute_chain, [ attribute ])
    ruleW(attribute_chain, [ attribute_chain, period, attribute_chain ])

    ruleN(type_constructor_expression,
         [ tNEW, schema, period, type_name, lparen, expr_list, rparen ])
    ruleN(type_constructor_expression,
         [ schema, period, type_name, lparen, expr_list, rparen ])
    ruleN(type_constructor_expression,
         [ tNEW, type_name, lparen, expr_list, rparen ])
    ruleN(type_constructor_expression, [ type_name, lparen, expr_list, rparen ])

    #-------------------------------------------------------------------------
    # Conditions

    ruleN(condition, [ comparison_condition ])
    ruleN(condition, [ floating_point_condition ])
    ruleW(condition, [ logical_condition ])
    ruleN(condition, [ multiset_condition ])
    ruleN(condition, [ pattern_matching_condition ])
    ruleN(condition, [ null_condition ])
    ruleN(condition, [ xml_condition ])
    ruleW(condition, [ exists_condition ])
    ruleN(condition, [ in_condition ])
    ruleN(condition, [ is_of_type_condition ])
    ruleN(condition, [ between_condition ])

    ruleN(comparison_condition, [ simple_comparison_condition ])
    ruleW(comparison_condition, [ group_comparison_condition ])

    ruleN(not_equal, [ bangequal ])
    ruleN(not_equal, [ hatequal ])
    ruleN(not_equal, [ box ])

    ruleN(equal_like, [ equals ])
    ruleN(equal_like, [ not_equal ])

    ruleN(compare_stack, [ equal_like ])
    ruleN(compare_stack, [ langle ])
    ruleN(compare_stack, [ rangle ])
    ruleN(compare_stack, [ gtrequal ])
    ruleN(compare_stack, [ lessequal ])

    ruleN(simple_comparison_condition, [ expr, compare_stack, expr ])
    ruleW(simple_comparison_condition,
      [ lparen, expr_list, rparen, equal_like, lparen, subquery, rparen ])

    ruleN(group_stack, [ tANY ])
    ruleN(group_stack, [ tALL ])
    ruleN(group_stack, [ tSOME ])

    ruleN(group_comparison_condition,
         [ expr, compare_stack, group_stack, lparen, expression_list, rparen ])
    ruleW(group_comparison_condition,
         [ expr, compare_stack, group_stack, lparen, subquery, rparen ])
    ruleN(group_comparison_condition,
         [ lparen, expr_list, rparen, equal_like, group_stack,
           lparen, expression_list, rparen ])
    ruleW(group_comparison_condition,
         [ lparen, expr_list, rparen, equal_like, group_stack,
           lparen, subquery, rparen ])

    ruleN(floating_point_condition, [ expr, tIS, tNOT, tNAN ])
    ruleN(floating_point_condition, [ expr, tIS, tNOT, tINFINITE ])
    ruleN(floating_point_condition, [ expr, tIS, tNAN ])
    ruleN(floating_point_condition, [ expr, tIS, tINFINITE ])

    ruleN(logical_condition, [ tNOT, condition ])
    ruleN(logical_condition, [ condition, tAND, condition ])
    ruleN(logical_condition, [ condition, tOR, condition ])
    ruleN(logical_condition, [ lparen, condition, rparen ])

    ruleN(model_condition, [ tANY ])
    ruleN(model_condition, [ dimension_column, tIS, tANY ])
    ruleN(model_condition, [ cell_reference, tIS, tPRESENT ])

    ruleN(multiset_condition, [ is_a_set_condition ])
    ruleN(multiset_condition, [ is_empty_condition ])
    ruleN(multiset_condition, [ member_condition ])
    ruleN(multiset_condition, [ submultiset_condition ])

    ruleN(submultiset_condition,
         [ nested_table, tNOT, tSUBMULTISET, tOF, nested_table ])
    ruleN(submultiset_condition,
         [ nested_table,       tSUBMULTISET, tOF, nested_table ])
    ruleN(submultiset_condition,
         [ nested_table, tNOT, tSUBMULTISET,      nested_table ])
    ruleN(submultiset_condition,
         [ nested_table,       tSUBMULTISET,      nested_table ])

    ruleN(is_a_set_condition, [ nested_table, tIS, tNOT, rwA, tSET ])
    ruleN(is_a_set_condition, [ nested_table, tIS,       rwA, tSET ])

    ruleN(rwA, [ a_or_A ])

    ruleN(is_empty_condition, [ nested_table, tIS, tNOT, tEMPTY ])
    ruleN(is_empty_condition, [ nested_table, tIS,       tEMPTY ])

    ruleN(member_condition, [ expr, tNOT, tMEMBER, tOF, nested_table ])
    ruleN(member_condition, [ expr,       tMEMBER, tOF, nested_table ])
    ruleN(member_condition, [ expr, tNOT, tMEMBER,      nested_table ])
    ruleN(member_condition, [ expr,       tMEMBER,      nested_table ])

    ruleN(pattern_matching_condition, [ like_condition ])
    ruleN(pattern_matching_condition, [ regexp_like_condition ])

    ruleN(like_condition,
         [ char_expr, tNOT, like_stack, char_expr, tESCAPE, char_expr ])
    ruleN(like_condition,
         [ char_expr,       like_stack, char_expr, tESCAPE, char_expr ])
    ruleN(like_condition,
         [ char_expr, tNOT, like_stack,                     char_expr ])
    ruleN(like_condition,
         [ char_expr,       like_stack, char_expr                     ])

    ruleN(char_expr, [ expr ])

    ruleN(like_stack, [ tLIKE ])
    ruleN(like_stack, [ tLIKEC ])
    ruleN(like_stack, [ tLIKE2 ])
    ruleN(like_stack, [ tLIKE4 ])

    ruleN(regexp_like_condition,
         [ tREGEXP_LIKE, lparen, char_expr, comma, char_expr,
           comma, char_expr, rparen ])
    ruleN(regexp_like_condition,
         [ tREGEXP_LIKE, lparen, char_expr, comma, char_expr, rparen ])

    ruleN(null_condition, [ expr, tIS, tNOT, tNULL ])
    ruleN(null_condition, [ expr, tIS,       tNULL ])

    ruleN(xml_condition, [ equals_path_condition ])
    ruleN(xml_condition, [ under_path_condition ])

    ruleN(equals_path_condition,
         [ tEQUALS_PATH, lparen, column, comma, path_string,
           comma, correlation_integer, rparen ])
    ruleN(equals_path_condition,
         [ tEQUALS_PATH, lparen, column, comma, path_string, rparen ])

    ruleN(path_string, [ string ])
    ruleN(correlation_integer, [ expr ])

    ruleN(under_path_condition,
         [ tUNDER_PATH, lparen, column, comma, levels, comma, path_string,
           comma, correlation_integer, rparen ])
    ruleN(under_path_condition,
         [ tUNDER_PATH, lparen, column,                comma, path_string,
           comma, correlation_integer, rparen ])
    ruleN(under_path_condition,
         [ tUNDER_PATH, lparen, column, comma, levels, comma, path_string,
                                       rparen ])
    ruleN(under_path_condition,
         [ tUNDER_PATH, lparen, column, comma, path_string, rparen ])

    ruleN(levels, [ expr ])

    ruleN(between_condition, [ expr, tNOT, tBETWEEN, expr, tAND, expr ])
    ruleN(between_condition, [ expr,       tBETWEEN, expr, tAND, expr ])

    ruleN(exists_condition, [ tEXISTS, lparen, subquery, rparen ])

    ruleN(in_condition, [ inc_part1 ])
    ruleN(in_condition, [ inc_part2 ])

    ruleN(inc_part1,
         [ expr, tNOT, tIN, lparen, expression_list, rparen ])
    ruleN(inc_part1,
         [ expr,       tIN, lparen, expression_list, rparen ])
    ruleW(inc_part1,
         [ expr, tNOT, tIN, lparen, subquery,        rparen ])
    ruleW(inc_part1,
         [ expr,       tIN, lparen, subquery,        rparen ])

    ruleN(inc_part2,
         [ lparen, expr_list, rparen, tNOT, tIN,
           lparen, expression_list_list, rparen ])
    ruleN(inc_part2,
         [ lparen, expr_list, rparen,    tIN,
           lparen, expression_list_list, rparen ])
    ruleW(inc_part2,
         [ lparen, expr_list, rparen, tNOT, tIN,
           lparen, subquery, rparen ])
    ruleW(inc_part2,
         [ lparen, expr_list, rparen,    tIN, lparen, subquery, rparen ])

    ruleN(expression_list_list, [ expression_list ])
    ruleW(expression_list_list,
          [ expression_list_list, comma, expression_list_list ])

    ruleN(is_of_type_condition,
         [ expr, tIS, iot_part1, lparen, iot_part2, rparen ])

    ruleN(iot_part1, [ tNOT, tOF, tTYPE ])
    ruleN(iot_part1, [ tNOT,      tTYPE ])
    ruleN(iot_part1, [ tNOT, tOF        ])
    ruleN(iot_part1, [ tNOT             ])

    ruleN(iot_part2A, [ tONLY, schema, period, type ])
    ruleN(iot_part2A, [        schema, period, type ])
    ruleN(iot_part2A, [ tONLY,                 type ])
    ruleN(iot_part2A, [                        type ])

    ruleN(iot_part2, [ iot_part2A ])
    ruleW(iot_part2, [ iot_part2, comma, iot_part2 ])


    #-------------------------------------------------------------------------
    # Aggregate and analytic functions

    ruleN(aggregate_function, [ avg_func ])
    ruleN(aggregate_function, [ collect_func ])

    ruleN(avg_func, [ tAVG, lparen, tDISTINCT, expr, rparen ])
    ruleN(avg_func, [ tAVG, lparen, tALL,      expr, rparen ])
    ruleN(avg_func, [ tAVG, lparen,            expr, rparen ])

    ruleN(collect_func, [ tCOLLECT, lparen, tDISTINCT, expr, rparen ])
    ruleN(collect_func, [ tCOLLECT, lparen, tUNIQUE,   expr, rparen ])
    ruleN(collect_func, [ tCOLLECT, lparen,            expr, rparen ])

    ruleN(analytic_function,
         [ analytic_call, tOVER, lparen, analytic_clause, rparen ])

    ruleN(analytic_clause,
         [ query_partition_clause, order_by_clause, windowing_clause ])
    ruleN(analytic_clause,
         [ query_partition_clause, order_by_clause                   ])
    ruleN(analytic_clause,
         [ query_partition_clause                                    ])
    ruleN(analytic_clause,
         [                         order_by_clause, windowing_clause ])
    ruleN(analytic_clause,
         [                         order_by_clause                   ])
    ruleN(analytic_clause,
         [                                                           ])

    ruleN(analytic_call, [ avg_func ])
    ruleN(analytic_call, [ collect_func])

    ruleN(windowing_clause, [ tROWS,  wc_part1 ])
    ruleN(windowing_clause, [ tRANGE, wc_part1 ])
    ruleN(windowing_clause, [ tROWS,  wc_part2 ])
    ruleN(windowing_clause, [ tRANGE, wc_part2 ])

    ruleN(wc_part1, [ tBETWEEN, wc_part1A, tAND, wc_part1A ])

    ruleN(wc_part1A, [ tUNBOUNDED, tPRECEDING ])
    ruleN(wc_part1A, [ tCURRENT, tROW ])
    ruleN(wc_part1A, [ value_expr, tPRECEDING ])
    ruleN(wc_part1A, [ value_expr, tFOLLOWING ])

    ruleN(wc_part2, [ tUNBOUNDED, tPRECEDING ])
    ruleN(wc_part2, [ tCURRENT, tROW ])
    ruleN(wc_part2, [ value_expr, tPRECEDING ])

    ruleN(value_expr, [ expr ])

    ruleN(cell_reference, [ spread_name, lbracket, expr, rbracket ])
    ruleN(cell_reference,
         [ spread_name, lbracket, expr, comma, expr, rbracket ])


    #-------------------------------------------------------------------------
    # Metadata elements

    metaTable = addT('metaTable')
    ruleN(table, [ metaTable ], self.method(:tableRep))
    
    metaColumn = addT('metaColumn')
    ruleN(column, [ metaColumn ], self.method(:columnRep))

    metaSchema = addT('metaSchema')
    ruleN(schema, [ metaSchema ], self.method(:schemaRep))

    metaTableAlias = addT('metaTableAlias')
    ruleN(table_alias, [ metaTableAlias ], self.method(:tableAliasRep))

    metaColumnAlias = addT('metaTableAlias')
    ruleN(c_alias, [ metaColumnAlias ], self.method(:columnAliasRep))

    #-------------------------------------------------------------------------
    # Unimplemented terminals

    ruleN(attribute,            [], self.method(:unimplementedRep))
    ruleN(c_alias,              [], self.method(:unimplementedRep))
    ruleN(constraint,           [], self.method(:unimplementedRep))
    ruleN(dimension_column,     [], self.method(:unimplementedRep))
    ruleN(main_model_name,      [], self.method(:unimplementedRep))
    ruleN(materialized_view,    [], self.method(:unimplementedRep))
    ruleN(measure_column,       [], self.method(:unimplementedRep))
    ruleN(method,               [], self.method(:unimplementedRep))
    ruleN(nested_table,         [], self.method(:unimplementedRep))
    ruleN(object_table_alias,   [], self.method(:unimplementedRep))
    ruleN(pattern,              [], self.method(:unimplementedRep))
    ruleN(query_name,           [], self.method(:unimplementedRep))
    ruleN(reference_model_name, [], self.method(:unimplementedRep))
    ruleN(sequence,             [], self.method(:unimplementedRep))
    ruleN(spread_name,          [], self.method(:unimplementedRep))
    ruleN(time_constant,        [], self.method(:unimplementedRep))
    ruleN(time_zone_name,       [], self.method(:unimplementedRep))
    ruleN(type,                 [], self.method(:unimplementedRep))
    ruleN(type_name,            [], self.method(:unimplementedRep))
    ruleN(view,                 [], self.method(:unimplementedRep))


    #-------------------------------------------------------------------------
    # Constants and literals

    ruleN(literal, [ integer ], self.method(:literalRepresent))
    ruleN(literal, [ number ],  self.method(:literalRepresent))
    ruleN(literal, [ string ])

    ruleN(integer_part, [ digit ])
    ruleN(integer_part, [ integer_part, digit ], self.method(:tightRepresent))

    ruleN(integer, [        integer_part ])
    ruleN(integer, [ plus,  integer_part ], self.method(:tightRepresent))
    ruleN(integer, [ minus, integer_part ], self.method(:tightRepresent))

    ruleN(number, [ integer, period, integer_part, exponent_part ],
          self.method(:tightRepresent))
    ruleN(number, [          period, integer_part, exponent_part ],
          self.method(:tightRepresent))
    ruleN(number, [ integer, period, integer_part                ],
          self.method(:tightRepresent))
    ruleN(number, [          period, integer_part                ],
          self.method(:tightRepresent))

    ruleN(exponent_part, [ e_or_E, plus,  integer_part, f_or_F ],
          self.method(:tightRepresent))
    ruleN(exponent_part, [ e_or_E, plus,  integer_part, d_or_D ],
          self.method(:tightRepresent))
    ruleN(exponent_part, [ e_or_E, minus, integer_part, f_or_F ],
          self.method(:tightRepresent))
    ruleN(exponent_part, [ e_or_E, minus, integer_part, d_or_D ],
          self.method(:tightRepresent))
    ruleN(exponent_part, [ e_or_E,        integer_part, f_or_F ],
          self.method(:tightRepresent))
    ruleN(exponent_part, [ e_or_E,        integer_part, d_or_D ],
          self.method(:tightRepresent))
    ruleN(exponent_part, [ e_or_E, plus,  integer_part         ],
          self.method(:tightRepresent))
    ruleN(exponent_part, [ e_or_E, minus, integer_part         ],
          self.method(:tightRepresent))
    ruleN(exponent_part, [ e_or_E,        integer_part         ],
          self.method(:tightRepresent))
    ruleN(exponent_part, [                              f_or_F ],
          self.method(:tightRepresent))
    ruleN(exponent_part, [                              d_or_D ],
          self.method(:tightRepresent))
    
    ruleN(string, [ n_or_N, ordinary_string ], self.method(:tightRepresent))
    ruleN(string, [         ordinary_string ], self.method(:tightRepresent))
    ruleN(string, [ n_or_N, q_string ], self.method(:tightRepresent))
    ruleN(string, [         q_string ], self.method(:tightRepresent))

    ruleN(ordinary_string, [tick, inner_string, tick ],
          self.method(:tightRepresent))
    
    ruleN(inner_string, [ ], self.method(:tightRepresent))
    ruleN(inner_string, [ inner_string, graphic_char_no_tick ],
          self.method(:tightRepresent))
    ruleN(inner_string, [ inner_string, tick, tick ], 
          self.method(:tightRepresent))
    
    ruleN(q_string, [ q_or_Q, tick, graphic_char_no_tick,
                      inner_string, graphic_char_no_tick, tick ],
          self.method(:qStringRep))


    #-------------------------------------------------------------------------
    # Hints
    # 
    # HACK: We are ignoring --+ hint syntax for the moment.
    # HACK: We only have some of the hints listed.

    ruleN(hint_comment, [ hint_opener, hint_list, hint_closer ])

    ruleN(hint_list, [ hint ])
    ruleN(hint_list, [ hint_list, hint_string, hint ])

    ruleN(hint_string, [ hint_string_chunk])
    ruleW(hint_string, [ hint_string, whitespace, hint_string_chunk ])

    ruleN(hint_string_chunk, [ graphic_char ],
                             self.method(:tightRepresent))
    ruleN(hint_string_chunk, [ hint_string, graphic_char], 
                             self.method(:tightRepresent))

    ruleN(hint, [ tALL_ROWS ])
    ruleN(hint, [ tAPPEND ])
    ruleN(hint, [ tAPPEND_VALUES ])
    ruleN(hint, [ cache_hint ])
    ruleN(hint, [ tFIRST_ROWS, lparen, integer, rparen ],
                self.method(:tightRepresent))

    ruleN(cache_hint, [ tCACHE, lparen, at_queryspec, tablespec, rparen ])
    ruleN(cache_hint, [ tCACHE, lparen,               tablespec, rparen ])

    ruleN(at_queryspec, [ at_sign, queryblock ], self.method(:tightRepresent))
    
    ruleN(queryblock, [ identifier ])

    ruleN(tablespec, [ table ])
    ruleW(tablespec, [ view, period, tablespec ], 
                     self.method(:tightRepresent))

    #-------------------------------------------------------------------------
    # Identifiers

    ruleN(identifier, [ ordinary_id ])
    ruleN(identifier, [ quoted_id   ])

    ruleN(ordinary_id, [ letter ])
    ruleN(ordinary_id, [ ordinary_id, identifier_char ],
                       self.method(:tightRepresent))
    
    ruleN(quoted_id, [ double_quote, hint_string, double_quote ],
                     self.method(:tightRepresent))


    #-------------------------------------------------------------------------
    # Alphabets and characters

    ruleN(graphic_char, [ graphic_char_no_tick ])
    ruleN(graphic_char, [ tick ])

    ruleN(identifier_char, [ letter ])
    ruleN(identifier_char, [ digit ])
    ruleN(identifier_char, [ underscore ])
    ruleN(identifier_char, [ dollar ])
    ruleN(identifier_char, [ pound_sign ])

    ruleN(graphic_char_no_tick, [ digit ])
    ruleN(graphic_char_no_tick, [ letter ])
    ruleN(graphic_char_no_tick, [ ordinary_graphic ])
    ruleN(graphic_char_no_tick, [ whitespace ])

    ruleN(digit, [ digit0 ])
    ruleN(digit, [ digit1 ])
    ruleN(digit, [ digit2 ])
    ruleN(digit, [ digit3 ])
    ruleN(digit, [ digit4 ])
    ruleN(digit, [ digit5 ])
    ruleN(digit, [ digit6 ])
    ruleN(digit, [ digit7 ])
    ruleN(digit, [ digit8 ])
    ruleN(digit, [ digit9 ])

    ruleN(a_or_A, [letter_a])
    ruleN(a_or_A, [letter_A])
    ruleN(b_or_B, [letter_b])
    ruleN(b_or_B, [letter_B])
    ruleN(c_or_C, [letter_c])
    ruleN(c_or_C, [letter_C])
    ruleN(d_or_D, [letter_d])
    ruleN(d_or_D, [letter_D])
    ruleN(e_or_E, [letter_e])
    ruleN(e_or_E, [letter_E])
    ruleN(f_or_F, [letter_f])
    ruleN(f_or_F, [letter_F])
    ruleN(g_or_G, [letter_g])
    ruleN(g_or_G, [letter_G])
    ruleN(h_or_H, [letter_h])
    ruleN(h_or_H, [letter_H])
    ruleN(i_or_I, [letter_i])
    ruleN(i_or_I, [letter_I])
    ruleN(j_or_J, [letter_j])
    ruleN(j_or_J, [letter_J])
    ruleN(k_or_K, [letter_k])
    ruleN(k_or_K, [letter_K])
    ruleN(l_or_L, [letter_l])
    ruleN(l_or_L, [letter_L])
    ruleN(m_or_M, [letter_m])
    ruleN(m_or_M, [letter_M])
    ruleN(n_or_N, [letter_n])
    ruleN(n_or_N, [letter_N])
    ruleN(o_or_O, [letter_o])
    ruleN(o_or_O, [letter_O])
    ruleN(p_or_P, [letter_p])
    ruleN(p_or_P, [letter_P])
    ruleN(q_or_Q, [letter_q])
    ruleN(q_or_Q, [letter_Q])
    ruleN(r_or_R, [letter_r])
    ruleN(r_or_R, [letter_R])
    ruleN(s_or_S, [letter_s])
    ruleN(s_or_S, [letter_S])
    ruleN(t_or_T, [letter_t])
    ruleN(t_or_T, [letter_T])
    ruleN(u_or_U, [letter_u])
    ruleN(u_or_U, [letter_U])
    ruleN(v_or_V, [letter_v])
    ruleN(v_or_V, [letter_V])
    ruleN(w_or_W, [letter_w])
    ruleN(w_or_W, [letter_W])
    ruleN(x_or_X, [letter_x])
    ruleN(x_or_X, [letter_X])
    ruleN(y_or_Y, [letter_y])
    ruleN(y_or_Y, [letter_Y])
    ruleN(z_or_Z, [letter_z])
    ruleN(z_or_Z, [letter_Z])

    ruleN(letter, [ a_or_A ])
    ruleN(letter, [ b_or_B ])
    ruleN(letter, [ c_or_C ])
    ruleN(letter, [ d_or_D ])
    ruleN(letter, [ e_or_E ])
    ruleN(letter, [ f_or_F ])
    ruleN(letter, [ g_or_G ])
    ruleN(letter, [ h_or_H ])
    ruleN(letter, [ i_or_I ])
    ruleN(letter, [ j_or_J ])
    ruleN(letter, [ k_or_K ])
    ruleN(letter, [ l_or_L ])
    ruleN(letter, [ m_or_M ])
    ruleN(letter, [ n_or_N ])
    ruleN(letter, [ o_or_O ])
    ruleN(letter, [ p_or_P ])
    ruleN(letter, [ q_or_Q ])
    ruleN(letter, [ r_or_R ])
    ruleN(letter, [ s_or_S ])
    ruleN(letter, [ t_or_T ])
    ruleN(letter, [ u_or_U ])
    ruleN(letter, [ v_or_V ])
    ruleN(letter, [ w_or_W ])
    ruleN(letter, [ x_or_X ])
    ruleN(letter, [ y_or_Y ])
    ruleN(letter, [ z_or_Z ])

    ruleN(ordinary_graphic, [ langle    ])
    ruleN(ordinary_graphic, [ rangle    ])
    ruleN(ordinary_graphic, [ asterisk  ])
    ruleN(ordinary_graphic, [ comma     ])
    ruleN(ordinary_graphic, [ equals    ])
    ruleN(ordinary_graphic, [ lbracket  ])
    ruleN(ordinary_graphic, [ lparen    ])
    ruleN(ordinary_graphic, [ minus     ])
    ruleN(ordinary_graphic, [ period    ])
    ruleN(ordinary_graphic, [ plus      ])
    ruleN(ordinary_graphic, [ rbracket  ])
    ruleN(ordinary_graphic, [ rparen    ])
    ruleN(ordinary_graphic, [ semicolon ])
    ruleN(ordinary_graphic, [ slash     ])
    ruleN(ordinary_graphic, [ at_sign   ])
    ruleN(ordinary_graphic, [ underscore ])
    ruleN(ordinary_graphic, [ dollar ])
    ruleN(ordinary_graphic, [ pound_sign ])

    ruleN(whitespace, [ blank ])

    # Remember this thing returns the grammar it generated, not the one-off
    # object that knows the details of SQL.

    return @gram

  end # build

end
