#include <ruby.h>


static VALUE 
non_associative_triple(VALUE self) {
  VALUE table = rb_iv_get(self, "@table");
  VALUE max = NUM2INT(rb_iv_get(self, "@order"));  
  VALUE base = rb_iv_get(self, "@elements");
  
  int i,j,k;
  for (i=0; i < max; ++i) {
    for (j=0; j < max; ++j) {
      for (k=0; k < max; ++k) {
        int ij,jk, i_jk, ij_k;
        ij = NUM2INT(RARRAY(table)->ptr[max*i + j]);
        jk = NUM2INT(RARRAY(table)->ptr[max*j + k]);
        i_jk = NUM2INT(RARRAY(table)->ptr[max*i + jk]);
        ij_k = NUM2INT(RARRAY(table)->ptr[max*ij + k]);
        if (ij_k != i_jk) {
          return (rb_ary_new3(3,RARRAY(base)->ptr[i],RARRAY(base)->ptr[j],RARRAY(base)->ptr[k]));
        }
      }
    }
  }
  
  return (Qnil);
}

static VALUE 
is_commutative(VALUE self) {
  VALUE table = rb_iv_get(self, "@table");
  VALUE max = NUM2INT(rb_iv_get(self, "@order"));

  int i,j;
  for (i=0; i < max; ++i) {
    for (j=0; j < max; ++j) {
      if (NUM2INT(RARRAY(table)->ptr[max*i + j]) != NUM2INT(RARRAY(table)->ptr[max*j + i]))
	return (Qfalse);
    }
  }

  return (Qtrue);
}

#ifdef __cplusplus
extern "C" {
#endif
  void Init_binop_cext() {
    VALUE rlsm = rb_define_module("RLSM");
    VALUE binop = rb_define_class_under(rlsm, "BinaryOperation", rb_cObject);

    rb_define_private_method(binop, "is_commutative", (VALUE(*)(ANYARGS))is_commutative, 0);
    rb_define_private_method(binop, "non_associative_triple", (VALUE(*)(ANYARGS))non_associative_triple, 0);
  }
#ifdef __cplusplus
}
#endif
