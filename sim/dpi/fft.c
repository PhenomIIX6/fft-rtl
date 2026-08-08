#include <math.h>
#include <stdlib.h>
#include <complex.h>
#include <svdpi.h>
#include "dpi.h"

double complex* get_w(int n) {
    double complex* w = malloc(n * sizeof(double complex));
    for(int i = 0; i < n; i++) {
        w[i] = cexp(2 * PI * I * i / (double)n);
    }
    return w;
}

int bit_reverse(int a, int n) {
    int ans = 0;
    for(int i = n; i > -1; i--) {
        if ((1 << i) <= a) {
            a -= (1 << i);
            ans += (1 << (n-i-1));
        }
    }
    return ans;
}

void fft_reversed(double complex* a, int n, double complex* w, double complex* out, int scale) {
    int size = (int)log2((double)n);
    for(int i = 0; i < n; i++) {
        out[i] = (double complex) a[bit_reverse(i, size)];
    }

    int r = 1;
    while (r != n) {
        for(int subarray = 0; subarray < n/(2*r); subarray++) {
            for(int offset = 0; offset < r; offset++) {
                double complex old_left = out[subarray*(r*2) + offset];
                double complex old_right = out[subarray*(r*2) + offset+r];
                out[subarray*(r*2) + offset] = old_left + w[offset*(n/(2*r))] * old_right;
                out[subarray*(r*2) + offset+r] = old_left + w[offset*(n/(2*r))+(n/2)] * old_right;
           
                // Scale
                out[subarray*(r*2) + offset] /= (double) (1 << scale); 
                out[subarray*(r*2) + offset+r] /= (double) (1 << scale);
            }
        }
        r *= 2;
    }
}

void get_complex_t_fft(complex_t in[], int n, int scale, complex_t out[]) {
    double complex* w = get_w(n);
    double complex* a = malloc(n * sizeof(double complex));
    double complex* temp = malloc(n * sizeof(double complex));

    for(int i = 0; i < n; i++) {
        a[i] = in[i].re + I * in[i].im;
    }

    fft_reversed(a, n, w, temp, scale);

    for(int i = 0; i < n; i++) {
        out[i].re = creal(temp[i]);
        out[i].im = cimag(temp[i]);
    }

    free(a); free(temp);
}