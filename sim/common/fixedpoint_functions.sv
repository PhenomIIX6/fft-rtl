package fixedpoint_functions;
    import params_package::*;

    virtual class Fixedpoint #(parameter WIDTH = 32);
        static function automatic real get_real(logic [WIDTH-1:0] fixedpoint);
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
    endclass

   // TODO: Maybe need ABS function
endpackage
