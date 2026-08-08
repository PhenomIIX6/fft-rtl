module round_trunc_scale #(
    parameter INPUT_WIDTH = 32,
    parameter INPUT_INTEGER_WIDTH = 4,

    parameter OUTPUT_WIDTH = 16,
    parameter OUTPUT_INTEGER_WIDTH = 2,

    parameter ROUND = 1,
    parameter SATURATION = 1,
    parameter RADIX_OUT_SCALE = 1,

    localparam INPUT_FRAC_WIDTH = INPUT_WIDTH - INPUT_INTEGER_WIDTH,
    localparam OUTPUT_FRAC_WIDTH = OUTPUT_WIDTH - OUTPUT_INTEGER_WIDTH,
    localparam SHIFT_AMOUNT = INPUT_FRAC_WIDTH - OUTPUT_FRAC_WIDTH + RADIX_OUT_SCALE
) (
    input  logic signed [INPUT_WIDTH-1:0] a,
    output logic signed [OUTPUT_WIDTH-1:0] res 
);
    logic signed [OUTPUT_WIDTH-1:0] res_scaled;
    logic signed [OUTPUT_WIDTH-1:0] res_rounded;

    assign res_scaled = a >>> SHIFT_AMOUNT; 

    // Round or truncate
    generate
        if (ROUND && SHIFT_AMOUNT > 0) begin
            if (SHIFT_AMOUNT == 1) begin
                assign res = res_scaled + (a[0] && res_scaled[0]);
            end
            else begin
                logic is_middle;
                assign is_middle = a[SHIFT_AMOUNT-1] && !(|a[SHIFT_AMOUNT-2 : 0]);

                always_comb begin
                    if (is_middle) begin
                        res_rounded = res_scaled + res_scaled[0];    
                    end
                    else begin
                        res_rounded = res_scaled + a[SHIFT_AMOUNT-1];
                    end
                end
            end
        end
        else begin 
            assign res_rounded = res_scaled;
        end
    endgenerate
    
    // Saturation
    generate
        if (SATURATION) begin

            parameter FIXEDPOINT_MIN = {1'b1, {(OUTPUT_WIDTH-1){1'b0}}};
            parameter FIXEDPOINT_MAX = {1'b0, {(OUTPUT_WIDTH-1){1'b1}}};

            logic res_part_changed;
            assign res_part_changed = (res_scaled[OUTPUT_WIDTH-1 -: OUTPUT_INTEGER_WIDTH] != res_rounded[OUTPUT_WIDTH-1 -: OUTPUT_INTEGER_WIDTH]);

            logic signed [INPUT_INTEGER_WIDTH - 1 : 0] res_int_part;
            assign res_int_part = $signed(res_rounded[OUTPUT_WIDTH-1 -: OUTPUT_INTEGER_WIDTH]);
            
            always_comb begin
                if (res_int_part != {a >>> RADIX_OUT_SCALE}[INPUT_WIDTH-1 -: INPUT_INTEGER_WIDTH] + res_part_changed) begin
                    res = a[INPUT_WIDTH-1] ? FIXEDPOINT_MIN : FIXEDPOINT_MAX;
                end 
                else begin
                    res = res_rounded; 
                end
            end
        end
        else begin
            assign res = res_rounded;
        end
    endgenerate

endmodule