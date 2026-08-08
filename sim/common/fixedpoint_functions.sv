package fixedpoint_functions;
    import params_package::*;

    function automatic real fixedpoint_to_float(logic [WIDTH-1:0] fixedpoint);
        real res;
        logic [WIDTH-1:0] positive_fixedpoint; 

        if (fixedpoint[WIDTH-1] == 1'b1) begin
            positive_fixedpoint = ~fixedpoint + 1'b1;
        end
        else begin
            positive_fixedpoint = fixedpoint;
        end

        res = real'(int'(positive_fixedpoint[WIDTH-1 -: INTEGER_WIDTH]));
        for(int i = FRAC_WIDTH - 1; i > -1; i = i - 1) begin
            if (positive_fixedpoint[i] == 1'b1) begin
                res = res + 2**(real'(i) - FRAC_WIDTH);
            end
        end

        if (fixedpoint[WIDTH-1] == 1'b1) begin
            res = -1.0 * res;
        end
        
        return res;
    endfunction


    function automatic real wide_fixedpoint_to_float(logic [2*WIDTH-1:0] fixedpoint);
        real res;
        logic [2*WIDTH-1:0] positive_fixedpoint; 

        if (fixedpoint[2*WIDTH-1] == 1'b1) begin
            positive_fixedpoint = ~fixedpoint + 1'b1;
        end
        else begin
            positive_fixedpoint = fixedpoint;
        end

        res = real'(int'(positive_fixedpoint[2*WIDTH-1 -: 2*INTEGER_WIDTH]));
        for(int i = 2*FRAC_WIDTH - 1; i > -1; i = i - 1) begin
            if (positive_fixedpoint[i] == 1'b1) begin
                res = res + 2**(real'(i) - 2*FRAC_WIDTH);
            end
        end

        if (fixedpoint[2*WIDTH-1] == 1'b1) begin
            res = -1.0 * res;
        end
        
        return res;
    endfunction

    // TODO: fixedpoint_to_float and wide_fixedpoint_to_float is ugly
    // TODO: Maybe need ABS function
endpackage