module radix2_core #(
    parameter WIDTH = 16,
    parameter INTEGER_WIDTH = 2,
    parameter ROUND = 1,
    parameter RADIX_OUT_SCALE = 1,
    parameter SATURATION = 1,

    localparam FRAC_WIDTH = WIDTH - INTEGER_WIDTH,
    localparam SAMPLE_WIDTH = 2*WIDTH
) (
    input  logic [SAMPLE_WIDTH-1:0] old_left,
    input  logic [SAMPLE_WIDTH-1:0] old_right,
    input  logic [SAMPLE_WIDTH-1:0] tw_factor_0,
    input  logic [SAMPLE_WIDTH-1:0] tw_factor_1,

    output logic [SAMPLE_WIDTH-1:0] new_left,
    output logic [SAMPLE_WIDTH-1:0] new_right
);

    // new_left = old_left + tw_factor_0 * old_right
    // new_right = old_left + tw_factor_1 * old_right   

    logic signed [2*WIDTH-1:0] new_left_product_re, new_left_product_im; // new_left_product = tw_factor_0 * old_right
    logic signed [2*WIDTH-1:0] new_right_product_re, new_right_product_im; // new_right_product = tw_factor_1 * old_right

    complex_multiplier #(
        .WIDTH(WIDTH)
    ) complex_multiplier_inst_0 (
        .z0(tw_factor_0),
        .z1(old_right),
        .re(new_left_product_re),
        .im(new_left_product_im)
    );

    complex_multiplier #(
        .WIDTH(WIDTH)
    ) complex_multiplier_inst_1 (
        .z0(tw_factor_1),
        .z1(old_right),
        .re(new_right_product_re),
        .im(new_right_product_im)
    );

    parameter EXTENDED_WIDTH = 2*WIDTH+1;
    parameter EXTENDED_INTEGER_WIDTH = 2*INTEGER_WIDTH+1;
    parameter EXTENDED_FRAC_WIDTH = EXTENDED_WIDTH - EXTENDED_INTEGER_WIDTH;

    logic signed [EXTENDED_WIDTH-1:0] new_left_full_re, new_left_full_im;
    logic signed [EXTENDED_WIDTH-1:0] new_right_full_re, new_right_full_im;

    // Get full new_left and new_right
    logic signed [EXTENDED_WIDTH-1:0] old_left_extended_re, old_left_extended_im;

    assign old_left_extended_re = $signed(old_left[SAMPLE_WIDTH-1 -: WIDTH]) << (EXTENDED_FRAC_WIDTH - FRAC_WIDTH);
    assign old_left_extended_im = $signed(old_left[WIDTH-1 : 0]) << (EXTENDED_FRAC_WIDTH - FRAC_WIDTH); 

    assign new_left_full_re = new_left_product_re + old_left_extended_re;
    assign new_left_full_im = new_left_product_im + old_left_extended_im;

    assign new_right_full_re = new_right_product_re + old_left_extended_re;
    assign new_right_full_im = new_right_product_im + old_left_extended_im;

    // Round or truncate
    round_trunc_scale #(
        .INPUT_WIDTH(EXTENDED_WIDTH),
        .INPUT_INTEGER_WIDTH(EXTENDED_INTEGER_WIDTH),
        .OUTPUT_WIDTH(WIDTH),
        .OUTPUT_INTEGER_WIDTH(INTEGER_WIDTH),
        .ROUND(ROUND),
        .RADIX_OUT_SCALE(RADIX_OUT_SCALE),
        .SATURATION(SATURATION)
    ) round_trunc_inst_0 (
        .a(new_left_full_re),
        .res(new_left[SAMPLE_WIDTH-1 -: WIDTH])
    );

    round_trunc_scale #(
        .INPUT_WIDTH(EXTENDED_WIDTH),
        .INPUT_INTEGER_WIDTH(EXTENDED_INTEGER_WIDTH),
        .OUTPUT_WIDTH(WIDTH),
        .OUTPUT_INTEGER_WIDTH(INTEGER_WIDTH),
        .ROUND(ROUND),
        .RADIX_OUT_SCALE(RADIX_OUT_SCALE),
        .SATURATION(SATURATION)
    ) round_trunc_inst_1 (
        .a(new_left_full_im),
        .res(new_left[WIDTH-1 : 0])
    );

    round_trunc_scale #(
        .INPUT_WIDTH(EXTENDED_WIDTH),
        .INPUT_INTEGER_WIDTH(EXTENDED_INTEGER_WIDTH),
        .OUTPUT_WIDTH(WIDTH),
        .OUTPUT_INTEGER_WIDTH(INTEGER_WIDTH),
        .ROUND(ROUND),
        .RADIX_OUT_SCALE(RADIX_OUT_SCALE),
        .SATURATION(SATURATION)
    ) round_trunc_inst_2 (
        .a(new_right_full_re),
        .res(new_right[SAMPLE_WIDTH-1 -: WIDTH])
    );

    round_trunc_scale #(
        .INPUT_WIDTH(EXTENDED_WIDTH),
        .INPUT_INTEGER_WIDTH(EXTENDED_INTEGER_WIDTH),
        .OUTPUT_WIDTH(WIDTH),
        .OUTPUT_INTEGER_WIDTH(INTEGER_WIDTH),
        .ROUND(ROUND),
        .RADIX_OUT_SCALE(RADIX_OUT_SCALE),
        .SATURATION(SATURATION)
    ) round_trunc_inst_3 (
        .a(new_right_full_im),
        .res(new_right[WIDTH-1 : 0])
    );
endmodule