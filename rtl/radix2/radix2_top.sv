module radix2_top #(
    parameter N = 512,
    parameter WIDTH = 16,
    parameter INTEGER_WIDTH = 2,
    parameter ROM_INIT_FILE = "./twiddle_factors.bin",
    parameter ROUND = 1,
    parameter RADIX_OUT_SCALE = 1,
    parameter SATURATION = 1,

    parameter SAMPLE_WIDTH = 2*WIDTH
) (
    input  logic clk,
    input  logic arst_n,
    
    input  logic en,
    output logic done,

    output logic [$clog2(N)-1:0] ram0_addr_0,
    output logic [$clog2(N)-1:0] ram0_addr_1,
    input  logic [SAMPLE_WIDTH-1:0] ram0_rd_data_0,
    input  logic [SAMPLE_WIDTH-1:0] ram0_rd_data_1,

    output logic [$clog2(N)-1:0] ram1_addr_0,
    output logic [$clog2(N)-1:0] ram1_addr_1,
    output logic [SAMPLE_WIDTH-1:0] ram1_wr_data_0,
    output logic [SAMPLE_WIDTH-1:0] ram1_wr_data_1,
    output logic ram1_wr_en_0,
    output logic ram1_wr_en_1,

    output logic stage_read_ram_req,
    output logic stage_write_ram_req
);
    typedef struct packed {
        logic [$clog2(N)-1:0] tw_factor_addr;
        logic [$clog2(N)-1:0] old_left_addr;
        logic [$clog2(N)-1:0] old_right_addr;
    } stage1_t;

    typedef struct packed {
        logic [SAMPLE_WIDTH-1:0] tw_factor_0;
        logic [SAMPLE_WIDTH-1:0] tw_factor_1;
        logic [SAMPLE_WIDTH-1:0] old_left;
        logic [SAMPLE_WIDTH-1:0] old_right;
        logic [$clog2(N)-1:0] new_left_addr;
        logic [$clog2(N)-1:0] new_right_addr;
    } stage2_t;

    typedef struct packed {
        logic [SAMPLE_WIDTH-1:0] new_left;
        logic [SAMPLE_WIDTH-1:0] new_right;
        logic [$clog2(N)-1:0] new_left_addr;
        logic [$clog2(N)-1:0] new_right_addr; 
    } stage3_t;

    typedef struct packed {
        logic [$clog2(N)-1:0] offset;
        logic [$clog2(N)-1:0] r;
        logic [$clog2(N)-1:0] subarray;
        logic valid;
        logic last;
    } common_stage_t;

    stage1_t stage1;
    stage2_t stage2;
    stage3_t stage3;
    common_stage_t stage1_common, stage2_common, stage3_common;
    
    // STAGE 1 - READ TWIDDLE FACTORS AND old_left, old_right
    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            stage1_common.offset <= 'b0;
            stage1_common.r <= 'b0;
            stage1_common.subarray <= 'b0;
        end
        else if (done) begin
            stage1_common.offset <= 'b0;
            stage1_common.r <= 'b0;
            stage1_common.subarray <= 'b0;
        end
        else if (stage1_common.valid && !stage1_common.last) begin
            stage1_common.offset <= stage1_common.offset + 1'b1;
            if (stage1_common.offset == ((1 << stage1_common.r) - 1'b1)) begin
                stage1_common.offset <= 'b0;
                stage1_common.subarray <= stage1_common.subarray + 1'b1;
                if (stage1_common.subarray == ((N >> (stage1_common.r + 1)) - 1'b1)) begin
                    stage1_common.offset <= 'b0;
                    stage1_common.subarray <= 'b0;
                    stage1_common.r <= stage1_common.r + 1'b1;
                end
            end
        end
    end

    assign stage1_common.last = (stage1_common.offset == ((1 << stage1_common.r) - 1'b1)) &&
                                (stage1_common.subarray == ((N >> (stage1_common.r + 1)) - 1'b1)) &&
                                (stage1_common.r == ($clog2(N) - 1'b1));

    assign stage1_common.valid = en && !stage2_common.last;
    
    assign stage1.tw_factor_addr = stage1_common.offset << ($clog2(N) - (stage1_common.r + 1));
    assign stage1.old_left_addr = (stage1_common.subarray << (stage1_common.r+1)) + stage1_common.offset;
    assign stage1.old_right_addr = (stage1_common.subarray << (stage1_common.r+1)) + stage1_common.offset + (1 << stage1_common.r);

    twiddle_factors_rom #(
        .N(N),
        .WIDTH(WIDTH),
        .INIT_FILE(ROM_INIT_FILE)
    ) tw_factors_rom_inst_0 (
        .clk(clk),
        .arst_n(arst_n),
        .addr(stage1.tw_factor_addr),
        .data_out(stage2.tw_factor_0)
    );

    pipeline_register #(
        .WIDTH($bits(common_stage_t))
    ) stage1_to_stage2 (
        .clk(clk),
        .arst_n(arst_n),
        .d(stage1_common),
        .q(stage2_common)
    );

    // STAGE 2 - COMPUTE
    assign stage2.tw_factor_1 = {
        ~stage2.tw_factor_0[SAMPLE_WIDTH-1:WIDTH] + 1'b1,
        ~stage2.tw_factor_0[WIDTH-1:0] + 1'b1
    };
    
    radix2_core #(
        .WIDTH(WIDTH),
        .INTEGER_WIDTH(INTEGER_WIDTH),
        .ROUND(ROUND),
        .RADIX_OUT_SCALE(RADIX_OUT_SCALE),
        .SATURATION(SATURATION),
        .CONTEXT_WIDTH($bits(common_stage_t) + $bits(stage2.new_left_addr) + $bits(stage2.new_right_addr))
    ) radix2_core_inst (
        .clk(clk),
        .arst_n(arst_n),

        .context_in(
            {
                stage2_common,
                stage2.new_left_addr,
                stage2.new_right_addr
            }
        ),
        .context_out(
            {
                stage3_common,
                stage3.new_left_addr,
                stage3.new_right_addr
            }
        ),

        .old_left(stage2.old_left),        
        .old_right(stage2.old_right),
        .tw_factor_0(stage2.tw_factor_0),
        .tw_factor_1(stage2.tw_factor_1),
        .new_left(stage3.new_left),
        .new_right(stage3.new_right)
    );

    assign stage2.new_left_addr = ( stage2_common.subarray << (stage2_common.r+1) ) + stage2_common.offset;
    assign stage2.new_right_addr = ( stage2_common.subarray << (stage2_common.r+1) ) + stage2_common.offset + (1 << stage2_common.r);

    // STAGE 3 - WRITE BACK
    always_comb begin
        ram0_addr_0 = 'b0;
        ram0_addr_1 = 'b0;
        ram1_addr_0 = 'b0;
        ram1_addr_1 = 'b0;
        ram1_wr_data_0 = 'b0;
        ram1_wr_data_1 = 'b0;
        ram1_wr_en_0 = 'b0;
        ram1_wr_en_1 = 'b0;
        
        if (stage1_common.valid) begin
            ram0_addr_0 = stage1.old_left_addr;
            ram0_addr_1 = stage1.old_right_addr;
        end

        if (stage3_common.valid) begin
            ram1_addr_0 = stage3.new_left_addr;
            ram1_addr_1 = stage3.new_right_addr;
            ram1_wr_data_0 = stage3.new_left;
            ram1_wr_data_1 = stage3.new_right;
            ram1_wr_en_0 = 1'b1;
            ram1_wr_en_1 = 1'b1;
        end

        stage2.old_left = ram0_rd_data_0;
        stage2.old_right = ram0_rd_data_1;
    end

    assign stage_read_ram_req = stage1_common.r[0];
    assign stage_write_ram_req = !stage3_common.r[0];

    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            done <= 1'b0;
        end
        else begin
            if (stage3_common.valid && stage3_common.last) begin
                done <= 1'b1;
            end
            else begin
                done <= 1'b0;
            end
        end
    end

endmodule