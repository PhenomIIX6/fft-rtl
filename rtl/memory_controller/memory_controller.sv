module memory_controller #(
    parameter N = 512,
    parameter WIDTH = 16,

    parameter ADDRSIZE = $clog2(N),
    parameter SAMPLE_WIDTH = 2*WIDTH
) (
    input  logic clk,
    input  logic arst_n,

    // CONTROL UNIT <-> MEMORY CONTROLLER INTF
    input logic ram_init_en,
    input logic radix_en,
    input logic radix_done,
    input logic ram_export_en,

    // RADIX <-> memory_controller intf
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

    // RAM INIT UNIT <-> memory_controller intf
    input logic [SAMPLE_WIDTH-1:0] init_ram_wr_data,
    input logic [ADDRSIZE-1:0] init_ram_wr_addr,
    input logic init_ram_wr_en,

    // RAM EXPORT UNIT <-> memory_controller intf
    input  logic [ADDRSIZE-1:0] export_ram_rd_addr,
    output logic [SAMPLE_WIDTH-1:0] export_ram_rd_data,

    // memory_controller <-> ram0 intf
    output  logic [ADDRSIZE-1:0] ram0_rd_addr_0,
    output  logic [ADDRSIZE-1:0] ram0_rd_addr_1,

    output  logic [ADDRSIZE-1:0] ram0_wr_addr_0,
    output  logic [ADDRSIZE-1:0] ram0_wr_addr_1,
    
    output  logic [SAMPLE_WIDTH-1:0]    ram0_wr_data_0,
    output  logic                       ram0_wr_en_0,
    output  logic [SAMPLE_WIDTH-1:0]    ram0_wr_data_1,
    output  logic                       ram0_wr_en_1,

    input   logic [SAMPLE_WIDTH-1:0]    ram0_rd_data_0,
    input   logic [SAMPLE_WIDTH-1:0]    ram0_rd_data_1,

    // memory_controller <-> ram1 intf
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
    logic init_target;
    logic export_target;

    assign export_target = !init_target;

    // PING-PONG 
    logic [ADDRSIZE-1:0] pp_ram0_rd_addr_0;
    logic [ADDRSIZE-1:0] pp_ram0_rd_addr_1;

    logic [ADDRSIZE-1:0] pp_ram0_wr_addr_0;
    logic [ADDRSIZE-1:0] pp_ram0_wr_addr_1;
    
    logic [SAMPLE_WIDTH-1:0]    pp_ram0_wr_data_0;
    logic                       pp_ram0_wr_en_0;
    logic [SAMPLE_WIDTH-1:0]    pp_ram0_wr_data_1;
    logic                       pp_ram0_wr_en_1;

    logic [SAMPLE_WIDTH-1:0]    pp_ram0_rd_data_0;
    logic [SAMPLE_WIDTH-1:0]    pp_ram0_rd_data_1;

    logic [ADDRSIZE-1:0] pp_ram1_rd_addr_0;
    logic [ADDRSIZE-1:0] pp_ram1_rd_addr_1;

    logic [ADDRSIZE-1:0] pp_ram1_wr_addr_0;
    logic [ADDRSIZE-1:0] pp_ram1_wr_addr_1;
    
    logic [SAMPLE_WIDTH-1:0]    pp_ram1_wr_data_0;
    logic                       pp_ram1_wr_en_0;
    logic [SAMPLE_WIDTH-1:0]    pp_ram1_wr_data_1;
    logic                       pp_ram1_wr_en_1;

    logic [SAMPLE_WIDTH-1:0]      pp_ram1_rd_data_0;
    logic [SAMPLE_WIDTH-1:0]      pp_ram1_rd_data_1;


    logic pp_stage1_ram_req, pp_stage2_ram_req;
    
    assign pp_stage1_ram_req = init_target ? !stage1_ram_req : stage1_ram_req;
    assign pp_stage2_ram_req = init_target ? !stage2_ram_req : stage2_ram_req;

    ping_pong #(
        .N(N),
        .WIDTH(WIDTH)
    ) ping_pong_inst (
        .clk(clk),
        .arst_n(arst_n),
        
        // RADIX-2 <-> ping-pong intf
        .radix_ram0_rd_addr_0(radix_ram0_rd_addr_0),
        .radix_ram0_rd_addr_1(radix_ram0_rd_addr_1),
        .radix_ram0_rd_data_0(radix_ram0_rd_data_0),
        .radix_ram0_rd_data_1(radix_ram0_rd_data_1),

        .radix_ram1_wr_addr_0(radix_ram1_wr_addr_0),
        .radix_ram1_wr_addr_1(radix_ram1_wr_addr_1),
        .radix_ram1_wr_data_0(radix_ram1_wr_data_0),
        .radix_ram1_wr_data_1(radix_ram1_wr_data_1),
        .radix_ram1_wr_en_0(radix_ram1_wr_en_0),
        .radix_ram1_wr_en_1(radix_ram1_wr_en_1),

        .radix_stall(radix_stall),

        .stage1_ram_req(pp_stage1_ram_req),
        .stage2_ram_req(pp_stage2_ram_req),

        // ping-pong <-> ram0 intf
        .ram0_rd_addr_0(pp_ram0_rd_addr_0),
        .ram0_rd_addr_1(pp_ram0_rd_addr_1),

        .ram0_wr_addr_0(pp_ram0_wr_addr_0),
        .ram0_wr_addr_1(pp_ram0_wr_addr_1),
        
        .ram0_wr_data_0(pp_ram0_wr_data_0),
        .ram0_wr_en_0(pp_ram0_wr_en_0),
        .ram0_wr_data_1(pp_ram0_wr_data_1),
        .ram0_wr_en_1(pp_ram0_wr_en_1),

        .ram0_rd_data_0(pp_ram0_rd_data_0),
        .ram0_rd_data_1(pp_ram0_rd_data_1),

        // ping-pong <-> ram1 intf
        .ram1_rd_addr_0(pp_ram1_rd_addr_0),
        .ram1_rd_addr_1(pp_ram1_rd_addr_1),

        .ram1_wr_addr_0(pp_ram1_wr_addr_0),
        .ram1_wr_addr_1(pp_ram1_wr_addr_1),
        
        .ram1_wr_data_0(pp_ram1_wr_data_0),
        .ram1_wr_en_0(pp_ram1_wr_en_0),
        .ram1_wr_data_1(pp_ram1_wr_data_1),
        .ram1_wr_en_1(pp_ram1_wr_en_1),

        .ram1_rd_data_0(pp_ram1_rd_data_0),
        .ram1_rd_data_1(pp_ram1_rd_data_1)
    );

    always_comb begin
        ram0_rd_addr_0 = 'b0; 
        ram0_rd_addr_1 = 'b0; 
        ram0_wr_addr_0 = 'b0; 
        ram0_wr_addr_1 = 'b0; 
        ram0_wr_data_0 = 'b0; 
        ram0_wr_en_0 = 'b0; 
        ram0_wr_data_1 = 'b0; 
        ram0_wr_en_1 = 'b0; 
        pp_ram0_rd_data_0 = 'b0;
        pp_ram0_rd_data_1 = 'b0;
        pp_ram1_rd_data_0 = 'b0;
        pp_ram1_rd_data_1 = 'b0;
        ram1_rd_addr_0 = 'b0; 
        ram1_rd_addr_1 = 'b0; 
        ram1_wr_addr_0 = 'b0; 
        ram1_wr_addr_1 = 'b0; 
        ram1_wr_data_0 = 'b0; 
        ram1_wr_en_0 = 'b0; 
        ram1_wr_data_1 = 'b0; 
        ram1_wr_en_1 = 'b0; 
        export_ram_rd_data = 'b0;
    
        if (ram_init_en) begin
            if (init_target) begin
                ram1_wr_data_0 = init_ram_wr_data;
                ram1_wr_addr_0 = init_ram_wr_addr;
                ram1_wr_en_0 = init_ram_wr_en;
            end
            else begin 
                ram0_wr_data_0 = init_ram_wr_data;
                ram0_wr_addr_0 = init_ram_wr_addr;
                ram0_wr_en_0 = init_ram_wr_en;
            end
        end

        if (radix_en || radix_stall) begin
            // RAM 0
            ram0_rd_addr_0 = pp_ram0_rd_addr_0; 
            ram0_rd_addr_1 = pp_ram0_rd_addr_1; 

            ram0_wr_addr_0 = pp_ram0_wr_addr_0; 
            ram0_wr_addr_1 = pp_ram0_wr_addr_1; 
            
            ram0_wr_data_0 = pp_ram0_wr_data_0; 
            ram0_wr_en_0 = pp_ram0_wr_en_0; 
            ram0_wr_data_1 = pp_ram0_wr_data_1; 
            ram0_wr_en_1 = pp_ram0_wr_en_1; 

            pp_ram0_rd_data_0 = ram0_rd_data_0;
            pp_ram0_rd_data_1 = ram0_rd_data_1;

            // RAM 1
            ram1_rd_addr_0 = pp_ram1_rd_addr_0; 
            ram1_rd_addr_1 = pp_ram1_rd_addr_1; 

            ram1_wr_addr_0 = pp_ram1_wr_addr_0; 
            ram1_wr_addr_1 = pp_ram1_wr_addr_1; 
            
            ram1_wr_data_0 = pp_ram1_wr_data_0; 
            ram1_wr_en_0 = pp_ram1_wr_en_0; 
            ram1_wr_data_1 = pp_ram1_wr_data_1; 
            ram1_wr_en_1 = pp_ram1_wr_en_1; 

            pp_ram1_rd_data_0 = ram1_rd_data_0;
            pp_ram1_rd_data_1 = ram1_rd_data_1;
        end

        if (ram_export_en) begin
            if (export_target) begin
                ram1_rd_addr_0 = export_ram_rd_addr;
                export_ram_rd_data = ram1_rd_data_0;
            end
            else begin
                ram0_rd_addr_0 = export_ram_rd_addr;
                export_ram_rd_data = ram0_rd_data_0;
            end
        end

    end

    generate
        if ($clog2(N) % 2) begin
            assign init_target = 1'b0;
        end
        else begin
            always_ff @(posedge clk or negedge arst_n) begin
                if (!arst_n) begin
                    init_target <= 'b0;
                end
                else if (radix_done) begin
                    init_target <= !init_target;
                end
            end
        end
    endgenerate


endmodule