/*
 * Transaction
 */

%{

/*
 * iterating over jobs of a transaction ('yield' in Ruby)
 */

static int
transaction_jobs_iterate_callback( const Job *j )
{
#if defined(SWIGRUBY)
  /* FIXME: how to pass 'break' back to the caller ? */
  rb_yield(SWIG_NewPointerObj((void*) j, SWIGTYPE_p__Job, 0));
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
  Transaction( Pool *pool )
  { return transaction_new( pool ); }

  ~Transaction()
  { transaction_free( $self ); }

  /*
   * Install request
   *
   * Ensure installation of a solvable by either
   * * specifying it directly
   * * specify it by name
   * * specify a required relation
   *
   * Except when specified directly, the solver is free to choose any
   * solvable matching the request (by name, by relation)
   *
   * call-seq:
   *  transaction.install(solvable) -> void
   *  transaction.install("kernel") -> void
   *  transaction.install(relation) -> void
   *
   */
  void install( XSolvable *xs )
  { transaction_install_xsolvable( $self, xs ); }

  /*
   * Remove request
   *
   * Ensure removal of a solvable by either
   * * specifying it directly
   * * specify it by name
   * * specify a required relation
   *
   * Except when specified directly, the solver is free to choose any
   * solvable matching the request (by name, by relation)
   *
   * call-seq:
   *  transaction.remove(solvable) -> void
   *  transaction.remove("kernel") -> void
   *  transaction.remove(relation) -> void
   *
   */
  void remove( XSolvable *xs )
  { transaction_remove_xsolvable( $self, xs ); }

  /*
   * Install solvable by name
   */
  void install( const char *name )
  { transaction_install_name( $self, name ); }

  /*
   * Remove solvable by name
   *
   */
  void remove( const char *name )
  { transaction_remove_name( $self, name ); }

  /*
   * Install solvable by relation
   *
   */
  void install( const Relation *rel )
  { transaction_install_relation( $self, rel ); }

  /*
   * Remove solvable by relation
   *
   */
  void remove( const Relation *rel )
  { return transaction_remove_relation( $self, rel ); }

#if defined(SWIGRUBY)
  %rename("empty?") empty();
  %typemap(out) int empty
    "$result = $1 ? Qtrue : Qfalse;";
#endif
  /*
   * Check if the transaction has any jobs attached.
   *
   * call-seq:
   *   transaction.empty? -> bool
   *
   */
  int empty()
  { return ( $self->queue.count == 0 ); }

  /*
   * Return number of jobs of this transaction
   *
   */
  int size()
  { return transaction_size( $self ); }

#if defined(SWIGRUBY)
  %rename("clear!") clear();
#endif
  /*
   * Remove all jobs of this transaction
   *
   * call-seq:
   *   transaction.clear! -> void
   *
   */
  void clear()
  { queue_empty( &($self->queue) ); }

#if defined(SWIGRUBY)
  %alias get "[]";
#endif
  /*
   * Get job by index
   *
   * The index is just a convenience access method and
   * does NOT imply any preference/ordering of the Jobs.
   *
   * A Transaction is always considered a set of Jobs.
   *
   * call-seq:
   *  transaction.get(42) -> Job
   *
   */
  Job *get( unsigned int i )
  { return transaction_job_get( $self, i ); }

  /*
   * Iterate over each Job of the Transaction.
   *
   * call-seq:
   *  transaction.each { |job| ... }
   *
   */
  void each()
  { transaction_jobs_iterate( $self, transaction_jobs_iterate_callback ); }
}

