module complex_multiplier_pipe #(
    parameter WIDTH = 16,
    parameter INTEGER_WIDTH = 2,

    parameter SAMPLE_WIDTH = 2*WIDTH
) (
    input logic clk,

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

    assign a = $signed(z0[SAMPLE_WIDTH-1 -: WIDTH]);
    assign b = $signed(z0[WIDTH-1 : 0]);
    assign c = $signed(z1[SAMPLE_WIDTH-1 -: WIDTH]);
    assign d = $signed(z1[WIDTH-1 : 0]);

    logic signed [2*WIDTH:0] k1, k2, k3;

    always_ff @(posedge clk) begin
        k1 <= c * (a + b);
        k2 <= a * (d - c);
        k3 <= b * (c + d);
    end
    
    assign re = k1 - k3;
    assign im = k1 + k2; 

endmodule