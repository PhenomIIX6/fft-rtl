#include <stdio.h>
#include <complex.h>
#include <stdlib.h>
#include <inttypes.h>
#include <math.h>
#include <string.h>

// #define WIDTH 16
// #define INTEGER_WIDTH 2
// #define N 512
// #define FILENAME "twiddle_factors.bin"

const double PI = 3.14159265358979323846;

typedef struct
{
    uint64_t int_part;
    uint64_t frac_part;
} fixedpoint_t;


double complex* get_w(int n) {
    double complex* w = malloc(n * sizeof(double complex));
    for(int i = 0; i < n; i++) {
        w[i] = cexp(2 * PI * I * i / (double)n);
    }
    return w;
}

// It generates only positive values because the ROM contains only them
// Other twiddle factors can be calculated using some logic
fixedpoint_t double_to_fixed(double a, size_t width, size_t frac_width) {
    fixedpoint_t fixedpoint;
    
    if (frac_width > 64) {
        frac_width = 64;
    }

    if (a == 1.0) {
        if (width - frac_width > 1) {
            fixedpoint.int_part = 1;
            fixedpoint.frac_part = 0;
        }
        else {
            fixedpoint.int_part = 0;
            fixedpoint.frac_part = 0xFFFFFFFFFFFFFFFFULL;
        }
    }
    else {
        fixedpoint.int_part = 0;
        fixedpoint.frac_part = (uint64_t) rint(a * (1 << frac_width));
    }

    return fixedpoint;
}

void write_fixedpoint_to_file(FILE* fptr, fixedpoint_t fixedpoint, size_t width, size_t integer_width) {
    for(int i = 0; i < integer_width; i++) {
        int idx = integer_width - i - 1;
        uint8_t bit = (fixedpoint.int_part >> idx) & 1;
        fprintf(fptr, "%d", bit); 
    }
    for (int i = 0; i < width-integer_width; i++) {
        int idx = width-integer_width - i - 1;
        uint8_t bit = (fixedpoint.frac_part >> idx) & 1;
        fprintf(fptr, "%d", bit);
    }
}

int main(void) {
    FILE* fptr;
    fptr = fopen(FILENAME, "w");

    double complex* w = get_w(N);
    for(int i = 0; i < N/4+1; i++) {
        double re = creal(w[i]);
        double im = cimag(w[i]);
        // printf("%f %f\n", re, im);
        fixedpoint_t re_fixed = double_to_fixed(re, WIDTH, WIDTH-INTEGER_WIDTH);
        fixedpoint_t im_fixed = double_to_fixed(im, WIDTH, WIDTH-INTEGER_WIDTH);
        write_fixedpoint_to_file(fptr, re_fixed, WIDTH, INTEGER_WIDTH);
        write_fixedpoint_to_file(fptr, im_fixed, WIDTH, INTEGER_WIDTH);
        fprintf(fptr, "\n"); 
    }

    free(w);
    
    return 0;
}