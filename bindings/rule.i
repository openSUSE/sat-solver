/*
 * Rule
=begin rdoc
This documents rule
=end
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
