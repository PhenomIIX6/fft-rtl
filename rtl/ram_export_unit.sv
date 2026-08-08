module ram_export_unit #(
    parameter N = 512,
    parameter WIDTH = 16,
    
    parameter SAMPLE_WIDTH = 2*WIDTH 
) (
    input  logic clk,
    input  logic arst_n,

    input  logic en,
    output logic done,

    // AXIS MASTER
    output logic [SAMPLE_WIDTH-1:0] m_tdata,
    output logic m_tvalid,
    input  logic m_tready,

    // RAM INTF
    output logic [$clog2(N)-1:0] ram_rd_addr,
    input  logic [SAMPLE_WIDTH-1:0] ram_rd_data
);
    logic [$clog2(N)-1:0] counter;

    logic wr;
    logic rd;
    logic last;

    fifo #(
        .DEPTH(2),
        .WIDTH(SAMPLE_WIDTH)
    ) fifo_inst (
        .clk(clk),
        .arst_n(arst_n),
        .wr(wr),
        .rd(rd),
        .data_in(ram_rd_data),
        .empty(empty),
        .full(full),
        .data_out(m_tdata) 
    );

    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            counter <= 'b0;
            wr <= 1'b0;
        end
        else if(done) begin
            counter <= 'b0;
            wr <= 1'b0;
        end 
        else if(!full && en && !last) begin
            counter <= counter + 1'b1;
            wr <= 1'b1;
        end
        else begin
            wr <= 1'b0;
        end
    end

    assign ram_rd_addr = counter;

    assign m_tvalid = !empty;
    assign rd = (m_tvalid && m_tready);
    assign done = empty && last;

    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            last <= 1'b0;
        end
        else if (done) begin
            last <= 1'b0;
        end
        else if (counter == (N - 1'b1)) begin
            last <= 1'b1;
        end
    end

endmodule