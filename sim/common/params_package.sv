package params_package;
    parameter CLK_PERIOD = 20;

    `ifdef N
        parameter N = `N;
    `else
        parameter N = 512;
    `endif

    `ifdef WIDTH
        parameter WIDTH = `WIDTH;
    `else
        parameter WIDTH = 16;
    `endif

    `ifdef INTEGER_WIDTH
        parameter INTEGER_WIDTH = `INTEGER_WIDTH;
    `else
        parameter INTEGER_WIDTH = 2;
    `endif

    `ifdef ROUND
        parameter ROUND = `ROUND;
    `else
        parameter ROUND = 1;
    `endif

    `ifdef RADIX_OUT_SCALE
        parameter RADIX_OUT_SCALE = `RADIX_OUT_SCALE;
    `else
        parameter RADIX_OUT_SCALE = 1;
    `endif

    `ifdef SATURATION
        parameter SATURATION = `SATURATION;
    `else
        parameter SATURATION = 1;
    `endif

    parameter FRAC_WIDTH = WIDTH - INTEGER_WIDTH;
    parameter INIT_FILE = "./twiddle_factors.bin";
    parameter SAMPLE_WIDTH = 2*WIDTH;

    parameter FIXEDPOINT_MIN = {1'b1, {(WIDTH-1){1'b0}}};
    parameter FIXEDPOINT_MAX = {1'b0, {(WIDTH-1){1'b1}}};

    // TODO: Rename INIT_FILE parameter
        
endpackage