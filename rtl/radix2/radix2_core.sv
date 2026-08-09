module radix2_core #(
    parameter WIDTH = 16,
    parameter INTEGER_WIDTH = 2,
    parameter ROUND = 1,
    parameter RADIX_OUT_SCALE = 1,
    parameter SATURATION = 1,

    parameter CONTEXT_WIDTH = 1,

    parameter FRAC_WIDTH = WIDTH - INTEGER_WIDTH,
    parameter SAMPLE_WIDTH = 2*WIDTH
) (
    input  logic clk,
    input  logic arst_n, 

    input  logic [CONTEXT_WIDTH-1:0] context_in,
    output logic [CONTEXT_WIDTH-1:0] context_out,

    input  logic [SAMPLE_WIDTH-1:0] old_left,
    input  logic [SAMPLE_WIDTH-1:0] old_right,
    input  logic [SAMPLE_WIDTH-1:0] tw_factor_0,
    input  logic [SAMPLE_WIDTH-1:0] tw_factor_1,

    output logic [SAMPLE_WIDTH-1:0] new_left,
    output logic [SAMPLE_WIDTH-1:0] new_right
);

    // new_left = old_left + tw_factor_0 * old_right
    // new_right = old_left + tw_factor_1 * old_right   

    // new_left_product = tw_factor_0 * old_right
    // new_right_product = tw_factor_1 * old_right
    
    parameter EXTENDED_WIDTH = 2*WIDTH+1;
    parameter EXTENDED_INTEGER_WIDTH = 2*INTEGER_WIDTH+1;
    parameter EXTENDED_FRAC_WIDTH = EXTENDED_WIDTH - EXTENDED_INTEGER_WIDTH;

    typedef struct packed {
        logic [SAMPLE_WIDTH-1:0] tw_factor_0;
        logic [SAMPLE_WIDTH-1:0] tw_factor_1;
        logic [SAMPLE_WIDTH-1:0] old_left;
        logic [SAMPLE_WIDTH-1:0] old_right;
    } stage1_t;

    typedef struct packed {
        logic [SAMPLE_WIDTH-1:0] old_left;

        logic signed [2*WIDTH-1:0] new_left_product_re;
        logic signed [2*WIDTH-1:0] new_left_product_im;
        logic signed [2*WIDTH-1:0] new_right_product_re;
        logic signed [2*WIDTH-1:0] new_right_product_im;

        logic signed [EXTENDED_WIDTH-1:0] new_left_full_re;
        logic signed [EXTENDED_WIDTH-1:0] new_left_full_im;

        logic signed [EXTENDED_WIDTH-1:0] new_right_full_re;
        logic signed [EXTENDED_WIDTH-1:0] new_right_full_im;

        logic signed [EXTENDED_WIDTH-1:0] old_left_extended_re;
        logic signed [EXTENDED_WIDTH-1:0] old_left_extended_im;        
    } stage2_t;

    stage1_t stage1;
    stage2_t stage2;

    // STAGE 1 - Multiply start
    assign stage1.tw_factor_0 = tw_factor_0;
    assign stage1.tw_factor_1 = tw_factor_1;
    assign stage1.old_left = old_left;
    assign stage1.old_right = old_right;  

    complex_multiplier_pipe #(
        .WIDTH(WIDTH),
        .CONTEXT_WIDTH(CONTEXT_WIDTH + $bits(stage1.old_left))
    ) complex_multiplier_inst_0 (
        .clk(clk),
        .arst_n(arst_n),

        .context_in({context_in, stage1.old_left}),
        .context_out({context_out, stage2.old_left}),

        .z0(stage1.tw_factor_0),
        .z1(stage1.old_right),
        .re(stage2.new_left_product_re),
        .im(stage2.new_left_product_im)
    );

    complex_multiplier_pipe #(
        .WIDTH(WIDTH),
        .CONTEXT_WIDTH(0)
    ) complex_multiplier_inst_1 (
        .clk(clk),
        .arst_n(arst_n),

        .context_in(),
        .context_out(),

        .z0(stage1.tw_factor_1),
        .z1(stage1.old_right),
        .re(stage2.new_right_product_re),
        .im(stage2.new_right_product_im)
    );

    // STAGE 2 - Get new_left and new_right
    assign stage2.old_left_extended_re = $signed(stage2.old_left[SAMPLE_WIDTH-1 -: WIDTH]) << (EXTENDED_FRAC_WIDTH - FRAC_WIDTH);
    assign stage2.old_left_extended_im = $signed(stage2.old_left[WIDTH-1 : 0]) << (EXTENDED_FRAC_WIDTH - FRAC_WIDTH); 

    assign stage2.new_left_full_re = stage2.new_left_product_re + stage2.old_left_extended_re;
    assign stage2.new_left_full_im = stage2.new_left_product_im + stage2.old_left_extended_im;

    assign stage2.new_right_full_re = stage2.new_right_product_re + stage2.old_left_extended_re;
    assign stage2.new_right_full_im = stage2.new_right_product_im + stage2.old_left_extended_im;

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
        .a(stage2.new_left_full_re),
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
        .a(stage2.new_left_full_im),
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
        .a(stage2.new_right_full_re),
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
        .a(stage2.new_right_full_im),
        .res(new_right[WIDTH-1 : 0])
    );
endmodule