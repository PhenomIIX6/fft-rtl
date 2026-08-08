module ram_init_unit #(
    parameter N = 512,
    parameter WIDTH = 16,
    // parameter SCALE_IN = 1,
    
    localparam SAMPLE_WIDTH = 2*WIDTH 
) (
    input  logic clk,
    input  logic arst_n,

    input  logic en,
    output logic done,

    // AXIS SLAVE
    input  logic [SAMPLE_WIDTH-1:0] s_tdata,
    input  logic s_tvalid,
    output logic s_tready,

    // RAM INTF
    output logic [SAMPLE_WIDTH-1:0] ram_wr_data,
    output logic [$clog2(N)-1:0] ram_wr_addr,
    output logic ram_wr_en
);
    // TODO: Realize SCALE_IN parameter

    logic [$clog2(N)-1:0] counter;
    logic [$clog2(N)-1:0] bit_reverse_counter;

    // Bit reverse
    genvar i;
    generate
        for(i = 0; i < N; i = i + 1) begin
            assign bit_reverse_counter[i] = counter[$clog2(N)-i-1];
        end
    endgenerate

    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            counter <= 'b0;
            ram_wr_data <= 'b0;
            ram_wr_addr <= 'b0;
            ram_wr_en <= 'b0;
            done <= 'b0;
        end
        else if(done) begin
            counter <= 'b0;
            ram_wr_data <= 'b0;
            ram_wr_addr <= 'b0;
            ram_wr_en <= 'b0;
            done <= 'b0;
        end
        else begin
            done <= (ram_wr_addr == N-1);
            
            if ((s_tvalid && s_tready) && en) begin
                ram_wr_addr <= bit_reverse_counter;
                ram_wr_data <= s_tdata;
                counter <= counter + 1'b1;
                ram_wr_en <= 1'b1;
            end
            else begin
                ram_wr_en <= 1'b0;
            end
        end
    end 

    assign s_tready = !done && en;
endmodule