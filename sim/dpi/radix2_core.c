#include <complex.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <svdpi.h>
#include "dpi.h"

void complex_mul(complex_t* a, complex_t* b, complex_t* out) {
    double complex a_complex = a->re + I * a->im;
    double complex b_complex = b->re + I * b->im;
    double complex prod = a_complex * b_complex;
    out->re = creal(prod);
    out->im = cimag(prod);
}

void complex_mac(complex_t* a, complex_t* b, complex_t* c, complex_t* out) {
    // printf("DPI DEBUG: a.re=%f, a.im=%f, b.re=%f, b.im=%f c.re=%f, c.im=%f\n", a->re, a->im, b->re, b->im, c->re, c->im);
    double complex a_complex = a->re + I * a->im;
    double complex b_complex = b->re + I * b->im;
    double complex c_complex = c->re + I * c->im;
    double complex res = (a_complex + b_complex * c_complex);
    out->re = creal(res);
    out->im = cimag(res);
    
}