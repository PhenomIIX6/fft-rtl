package complex_t_package;
    import params_package::*;
    import fixedpoint_functions::*;

    typedef struct {
        real re;
        real im;
    } complex_t;

    function automatic complex_t vector_to_complex_t(logic [SAMPLE_WIDTH-1:0] vector);
        complex_t complex;
        complex.re = fixedpoint_to_float(vector[SAMPLE_WIDTH-1 -: WIDTH]);
        complex.im = fixedpoint_to_float(vector[WIDTH-1:0]);
        return complex;
    endfunction
endpackage