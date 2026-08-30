module radix2_core_tb;
    import params_package::*;
    import complex_t_package::*;
    import fixedpoint_functions::*;

    typedef enum 
    {  
        PASS,
        FAIL,
        SKIP
    } check_status_t;

    import "DPI-C" function void complex_mac(complex_t a, complex_t b, complex_t c, output complex_t out);
    
    logic clk;
    logic arst_n;

    logic [SAMPLE_WIDTH-1:0] old_left;
    logic [SAMPLE_WIDTH-1:0] old_right;
    logic [SAMPLE_WIDTH-1:0] tw_factor_0;
    logic [SAMPLE_WIDTH-1:0] tw_factor_1;
    logic [SAMPLE_WIDTH-1:0] new_left;
    logic [SAMPLE_WIDTH-1:0] new_right;

    class Packet;
        rand bit [SAMPLE_WIDTH-1:0] old_left;
        rand bit [SAMPLE_WIDTH-1:0] old_right;
        rand bit [SAMPLE_WIDTH-1:0] tw_factor_0;
        rand bit [SAMPLE_WIDTH-1:0] tw_factor_1;


        // TODO: Rename function "hueta"
        function automatic bit [WIDTH-1:0] hueta(logic [WIDTH-1:0] a, logic [WIDTH-1:0] max_value);
            logic [WIDTH-1:0] a_abs;
            if (a[WIDTH-1]) begin
                a_abs = ~a + 1'b1;
            end
            else begin
                a_abs = a;
            end

            a_abs = a_abs % (max_value + 1);

            if (a[WIDTH-1]) begin
                return ~a_abs + 1'b1;
            end
            else begin
                return a_abs;
            end

        endfunction

        function automatic bit [SAMPLE_WIDTH-1:0] get_old_left();
            return old_left;
        endfunction

        function automatic bit [SAMPLE_WIDTH-1:0] get_old_right();
            return old_right;
        endfunction

        function automatic bit [SAMPLE_WIDTH-1:0] get_tw_factor_0();
            logic [WIDTH-1:0] re, im;
            logic [WIDTH-1:0] max_value;
            max_value = {{INTEGER_WIDTH-1{1'b0}}, 1'b1, {FRAC_WIDTH{1'b0}}};

            re = hueta(tw_factor_0[SAMPLE_WIDTH-1 -: WIDTH], max_value);
            im = hueta(tw_factor_0[WIDTH-1 : 0], max_value);

            return {re, im};  
        endfunction

        function automatic bit [SAMPLE_WIDTH-1:0] get_tw_factor_1();
            logic [WIDTH-1:0] re, im;
            logic [WIDTH-1:0] max_value;
            max_value = {{INTEGER_WIDTH-1{1'b0}}, 1'b1, {FRAC_WIDTH{1'b0}}};

            re = hueta(tw_factor_1[SAMPLE_WIDTH-1 -: WIDTH], max_value);
            im = hueta(tw_factor_1[WIDTH-1 : 0], max_value);

            return {re, im};  
        endfunction

    endclass

    function automatic void scale(ref complex_t a);
        a.re = a.re / (1 << RADIX_OUT_SCALE);
        a.im = a.im / (1 << RADIX_OUT_SCALE);
    endfunction

    function automatic logic saturate(ref real saturated);
        if (saturated > Fixedpoint#(WIDTH)::get_real(FIXEDPOINT_MAX)) begin
            saturated = Fixedpoint#(WIDTH)::get_real(FIXEDPOINT_MAX);
            return 1'b1;
        end
        else if (saturated < Fixedpoint#(WIDTH)::get_real(FIXEDPOINT_MIN))begin
            saturated = Fixedpoint#(WIDTH)::get_real(FIXEDPOINT_MIN);
            return 1'b1;
        end
        else begin
            saturated = saturated;
            return 1'b0;
        end 
    endfunction

    function automatic check_status_t check(real received, ref real expected, real epsilon);
        logic saturated_status;
        check_status_t check_status;
        logic eq;

        saturated_status = saturate(expected);
        eq = ((received - expected)**2 <= epsilon**2); 

        if (SATURATION) begin
            if (eq) begin
                check_status = PASS; 
            end
            else begin
                check_status = FAIL;
            end
        end
        else begin
            if (saturated_status) begin
                check_status = SKIP;
            end
            else if (eq) begin
                check_status = PASS;
            end
            else begin
                check_status = FAIL;
            end
        end

        return check_status;
    endfunction

    radix2_core #(
        .WIDTH(WIDTH),
        .INTEGER_WIDTH(INTEGER_WIDTH),
        .ROUND(ROUND)
    ) dut (
        .old_left(old_left),        
        .old_right(old_right),
        .tw_factor_0(tw_factor_0),
        .tw_factor_1(tw_factor_1),
        .new_left(new_left),
        .new_right(new_right)
    );

    initial begin
        clk = 1'b0;
        forever begin
            clk = ~clk;
            #(CLK_PERIOD / 2);
        end   
    end

    initial begin
        arst_n = 0;
        #(CLK_PERIOD + CLK_PERIOD/2);
        arst_n = 1;
    end

    // Random test
    complex_t new_left_received, new_right_received;
    complex_t new_left_expected, new_right_expected;
    complex_t new_left_expected_rounded, new_right_expected_rounded;

    complex_t tw_factor_0_complex, tw_factor_1_complex;
    complex_t old_left_complex, old_right_complex;

    initial begin
        Packet pkt = new();
        int i;
        real epsilon = 2.0**(-FRAC_WIDTH) * (ROUND ? 0.5 : 1);

        @(posedge arst_n);

        for(i = 0; i < 1000000; i = i + 1) begin
            pkt.randomize();
            old_left = pkt.get_old_left();
            old_right = pkt.get_old_right();
            tw_factor_0 = pkt.get_tw_factor_0();
            tw_factor_1 = pkt.get_tw_factor_1();

            @(posedge clk);

            old_left_complex = vector_to_complex_t(old_left);
            old_right_complex = vector_to_complex_t(old_right);
            tw_factor_0_complex = vector_to_complex_t(tw_factor_0);
            tw_factor_1_complex = vector_to_complex_t(tw_factor_1);

            new_left_received.re = Fixedpoint#(WIDTH)::get_real(new_left[SAMPLE_WIDTH-1 -: WIDTH]);
            new_left_received.im = Fixedpoint#(WIDTH)::get_real(new_left[WIDTH-1:0]);
            new_right_received.re = Fixedpoint#(WIDTH)::get_real(new_right[SAMPLE_WIDTH-1 -: WIDTH]);
            new_right_received.im = Fixedpoint#(WIDTH)::get_real(new_right[WIDTH-1:0]);
            
            // $display("DEBUG: old_left.re=%f, tw_factor_0.re=%f", old_left_complex.re, tw_factor_0_complex.re);
            complex_mac(old_left_complex, tw_factor_0_complex, old_right_complex, new_left_expected);
            complex_mac(old_left_complex, tw_factor_1_complex, old_right_complex, new_right_expected);
            scale(new_left_expected);
            scale(new_right_expected);

            if (check(new_left_received.re, new_left_expected.re, epsilon) == FAIL) begin
                $display("[%t] FAIL! Expected new_left.re == %f, but get %f.", $time, new_left_expected.re, new_left_received.re);
            end
            if (check(new_left_received.im, new_left_expected.im, epsilon) == FAIL) begin
                $display("[%t] FAIL! Expected new_left.im == %f, but get %f.", $time, new_left_expected.im, new_left_received.im);
            end

            if (check(new_right_received.re, new_right_expected.re, epsilon) == FAIL) begin
                $display("[%t] FAIL! Expected new_right.re == %f, but get %f.", $time, new_right_expected.re, new_right_received.re);
            end
            if (check(new_right_received.im, new_right_expected.im, epsilon) == FAIL) begin
                $display("[%t] FAIL! Expected new_right.im == %f, but get %f.", $time, new_right_expected.im, new_right_received.im);
            end
        end  
    end
endmodule
