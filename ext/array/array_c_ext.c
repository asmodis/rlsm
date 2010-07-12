#include <ruby.h>

#ifndef RARRAY_PTR
#define RARRAY_PTR(ary) RARRAY(ary)->ptr
#endif

#ifndef RARRAY_LEN
#define RARRAY_LEN(ary) RARRAY(ary)->len
#endif

static int 
c_subset_next(int* sub, int n, int k) {
  int i = k - 1;

  while(i >= 0 && sub[i] == n-k+i) { i--; }

  if (i < 0)
    return -1;

  int j;
  int sub_i = sub[i];
  for (j=i; j < k; ++j) {
    sub[j] = sub_i + 1 + j - i;
  }

  return 0;
}

static int
c_next_perm(int* perm, int n) {
  int i = n-2;
  while (i >= -1 && perm[i+1] < perm[i]) { i--; }
  if ( i < 0 ) { return -1; }

  int j = n-1;
  while ( perm[j] < perm[i] ) { j--; }

  int temp = perm[i];
  perm[i] = perm[j];
  perm[j] = temp;

  int* tmp = (int*) ALLOCA_N(int, n);

  int k;
  for (k=0; k < n; ++k) { tmp[k] = perm[k]; }

  for (k = i+1; k < n; ++k) {
    perm[k] = tmp[n+i-k];
  }

  return 0;
}

static VALUE 
ary2ruby(int* subset, int k, VALUE ary) {
  VALUE result = rb_ary_new2(k);
  int i;
  
  for (i=0; i < k; ++i) {
    rb_ary_store(result, i, RARRAY_PTR(ary)[subset[i]]);
  }

  return result; 
}

static VALUE 
powerset(VALUE self) {
  int k;
  int n = RARRAY_LEN(self);
  if (!rb_block_given_p()) {
    VALUE result = rb_ary_new();
    for (k=0; k <= n; ++k) {
      int i,res;
      int* subset = ALLOCA_N(int, k);
      for (i=0; i < k; ++i)  { subset[i] = i; }
      
      while(1) {
	rb_ary_push(result, ary2ruby(subset,k,self));
	res = c_subset_next(subset, n, k);
	if (res == -1)
	  break;
      }
    }
    return result;
  }
  else {
    for (k=0; k <= n; ++k) {
      int i,res;
      int* subset = ALLOCA_N(int, k);
      for (i=0; i < k; ++i)  { subset[i] = i; }
      
      while(1) {
	rb_yield(ary2ruby(subset,k,self));
	res = c_subset_next(subset, n, k);
	if (res == -1)
	  break;
      }
    }
    
    return Qnil;
  }
}

static VALUE
permutations(VALUE self) {
  int res;
  int n = RARRAY_LEN(self);
  int* perm = (int*) ALLOCA_N(int, n);
  int t;
  for (t=0; t < n; ++t)  { perm[t] = t; }

  if (rb_block_given_p()) {
    while(1) {
      rb_yield(ary2ruby(perm, n, self));
      res = c_next_perm(perm, n);
      if (res == -1)
	break;
    }
  }
  else {
    VALUE result = rb_ary_new();
    while(1) {
      rb_ary_push(result,ary2ruby(perm, n, self));
      res = c_next_perm(perm, n);
      if (res == -1)
	break;
    }

    return result;
  }

  return Qnil;
}

#ifdef __cplusplus
extern "C" {
#endif
  void Init_array_cext() {
    VALUE ary = rb_const_get(rb_cObject, rb_intern("Array")); 
    rb_define_method(ary, "powerset", (VALUE(*)(ANYARGS))powerset, 0);
    rb_define_method(ary, "permutations", (VALUE(*)(ANYARGS))permutations, 0);
  }
#ifdef __cplusplus
}
#endif
