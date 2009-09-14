/*
 * Document-class: Transaction
 *
 * Transaction represents the result of a successful (+Solver+.+solve+
 * returning +true+) solver run.
 *
 * The Transaction class contains a list of Steps, each representing a
 * Solvable to install, update, or remove.
 *
 * === Constructor
 * There is no constructor defined for Transaction. Transactions are created by accessing
 * the Solver result. See 'Solver.transaction'.
 *
 */


%{

/*
 * iterating over steps of a transaction ('yield' in Ruby)
 */

static int
transaction_steps_iterate_callback( const Step *s )
{
#if defined(SWIGRUBY)
  /* FIXME: how to pass 'break' back to the caller ? */
  rb_yield(SWIG_NewPointerObj((void*) s, SWIGTYPE_p__Step, 0));
#endif
  return 0;
}

%}


%nodefault _Transaction;
%rename(Transaction) _Transaction;
typedef struct _Transaction {} Transaction;

#if defined(SWIGRUBY)
%mixin Transaction "Enumerable";
#endif

%extend Transaction {

  /*
   * Modes
   */
  %constant int TRANSACTION_MODE_ACTIVE = SOLVER_TRANSACTION_SHOW_ACTIVE;
  %constant int TRANSACTION_MODE_ALL = SOLVER_TRANSACTION_SHOW_ALL;
  %constant int TRANSACTION_MODE_OBSOLETES = SOLVER_TRANSACTION_SHOW_OBSOLETES;
  %constant int TRANSACTION_MODE_MULTIINSTALL = SOLVER_TRANSACTION_SHOW_MULTIINSTALL;
  %constant int TRANSACTION_MODE_IS_REINSTALL = SOLVER_TRANSACTION_CHANGE_IS_REINSTALL;
  %constant int TRANSACTION_MODE_MERGE_VENDORCHANGES = SOLVER_TRANSACTION_MERGE_VENDORCHANGES;
  %constant int TRANSACTION_MODE_MERGE_ARCHCHANGES = SOLVER_TRANSACTION_MERGE_ARCHCHANGES;
 
  %constant int TRANSACTION_MODE_RPM_ONLY = SOLVER_TRANSACTION_RPM_ONLY;
 
  /*
   * order() flag
   */
  %constant int TRANSACTION_KEEP_ORDERDATA = SOLVER_TRANSACTION_KEEP_ORDERDATA;

  ~Transaction()
  { transaction_free( $self ); }

#if defined(SWIGRUBY)
  %rename("empty?") empty();
  %typemap(out) int empty
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * Check if the transaction has any steps attached.
   *
   * call-seq:
   *   transaction.empty? -> bool
   *
   */
  int empty()
  { return ( $self->steps.count == 0 ); }

  /*
   * Return number of steps of this transaction
   *
   */
  int size()
  { return $self->steps.count; }

  /*
   * Return the size change of the installed system
   *
   * This is how much disk space gets allocated/freed after the
   * solver decisions are applied to the system.
   *
   */
  long sizechange()
  {
    return transaction_calc_installsizechange($self);
  }

#if defined(SWIGRUBY)
  %rename("order!") order(int flags);
#endif
  /*
   * Order the transaction according to pre-requires
   *
   * Ordering is done in-place.
   *
   * flags can be TRANSACTION_KEEP_ORDERDATA
   *
   */
  void order(int flags = 0) {
    transaction_order($self, flags);
  }
  
#if defined(SWIGRUBY)
  %alias get "[]";
#endif
  /*
   * Get step by index
   *
   * call-seq:
   *  transaction.get(42) -> Job
   *
   */
  Step *get( unsigned int i )
  { return step_get( $self, i ); }

  /*
   * Iterate over each Step of the Transaction.
   *
   * call-seq:
   *  transaction.each { |step| ... }
   *
   */
  void each()
  { transaction_steps_iterate( $self, transaction_steps_iterate_callback ); }
}

