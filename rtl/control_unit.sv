module control_unit #(
    parameter N = 512,
    parameter WIDTH = 16,
    
    parameter SAMPLE_WIDTH = 2*WIDTH
) (
    input logic clk,
    input logic arst_n,

    // RAM INIT INTF
    input  logic ram_init_done,
    output logic ram_init_en,

    // RADIX 2 INTF
    input  logic radix_done,
    input  logic radix_stall,
    output logic radix_en,

    // RAM EXPORT INTF
    input  logic ram_export_done,
    output logic ram_export_en
);

    logic ram_init_stall;

    typedef enum logic [1:0] {  
        Init,
        Radix,
        Export
    } state_t;
    state_t state, nextstate;

    always_comb begin
        nextstate = state;
        case(state)
            Init: nextstate = ram_init_done ? Radix : Init; 
            Radix: nextstate = radix_done ? Export : Radix;
            Export: begin
                if (ram_export_done) begin
                    nextstate = ram_init_en ? Init : Radix;
                end
                else begin 
                    nextstate = Export;
                end
            end
            default: nextstate = state;
        endcase
    end

    always_comb begin
        ram_init_en = 'b0;
        radix_en = 'b0;
        ram_export_en = 'b0;
        case(state)
            Init: begin
                ram_init_en = 1'b1;
            end
            Radix: begin
                radix_en = !radix_stall;
            end
            Export: begin
                ram_export_en = 1'b1;
                ram_init_en = !ram_init_stall;
            end
        endcase
    end

    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            ram_init_stall <= 'b0;
        end
        else begin
            if (state == Export && ram_init_done) begin
                ram_init_stall <= 1'b1;
            end
            else begin
                ram_init_stall <= 'b0;
            end
        end
    end
  
    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            state <= Init;
        end
        else begin
            state <= nextstate;
        end
    end


endmodule