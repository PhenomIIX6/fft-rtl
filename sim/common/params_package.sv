package params_package;
    parameter CLK_PERIOD = 20;

    parameter N = 512;
    parameter WIDTH = 16;
    parameter INTEGER_WIDTH = 2;
    parameter ROUND = 1;
    parameter RADIX_OUT_SCALE = 1;
    parameter SATURATION = 1;

    parameter FRAC_WIDTH = WIDTH - INTEGER_WIDTH;
    parameter INIT_FILE = "./twiddle_factors.bin";
    parameter SAMPLE_WIDTH = 2*WIDTH;

    parameter FIXEDPOINT_MIN = {1'b1, {(WIDTH-1){1'b0}}};
    parameter FIXEDPOINT_MAX = {1'b0, {(WIDTH-1){1'b1}}};

    // TODO: Rename INIT_FILE parameter
        
endpackage