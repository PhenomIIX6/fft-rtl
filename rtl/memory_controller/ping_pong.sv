module ping_pong #(
    parameter N = 512,
    parameter WIDTH = 16,

    localparam ADDRSIZE = $clog2(N),
    localparam SAMPLE_WIDTH = 2*WIDTH
) (
    input  logic clk,
    input  logic arst_n,

    // RADIX-2 <-> ping-pong intf
    input  logic [ADDRSIZE-1:0] radix_ram0_rd_addr_0,
    input  logic [ADDRSIZE-1:0] radix_ram0_rd_addr_1,
    output logic [SAMPLE_WIDTH-1:0] radix_ram0_rd_data_0,
    output logic [SAMPLE_WIDTH-1:0] radix_ram0_rd_data_1,

    input  logic [ADDRSIZE-1:0] radix_ram1_wr_addr_0,
    input  logic [ADDRSIZE-1:0] radix_ram1_wr_addr_1,
    input  logic [SAMPLE_WIDTH-1:0] radix_ram1_wr_data_0,
    input  logic [SAMPLE_WIDTH-1:0] radix_ram1_wr_data_1,
    input  logic radix_ram1_wr_en_0,
    input  logic radix_ram1_wr_en_1,

    output logic radix_stall,

    input  logic stage1_ram_req,
    input  logic stage2_ram_req,

    // ping-pong <-> ram0 intf
    output  logic [ADDRSIZE-1:0] ram0_rd_addr_0,
    output  logic [ADDRSIZE-1:0] ram0_rd_addr_1,

    output  logic [ADDRSIZE-1:0] ram0_wr_addr_0,
    output  logic [ADDRSIZE-1:0] ram0_wr_addr_1,
    
    output  logic [SAMPLE_WIDTH-1:0]    ram0_wr_data_0,
    output  logic                       ram0_wr_en_0,
    output  logic [SAMPLE_WIDTH-1:0]    ram0_wr_data_1,
    output  logic                       ram0_wr_en_1,

    input logic [SAMPLE_WIDTH-1:0]      ram0_rd_data_0,
    input logic [SAMPLE_WIDTH-1:0]      ram0_rd_data_1,

    // ping-pong <-> ram1 intf
    output  logic [ADDRSIZE-1:0] ram1_rd_addr_0,
    output  logic [ADDRSIZE-1:0] ram1_rd_addr_1,

    output  logic [ADDRSIZE-1:0] ram1_wr_addr_0,
    output  logic [ADDRSIZE-1:0] ram1_wr_addr_1,
    
    output  logic [SAMPLE_WIDTH-1:0]    ram1_wr_data_0,
    output  logic                       ram1_wr_en_0,
    output  logic [SAMPLE_WIDTH-1:0]    ram1_wr_data_1,
    output  logic                       ram1_wr_en_1,

    input logic [SAMPLE_WIDTH-1:0]      ram1_rd_data_0,
    input logic [SAMPLE_WIDTH-1:0]      ram1_rd_data_1

);
    logic radix_stall_r;

    assign radix_stall = (stage1_ram_req == stage2_ram_req) && !radix_stall_r;

    always_comb begin
        radix_ram0_rd_data_0 = 'b0;
        radix_ram0_rd_data_1 = 'b0;
        ram0_rd_addr_0 = 'b0;
        ram0_rd_addr_1 = 'b0;
        ram0_wr_addr_0 = 'b0;
        ram0_wr_addr_1 = 'b0;
        ram0_wr_data_0 = 'b0;
        ram0_wr_en_0 = 'b0;
        ram0_wr_data_1 = 'b0;
        ram0_wr_en_1 = 'b0;
        ram1_rd_addr_0 = 'b0;
        ram1_rd_addr_1 = 'b0;
        ram1_wr_addr_0 = 'b0;
        ram1_wr_addr_1 = 'b0;
        ram1_wr_data_0 = 'b0;
        ram1_wr_en_0 = 'b0;
        ram1_wr_data_1 = 'b0;
        ram1_wr_en_1 = 'b0;
        
        if (!radix_stall) begin
            if (!stage1_ram_req) begin
                radix_ram0_rd_data_0 = ram0_rd_data_0;
                radix_ram0_rd_data_1 = ram0_rd_data_1;
                
                ram0_rd_addr_0 = radix_ram0_rd_addr_0;
                ram0_rd_addr_1 = radix_ram0_rd_addr_1;
                
                ram1_wr_addr_0 = radix_ram1_wr_addr_0;
                ram1_wr_addr_1 = radix_ram1_wr_addr_1;
                
                ram1_wr_data_0 = radix_ram1_wr_data_0;
                ram1_wr_en_0 = radix_ram1_wr_en_0;
                ram1_wr_data_1 = radix_ram1_wr_data_1;
                ram1_wr_en_1 = radix_ram1_wr_en_1;
            end
            else begin
                radix_ram0_rd_data_0 = ram1_rd_data_0;
                radix_ram0_rd_data_1 = ram1_rd_data_1;
                
                ram1_rd_addr_0 = radix_ram0_rd_addr_0;
                ram1_rd_addr_1 = radix_ram0_rd_addr_1;
                
                ram0_wr_addr_0 = radix_ram1_wr_addr_0;
                ram0_wr_addr_1 = radix_ram1_wr_addr_1;
                
                ram0_wr_data_0 = radix_ram1_wr_data_0;
                ram0_wr_en_0 = radix_ram1_wr_en_0;
                ram0_wr_data_1 = radix_ram1_wr_data_1;
                ram0_wr_en_1 = radix_ram1_wr_en_1;
            end
        end
        else begin
            if (!stage2_ram_req) begin
                ram0_wr_addr_0 = radix_ram1_wr_addr_0;
                ram0_wr_addr_1 = radix_ram1_wr_addr_1;
                
                ram0_wr_data_0 = radix_ram1_wr_data_0;
                ram0_wr_en_0 = radix_ram1_wr_en_0;
                ram0_wr_data_1 = radix_ram1_wr_data_1;
                ram0_wr_en_1 = radix_ram1_wr_en_1;

                radix_ram0_rd_data_0 = ram1_rd_data_0;
                radix_ram0_rd_data_1 = ram1_rd_data_1;
            end
            else begin
                ram1_wr_addr_0 = radix_ram1_wr_addr_0;
                ram1_wr_addr_1 = radix_ram1_wr_addr_1;
                
                ram1_wr_data_0 = radix_ram1_wr_data_0;
                ram1_wr_en_0 = radix_ram1_wr_en_0;
                ram1_wr_data_1 = radix_ram1_wr_data_1;
                ram1_wr_en_1 = radix_ram1_wr_en_1;

                radix_ram0_rd_data_0 = ram0_rd_data_0;
                radix_ram0_rd_data_1 = ram0_rd_data_1;
            end
        end
    end

    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            radix_stall_r <= 'b0;
        end
        else begin
            radix_stall_r <= radix_stall;
        end
    end
endmodule