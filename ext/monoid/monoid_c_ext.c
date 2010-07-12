#include <ruby.h>

#ifndef RARRAY_PTR
#define RARRAY_PTR(ary) RARRAY(ary)->ptr
#endif

#ifndef RARRAY_LEN
#define RARRAY_LEN(ary) RARRAY(ary)->len
#endif

typedef int bool;

static int 
mi_index(VALUE ary, int index) {
  int i;
  for (i=0; i < RARRAY_LEN(ary); ++i) {
    if (NUM2INT(RARRAY_PTR(ary)[i]) == index) { return i; }
  }

  return -1;
}

static int* 
mi_new_ary(int length, int val) {
  int* result = (int*) calloc(length, sizeof(int));
  int i;
  for (i=0; i < length; ++i) { result[i] = val; }

  return result;
}

static VALUE mi_ary2rb(const int* ary, int length) {
  VALUE result = rb_ary_new2(length);
  int i;
  for (i=0; i < length; ++i) { rb_ary_store(result, i, INT2NUM(ary[i])); }

  return result;
}

static int* 
mi_helper_init_table(VALUE diagonal, int order) {
  int* result = (int*) calloc(order*order, sizeof(int));

  int i;
  for (i = 0; i < order*order; ++i) {
    if (i < order)
      result[i] = i;
    else if (i % order == 0)
      result[i] = i / order;
    else if (i % order == i / order)
      result[i] = NUM2INT(RARRAY_PTR(diagonal)[i / order]);
    else
      result[i] = 0;
  }

  return result;
}

static bool 
mi_is_perm_stable(VALUE diagonal, VALUE perm) {
  int i;
  for (i=0; i < RARRAY_LEN(diagonal); ++i) {
    int a = NUM2INT(RARRAY_PTR(diagonal)[i]);
    int b = NUM2INT(RARRAY_PTR(perm)[NUM2INT(RARRAY_PTR(diagonal)[mi_index(perm, i)])]);

    if ( a != b)
      return 0;
  }

  return 1;
}

static bool 
mi_is_invertable(VALUE diag, int index) {
  int i, pot = NUM2INT(RARRAY_PTR(diag)[index]);

  for (i=0; i < RARRAY_LEN(diag); ++i) {
    if (pot == 0) { return 1; }
    pot = NUM2INT(RARRAY_PTR(diag)[pot]);
  }

  return 0;
}

static VALUE 
mi_helper_select_perms(VALUE diagonal, VALUE perms, int order) {
  VALUE result = rb_ary_new();
  VALUE perm;
  int i;
  for (i=0; i < RARRAY_LEN(perms); ++i) {
    perm = RARRAY_PTR(perms)[i];
    if (mi_is_perm_stable(diagonal, perm))
      rb_ary_push(result, perm);
  }

  return result;
}

static int* 
mi_helper_rc_restrictions(VALUE diagonal, int order) {
  int* result = (int*) calloc(order, sizeof(int));
  result[0] = 1;

  int i;
  for (i=1; i < order; ++i) {
    result[i] = 1;
    if (NUM2INT(RARRAY_PTR(diagonal)[i]) == i)
      result[i] *= 2; /* idempotent */
    if (mi_is_invertable(diagonal, i))
      result[i] *= 3; /* invertible */
  }

  return result;
}

static bool 
mi_is_diagonal_valid(int* diagonal, int ord, VALUE perms) {
  int i,j;
  VALUE perm;
  for (i=0; i < RARRAY_LEN(perms); ++i) {
    perm = RARRAY_PTR(perms)[i];

    for (j=0; j < ord; ++j) {
      int ii, pdii;
      ii = mi_index(perm, j);
      if (diagonal[ii] == -1) { break; }

      pdii = NUM2INT(RARRAY_PTR(perm)[diagonal[ii]]);
      if (diagonal[j] < pdii) { break; }
      if (diagonal[j] > pdii) { return 0; }
    }
  }

  return 1;
}


static bool 
mi_is_associative(const int* table, int order) {
  int x1,x2,x3;
  for (x1=1;  x1 < order; ++x1) {
    for (x2=1;  x2 < order; ++x2) {
      for (x3=1;  x3 < order; ++x3) {
        int x1x2, x2x3, x1_x2x3, x1x2_x3;

        x1x2 = table[order*x1 + x2];
        if (x1x2 == -1) { break; }

        x2x3 = table[order*x2 + x3];
        if (x2x3 == -1) { break; }

        x1x2_x3 = table[order*x1x2 + x3];
        if (x1x2_x3 == -1) { break; }

        x1_x2x3 = table[order*x1 + x2x3];
        if (x1_x2x3 == -1) { break; }

        if (x1_x2x3 != x1x2_x3)
          return 0;
      }
    }
  }

  return 1;
}

static bool 
mi_is_iso_antiiso(const int* table, int order, VALUE perms) {
  int p,i;
  int max_index = order*order;
  VALUE perm;

  for (p = 0; p < RARRAY_LEN(perms); ++p) {
    int smaller_iso = 0, smaller_aiso = 0;
    perm = RARRAY_PTR(perms)[p];
    for (i = order+1; i < max_index; ++i) {
      int ix1, ix2, ti, tii, taii, ptii, ptaii;
      ix1 = mi_index(perm, i / order);
      ix2 = mi_index(perm, i % order);

      ti   = table[i];
      tii  = table[order*ix1 + ix2];
      taii = table[order*ix2 + ix1];

      if (ti == -1 || tii == -1 || taii == -1 )
        break;

      ptii  = NUM2INT(RARRAY_PTR(perm)[tii]);
      ptaii = NUM2INT(RARRAY_PTR(perm)[taii]);
      
      if (ti < ptii)
        smaller_iso = 1;

      if (ti < ptaii)
        smaller_aiso = 1;

      if (smaller_iso == 1 && smaller_aiso == 1)
        break;

      if ((smaller_iso == 0 && ti > ptii) || (smaller_aiso == 0 && ti > ptaii))
        return 0;
    }
  }

  return 1;
}

static bool 
mi_is_rc_rest_satisfied(const int* table, int order, const int* rc_rest) {
  int i,j,k;
  for (i=1; i < order; ++i) {
    if (rc_rest[i] != 1) {
      if (rc_rest[i] % 2 == 0) {
        for (j=1; j < order; ++j) {
          if (table[order*i + j] == 0 || table[order*j + i] == 0)
            return 0;
        }
      }

      if (rc_rest[i] % 3 == 0) {
        for (j=0; j < order; ++j) {
          for (k=j+1; k < order; ++k) {
            if (table[order*i + j] != -1 && table[order*i + j] == table[order*i + k] )
              return 0;
            if (table[order*j + i] != -1 &&  table[order*j + i] == table[order*k + i])
              return 0;

          }
        }
      }
    }
  }

  return 1;
}

static bool 
mi_table_valid(const int* table, int order, const int* rc_rest, VALUE perms) {
  if (!mi_is_rc_rest_satisfied(table, order, rc_rest))
    return 0;
  
  if (!mi_is_associative(table, order))
    return 0;

  if (!mi_is_iso_antiiso(table, order, perms))
    return 0;

  return 1;
}


static VALUE
each_diagonal(VALUE self, VALUE rorder, VALUE perms) {
  rb_need_block();

  int order = NUM2INT(rorder);
  int* diagonal = mi_new_ary(order, 0);
  rb_yield(mi_ary2rb(diagonal, order));

  int index = order - 1;
  while(1) {
    diagonal[index]++;
    if (diagonal[index] >= order) {
      if (index == 1) { return Qnil; }  /* finished */
      diagonal[index] = -1;
      index--;
    }
    else if (mi_is_diagonal_valid(diagonal, order, perms)) {
      if (index == order -1)
        rb_yield(mi_ary2rb(diagonal, order));
      else
        index++;
    }
  }

  return Qnil;
}

static VALUE 
e_w_diagonal(VALUE self, VALUE diagonal, VALUE perms) {
  int order = RARRAY_LEN(diagonal), t_order = order*order;
  int* table = mi_helper_init_table(diagonal, order);
  VALUE rperms = mi_helper_select_perms(diagonal, perms, order);
  int* rc_rest = mi_helper_rc_restrictions(diagonal, order);

  if (mi_table_valid(table, order, rc_rest, rperms)) { rb_yield(mi_ary2rb(table, t_order)); }

  int index = t_order - 2;
  while (1) {
    table[index]++;
    if (table[index] >= order) {
      if (index <= order + 2) { return Qnil; }  /* finished */
      table[index] = -1;
      index--;
      /* skip diagonal and first column */
      if ((index % order == index / order) || (index % order == 0))
        index--;
    }
    else if (mi_table_valid(table, order, rc_rest, rperms)) {
      if (index == t_order - 2)
        rb_yield(mi_ary2rb(table, t_order));
      else {
        index++;
	/* skip diagonal and first column */
        if ((index % order == index / order) || (index % order == 0)) 
          index++;
      }
    }
  }

  return Qnil;
}

static VALUE 
e_pos(VALUE self, VALUE table, VALUE rorder) {
  int i, order = NUM2INT(rorder);
  for(i=0; i < order; ++i) {
    if (NUM2INT(RARRAY_PTR(table)[i]) != i || NUM2INT(RARRAY_PTR(table)[order*i]) != i) {
      rb_raise(rb_const_get(rb_cObject, rb_intern("RLSMError")), "Neutral element isn't in first row.");
    }
  }

  return Qnil;
}

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
        ij = NUM2INT(RARRAY_PTR(table)[max*i + j]);
        jk = NUM2INT(RARRAY_PTR(table)[max*j + k]);
        i_jk = NUM2INT(RARRAY_PTR(table)[max*i + jk]);
        ij_k = NUM2INT(RARRAY_PTR(table)[max*ij + k]);
        if (ij_k != i_jk) {
          return (rb_ary_new3(3,RARRAY_PTR(base)[i],RARRAY_PTR(base)[j],RARRAY_PTR(base)[k]));
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
      if (NUM2INT(RARRAY_PTR(table)[max*i + j]) != NUM2INT(RARRAY_PTR(table)[max*j + i]))
	return (Qfalse);
    }
  }

  return (Qtrue);
}


#ifdef __cplusplus
extern "C" {
#endif
  void Init_monoid_cext() {
    VALUE rlsm = rb_define_module("RLSM");
    VALUE monoid = rb_define_class_under(rlsm, "Monoid", rb_cObject);
    rb_define_singleton_method(monoid, "each_diagonal", (VALUE(*)(ANYARGS))each_diagonal, 2);
    rb_define_singleton_method(monoid, "each_with_diagonal", (VALUE(*)(ANYARGS))e_w_diagonal, 2);
    rb_define_method(monoid, "enforce_identity_position", (VALUE(*)(ANYARGS))e_pos, 2);
    rb_define_method(monoid, "is_commutative", (VALUE(*)(ANYARGS))is_commutative, 0);
    rb_define_method(monoid, "non_associative_triple", (VALUE(*)(ANYARGS))non_associative_triple, 0);
  }
#ifdef __cplusplus
}
#endif
