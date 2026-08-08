module rom #(    
    parameter WIDTH = 64,
    parameter DEPTH = 64,
    parameter INIT_FILE = "twiddle_factors.bin"
) (
    input logic clk,
    input logic arst_n,

    input  logic [$clog2(DEPTH)-1:0] addr,
    output logic [WIDTH-1:0] data_out
);

    logic [WIDTH-1:0] mem [0:DEPTH-1];

    initial begin
        $readmemb(INIT_FILE, mem);
    end

    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            data_out <= 'b0;
        end
        else begin
            data_out <= mem[addr];
        end
    end

endmodule