module complex_multiplier_pipe #(
    parameter WIDTH = 16,
    parameter INTEGER_WIDTH = 2,
    
    parameter CONTEXT_WIDTH = 1, 

    parameter SAMPLE_WIDTH = 2*WIDTH
) (
    input logic clk,
    input logic arst_n,

    input  logic [CONTEXT_WIDTH-1:0] context_in,
    output logic [CONTEXT_WIDTH-1:0] context_out,

    input logic [SAMPLE_WIDTH-1:0] z0,
    input logic [SAMPLE_WIDTH-1:0] z1,
    output logic signed [2*WIDTH-1:0] re,
    output logic signed [2*WIDTH-1:0] im
);
    // z0 = (A + iB), z1 = (C + iD)
    // z0 * z1 = (AC - BD) + i(AD + BC)
    
    // k1 = AC + BC
    // k2 = AD - AC
    // k3 = BC + BD
    // k1 - k3 = AC - BD = real(z0 * z1)
    // k1 + k2 = AD + BC = image(z0 * z1)

    logic signed [WIDTH:0] a, b, c, d;
    logic signed [WIDTH:0] a_r, b_r, c_r, d_r;
    logic signed [WIDTH:0] ab, dc, cd;
    logic signed [2*WIDTH:0] k1, k2, k3;

    assign a = $signed(z0[SAMPLE_WIDTH-1 -: WIDTH]);
    assign b = $signed(z0[WIDTH-1 : 0]);
    assign c = $signed(z1[SAMPLE_WIDTH-1 -: WIDTH]);
    assign d = $signed(z1[WIDTH-1 : 0]);

    logic [CONTEXT_WIDTH-1:0] context_temp;

    pipeline_register #(
        .WIDTH(CONTEXT_WIDTH)
    ) context_register_0 (
        .clk(clk),
        .arst_n(arst_n),
        .d(context_in),
        .q(context_temp)
    );

    pipeline_register #(
        .WIDTH(CONTEXT_WIDTH)
    ) context_register_1 (
        .clk(clk),
        .arst_n(arst_n),
        .d(context_temp),
        .q(context_out)
    );

    always_ff @(posedge clk) begin
        a_r <= a;
        b_r <= b;
        c_r <= c;
        d_r <= d;

        ab <= a + b;
        dc <= d - c;
        cd <= c + d;
    end

    always_ff @(posedge clk) begin
        k1 <= c_r * ab;
        k2 <= a_r * dc;
        k3 <= b_r * cd;
    end
    
    assign re = k1 - k3;
    assign im = k1 + k2; 

endmodule