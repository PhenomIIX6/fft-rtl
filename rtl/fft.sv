module fft #(
    parameter N = 512,

    parameter WIDTH = 16,
    parameter INTEGER_WIDTH = 2,
    
    parameter ROUND = 1,
    // parameter SCALE_IN = 1,
    parameter RADIX_OUT_SCALE = 1, 
    parameter SATURATION = 1,

    parameter SAMPLE_WIDTH = 2*WIDTH,
    parameter ADDRSIZE = $clog2(N)
) (
    input  logic clk,
    input  logic arst_n,

    // AXIS SLAVE
    input  logic [SAMPLE_WIDTH-1:0] s_tdata,
    input  logic s_tvalid,
    output logic s_tready,

    // AXIS MASTER
    output logic [SAMPLE_WIDTH-1:0] m_tdata,
    output logic m_tvalid,
    input  logic m_tready

);

    // CONTROL UNIT
    logic ram_init_done, ram_init_en;
    logic radix_done, radix_stall, radix_en;
    logic ram_export_done, ram_export_en;

    control_unit #(
        .N(N),
        .WIDTH(WIDTH)
    ) cu (
        .clk(clk),
        .arst_n(arst_n),

        // RAM INIT INTF
        .ram_init_done(ram_init_done),
        .ram_init_en(ram_init_en),

        // RADIX 2 INTF
        .radix_done(radix_done),
        .radix_stall(radix_stall),
        .radix_en(radix_en),

        // RAM EXPORT INTF
        .ram_export_done(ram_export_done),
        .ram_export_en(ram_export_en)
    );

    // RAM 0
    logic [ADDRSIZE-1:0] ram0_addr_0, ram0_addr_1;
    logic [SAMPLE_WIDTH-1:0] ram0_rd_data_0, ram0_rd_data_1;
    logic [SAMPLE_WIDTH-1:0] ram0_wr_data_0, ram0_wr_data_1;
    logic ram0_wr_en_0, ram0_wr_en_1;

    dpram #(
        .WIDTH(SAMPLE_WIDTH),
        .DEPTH(N)
    ) dpram_inst_0 (
        .clk(clk),
        .addr_0(ram0_addr_0),
        .addr_1(ram0_addr_1),
        .wr_data_0(ram0_wr_data_0),
        .wr_en_0(ram0_wr_en_0),
        .wr_data_1(ram0_wr_data_1),
        .wr_en_1(ram0_wr_en_1),
        .rd_data_0(ram0_rd_data_0),
        .rd_data_1(ram0_rd_data_1)
    );

    // RAM 1
    logic [ADDRSIZE-1:0] ram1_addr_0, ram1_addr_1;
    logic [SAMPLE_WIDTH-1:0] ram1_rd_data_0, ram1_rd_data_1;
    logic [SAMPLE_WIDTH-1:0] ram1_wr_data_0, ram1_wr_data_1;
    logic ram1_wr_en_0, ram1_wr_en_1;

    dpram #(
        .WIDTH(SAMPLE_WIDTH),
        .DEPTH(N)
    ) dpram_inst_1 (
        .clk(clk),
        .addr_0(ram1_addr_0),
        .addr_1(ram1_addr_1),
        .wr_data_0(ram1_wr_data_0),
        .wr_en_0(ram1_wr_en_0),
        .wr_data_1(ram1_wr_data_1),
        .wr_en_1(ram1_wr_en_1),
        .rd_data_0(ram1_rd_data_0),
        .rd_data_1(ram1_rd_data_1)
    );

    // RAM INIT UNIT
    logic [SAMPLE_WIDTH-1:0] init_ram_wr_data;
    logic [ADDRSIZE-1:0] init_ram_wr_addr;
    logic init_ram_wr_en;

    ram_init_unit #(
        .N(N),
        .WIDTH(WIDTH)
        // .SCALE_IN(SCALE_IN)
    ) ram_init_unit_inst (
        .clk(clk),
        .arst_n(arst_n),

        .en(ram_init_en),
        .done(ram_init_done),

        // AXIS SLAVE
        .s_tdata(s_tdata),
        .s_tvalid(s_tvalid),
        .s_tready(s_tready),

        // RAM INTF
        .ram_wr_data(init_ram_wr_data),
        .ram_wr_addr(init_ram_wr_addr),
        .ram_wr_en(init_ram_wr_en)
    );

    // RADIX
    logic [ADDRSIZE-1:0] radix_ram0_addr_0, radix_ram1_addr_0;
    logic [ADDRSIZE-1:0] radix_ram0_addr_1, radix_ram1_addr_1;
    logic [SAMPLE_WIDTH-1:0] radix_ram0_rd_data_0, radix_ram0_rd_data_1;
    logic [SAMPLE_WIDTH-1:0] radix_ram1_wr_data_0, radix_ram1_wr_data_1;
    logic radix_ram1_wr_en_0, radix_ram1_wr_en_1;

    logic stage1_ram_req;
    logic stage2_ram_req;
    
    radix2_top #(
        .N(N),
        .WIDTH(WIDTH),
        .INTEGER_WIDTH(INTEGER_WIDTH),
        .ROUND(ROUND),
        .RADIX_OUT_SCALE(RADIX_OUT_SCALE),
        .SATURATION(SATURATION)
    ) radix2_inst (
        .clk(clk),
        .arst_n(arst_n),
        
        .en(radix_en),
        .done(radix_done),

        .ram0_addr_0(radix_ram0_addr_0),
        .ram0_addr_1(radix_ram0_addr_1),
        .ram0_rd_data_0(radix_ram0_rd_data_0),
        .ram0_rd_data_1(radix_ram0_rd_data_1),

        .ram1_addr_0(radix_ram1_addr_0),
        .ram1_addr_1(radix_ram1_addr_1),
        .ram1_wr_data_0(radix_ram1_wr_data_0),
        .ram1_wr_data_1(radix_ram1_wr_data_1),
        .ram1_wr_en_0(radix_ram1_wr_en_0),
        .ram1_wr_en_1(radix_ram1_wr_en_1),

        .stage1_ram_req(stage1_ram_req),
        .stage2_ram_req(stage2_ram_req)
    );

    // RAM EXPORT UNIT
    logic [ADDRSIZE-1:0] export_ram_rd_addr;
    logic [SAMPLE_WIDTH-1:0] export_ram_rd_data;

    ram_export_unit #(
        .N(N),
        .WIDTH(WIDTH)
    ) ram_export_unit_inst (
        .clk(clk),
        .arst_n(arst_n),

        .en(ram_export_en),
        .done(ram_export_done),

        // AXIS MASTER
        .m_tdata(m_tdata),
        .m_tvalid(m_tvalid),
        .m_tready(m_tready),

        // RAM INTF
        .ram_rd_addr(export_ram_rd_addr),
        .ram_rd_data(export_ram_rd_data)
    );

    // MEMORY CONTROLLER
    memory_controller #(
        .N(N),
        .WIDTH(WIDTH)
    ) mc (
        .clk(clk),
        .arst_n(arst_n),

        // CONTROL UNIT <-> MEMORY CONTROLLER INTF
        .ram_init_en(ram_init_en),
        .radix_en(radix_en),
        .radix_done(radix_done),
        .ram_export_en(ram_export_en),

        // RADIX <-> memory_controller intf
        .radix_ram0_addr_0(radix_ram0_addr_0),
        .radix_ram0_addr_1(radix_ram0_addr_1),
        .radix_ram0_rd_data_0(radix_ram0_rd_data_0),
        .radix_ram0_rd_data_1(radix_ram0_rd_data_1),

        .radix_ram1_addr_0(radix_ram1_addr_0),
        .radix_ram1_addr_1(radix_ram1_addr_1),
        .radix_ram1_wr_data_0(radix_ram1_wr_data_0),
        .radix_ram1_wr_data_1(radix_ram1_wr_data_1),
        .radix_ram1_wr_en_0(radix_ram1_wr_en_0),
        .radix_ram1_wr_en_1(radix_ram1_wr_en_1),

        .radix_stall(radix_stall),

        .stage1_ram_req(stage1_ram_req),
        .stage2_ram_req(stage2_ram_req),

        // RAM INIT UNIT <-> memory_controller intf
        .init_ram_wr_data(init_ram_wr_data),
        .init_ram_wr_addr(init_ram_wr_addr),
        .init_ram_wr_en(init_ram_wr_en),

        // RAM EXPORT UNIT <-> memory_controller intf
        .export_ram_rd_addr(export_ram_rd_addr),
        .export_ram_rd_data(export_ram_rd_data),

        // memory_controller <-> ram0 intf
        .ram0_addr_0(ram0_addr_0),
        .ram0_addr_1(ram0_addr_1),

        .ram0_wr_data_0(ram0_wr_data_0),
        .ram0_wr_en_0(ram0_wr_en_0),
        .ram0_wr_data_1(ram0_wr_data_1),
        .ram0_wr_en_1(ram0_wr_en_1),

        .ram0_rd_data_0(ram0_rd_data_0),
        .ram0_rd_data_1(ram0_rd_data_1),

        // memory_controller <-> ram1 intf
        .ram1_addr_0(ram1_addr_0),
        .ram1_addr_1(ram1_addr_1),

        .ram1_wr_data_0(ram1_wr_data_0),
        .ram1_wr_en_0(ram1_wr_en_0),
        .ram1_wr_data_1(ram1_wr_data_1),
        .ram1_wr_en_1(ram1_wr_en_1),

        .ram1_rd_data_0(ram1_rd_data_0),
        .ram1_rd_data_1(ram1_rd_data_1)
    );


endmodule