module fifo #(
    parameter WIDTH = 32,
    parameter DEPTH = 32,

    localparam ADDRSIZE = $clog2(DEPTH),
    localparam CNTR_WIDTH = $clog2(DEPTH)+1
) (
    input  logic clk,
    input  logic arst_n,

    input  logic wr,
    input  logic rd,
    input  logic [WIDTH-1:0] data_in,
    output logic empty,
    output logic full,
    output logic [WIDTH-1:0] data_out
);

    logic [WIDTH-1:0] mem [0:DEPTH-1]; 
    
    logic [CNTR_WIDTH-1:0] rd_cnt, wr_cnt;

    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            rd_cnt <= 'b0;
        end
        else if(rd && !empty) begin
            // data_out <= mem[rd_cnt];
            rd_cnt <= rd_cnt + 1'b1;
        end
    end
    assign data_out = mem[rd_cnt[ADDRSIZE-1:0]];

    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            wr_cnt <= 'b0;
        end
        else if(wr && !full) begin
            mem[wr_cnt[ADDRSIZE-1:0]] <= data_in;
            wr_cnt <= wr_cnt + 1'b1;
        end
    end

    assign empty = (rd_cnt == wr_cnt);
    assign full =   (wr_cnt[CNTR_WIDTH-1] != rd_cnt[CNTR_WIDTH-1]) && 
                    (wr_cnt[ADDRSIZE-1:0] == rd_cnt[ADDRSIZE-1:0]); 

endmodule