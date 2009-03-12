/*
 * Document-class: Rule
 *
 * A rule is the internal representation of the _working_ _queue_ of the
 * solver. Each transaction item and each dependency is converted to a
 * rule the solver operates on.
 *
 * Rules are useful to traceback a decision or a problem.
 *
 */

%nodefault rule;
%rename(Rule) rule;
typedef struct rule {} Rule;

 
%extend Rule {
  /* no constructor, Rule is embedded in Solver */

  int p()
  { return $self->p; }
  
  int d()
  { return $self->d; }

  int w1()
  { return $self->w1; }

  int w2()
  { return $self->w2; }
  
}
