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
    // Reserve FIFO space when issuing a synchronous RAM read, not when its
    // result arrives one cycle later. Otherwise a read already in flight is
    // discarded when the FIFO becomes full under AXIS backpressure.
    logic [$clog2(N):0] issued_count;
    logic [1:0] reserved;
    logic read_pending;
    logic issue_read;

    logic wr;
    logic rd;
    logic empty;
    logic full;

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

    assign issue_read = en && (issued_count < N) && ((reserved < 2) || rd);
    assign wr = read_pending;
    assign ram_rd_addr = issued_count[$clog2(N)-1:0];

    assign m_tvalid = !empty;
    assign rd = (m_tvalid && m_tready);
    assign done = en && (issued_count == N) && (reserved == 0);

    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            issued_count <= '0;
            reserved <= '0;
            read_pending <= 1'b0;
        end
        else if (done) begin
            issued_count <= '0;
            reserved <= '0;
            read_pending <= 1'b0;
        end
        else begin
            read_pending <= issue_read;
            if (issue_read) issued_count <= issued_count + 1'b1;
            case ({issue_read, rd})
                2'b10: reserved <= reserved + 1'b1;
                2'b01: reserved <= reserved - 1'b1;
                default: reserved <= reserved;
            endcase
        end
    end

endmodule
