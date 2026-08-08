module dpram #(
    parameter WIDTH = 32,
    parameter DEPTH = 32,

    localparam ADDRSIZE = $clog2(DEPTH)
) (
    input  logic clk,

    input  logic [ADDRSIZE-1:0] rd_addr_0,
    input  logic [ADDRSIZE-1:0] rd_addr_1,

    input  logic [ADDRSIZE-1:0] wr_addr_0,
    input  logic [ADDRSIZE-1:0] wr_addr_1,

    input  logic [WIDTH-1:0]    wr_data_0,
    input  logic                wr_en_0,
    input  logic [WIDTH-1:0]    wr_data_1,
    input  logic                wr_en_1,

    output logic [WIDTH-1:0] rd_data_0,
    output logic [WIDTH-1:0] rd_data_1
);

    logic [WIDTH-1:0] mem [0:DEPTH-1];

    always_ff @(posedge clk) begin
        if (wr_en_0) begin
            mem[wr_addr_0] <= wr_data_0;
        end
        else begin
            rd_data_0 <= mem[rd_addr_0];
        end

        if (wr_en_1) begin
            mem[wr_addr_1] <= wr_data_1;
        end
        else begin
            rd_data_1 <= mem[rd_addr_1];
        end
    end

endmodule