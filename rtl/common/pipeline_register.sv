module pipeline_register #(
    parameter WIDTH = 32
) (
    input logic clk,
    input logic arst_n,
    input logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);

    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            q <= 'b0;
        end
        else begin
            q <= d;
        end
    end
    
endmodule