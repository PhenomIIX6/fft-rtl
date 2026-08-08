#include <complex.h>
#include <svdpi.h>
#include "dpi.h"

void get_tw(int num, int nfft, complex_t* out) {
    double complex w = cexp(2 * PI * I * num / (double)nfft);
    out->re = creal(w);
    out->im = cimag(w);
}