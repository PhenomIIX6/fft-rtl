#include <stdio.h>
#include <complex.h>
#include <stdlib.h>
#include <math.h>

// Defaults so the file can be built standalone too.
#ifndef WIDTH
#define WIDTH 16
#endif
#ifndef INTEGER_WIDTH
#define INTEGER_WIDTH 2
#endif
#ifndef N
#define N 512
#endif
#ifndef FILENAME
#define FILENAME "twiddle_factors.bin"
#endif

const double PI = 3.14159265358979323846;

double complex* get_w(int n) {
    double complex* w = malloc(n * sizeof(double complex));
    for (int i = 0; i < n; i++) {
        w[i] = cexp(2 * PI * I * i / (double)n);
    }
    return w;
}

// Write one fixed-point value as `width` bits, MSB first, with `integer_width`
// integer bits (the MSB is the sign bit) followed by `width - integer_width`
// fractional bits.
//
// Bits are produced one at a time from a `long double`, so there is no
// 64-bit integer limit and no undefined shift. The value is rounded half-up at
// the LSB, which also carries correctly into the integer part (so a value that
// rounds up to exactly 1.0 does not collapse to 0). `a` must be in
// [0, 2^(integer_width-1)); the only caller passes twiddle components in [0,1].
static void write_fixed(FILE* fptr, long double a, int width, int integer_width) {
    int frac = width - integer_width;
    long double v = a + ldexpl(0.5L, -frac);   // round half-up at the LSB

    // Integer bits, weight 2^(integer_width-1) .. 2^0.
    for (int i = integer_width - 1; i >= 0; i--) {
        long double w = ldexpl(1.0L, i);
        int bit = (v >= w);
        if (bit) {
            v -= w;
        }
        fputc(bit ? '1' : '0', fptr);
    }

    // Fractional bits, weight 2^-1 .. 2^-frac.
    for (int i = 0; i < frac; i++) {
        v *= 2.0L;
        int bit = (v >= 1.0L);
        if (bit) {
            v -= 1.0L;
        }
        fputc(bit ? '1' : '0', fptr);
    }
}

int main(void) {
    if (INTEGER_WIDTH < 2) {
        fprintf(stderr,
                "warning: INTEGER_WIDTH=%d cannot represent the twiddle W^0 = 1.0 "
                "(its largest representable value is %Lg); the value will wrap. "
                "Use INTEGER_WIDTH >= 2.\n",
                INTEGER_WIDTH, 1.0 - ldexpl(1.0, -WIDTH));
    }
    if (WIDTH - INTEGER_WIDTH < 1) {
        fprintf(stderr,
                "warning: WIDTH(%d) - INTEGER_WIDTH(%d) < 1: no fractional bits, "
                "the twiddle table is meaningless.\n",
                WIDTH, INTEGER_WIDTH);
    }

    FILE* fptr = fopen(FILENAME, "w");
    if (fptr == NULL) {
        perror(FILENAME);
        return 1;
    }

    double complex* w = get_w(N);
    for (int i = 0; i < N / 4 + 1; i++) {
        // w[i] for i in [0, N/4] has non-negative real and imaginary parts.
        write_fixed(fptr, (long double)creal(w[i]), WIDTH, INTEGER_WIDTH);
        write_fixed(fptr, (long double)cimag(w[i]), WIDTH, INTEGER_WIDTH);
        fputc('\n', fptr);
    }

    free(w);
    fclose(fptr);

    return 0;
}
