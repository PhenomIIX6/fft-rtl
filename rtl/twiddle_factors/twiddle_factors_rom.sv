module twiddle_factors_rom #(
    parameter N = 512,
    parameter WIDTH = 16,
    parameter INIT_FILE = "twiddle_factors.bin",
    
    parameter SAMPLE_WIDTH = 2*WIDTH
) (
    input logic clk,
    input logic arst_n,

    input  logic [$clog2(N)-1:0] addr,
    output logic [SAMPLE_WIDTH-1:0] data_out
);

    logic [$clog2(N)-2-1:0] lsb_addr;
    assign lsb_addr = addr[$clog2(N)-2-1:0];

    logic [1:0] msb_addr;
    assign msb_addr = addr[$clog2(N)-1:$clog2(N)-2];

    logic [$clog2(N/4+1)-1:0] rom_addr;
    logic [SAMPLE_WIDTH-1:0] rom_data_out;

    logic special_points;
    assign special_points = (lsb_addr == 'b0 && msb_addr[0] == 1'b1); 
    always_comb begin
        rom_addr = 'b0;
        if (special_points) begin
            rom_addr = {1'b1, lsb_addr};
        end
        else begin
            rom_addr = {1'b0, lsb_addr};
        end
    end

    rom #(
        .WIDTH(SAMPLE_WIDTH),
        .DEPTH(N/4+1),
        .INIT_FILE(INIT_FILE)
    ) twiddle_factors_rom_inst (
        .clk(clk),
        .arst_n(arst_n),
        .addr(rom_addr),
        .data_out(rom_data_out)  
    );

    logic [1:0] swap_inverter_control;
    always_ff @(posedge clk) begin
        if (special_points) begin
            swap_inverter_control <= msb_addr - 1'b1;
        end
        else begin
            swap_inverter_control <= msb_addr;
        end
    end

    always_comb begin
        case(swap_inverter_control)
            2'b00: data_out = rom_data_out;
            2'b01: data_out = {~rom_data_out[SAMPLE_WIDTH-WIDTH-1 : 0] + 1'b1, rom_data_out[SAMPLE_WIDTH-1 -: WIDTH]};
            2'b10: data_out = {~rom_data_out[SAMPLE_WIDTH-1 -: WIDTH] + 1'b1, ~rom_data_out[SAMPLE_WIDTH-WIDTH-1 : 0] + 1'b1};
            2'b11: data_out = {rom_data_out[SAMPLE_WIDTH-WIDTH-1 : 0], ~rom_data_out[SAMPLE_WIDTH-1 -: WIDTH] + 1'b1};  
            default: data_out = 'b0;
        endcase
    end

endmodule