module complex_multiplier_tb;
    import params_package::*;
    import complex_t_package::*;
    import fixedpoint_functions::*;

    import "DPI-C" function void complex_mul(complex_t a, complex_t b, output complex_t out);
    
    logic clk;
    logic arst_n;
    logic [SAMPLE_WIDTH-1:0] z0;
    logic [SAMPLE_WIDTH-1:0] z1;
    logic [2*WIDTH-1:0] re_received;
    logic [2*WIDTH-1:0] im_received;

    class Packet;
        rand bit [SAMPLE_WIDTH-1:0] z0;
        rand bit [SAMPLE_WIDTH-1:0] z1;
    endclass

    complex_multiplier #(
        .WIDTH(WIDTH),
        .INTEGER_WIDTH(INTEGER_WIDTH)
    ) dut (
        .z0(z0),
        .z1(z1),
        .re(re_received),
        .im(im_received)
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
    complex_t received, expected;
    complex_t z0_complex, z1_complex;

    initial begin
        Packet pkt = new();
        int i;

        @(posedge arst_n);

        for(i = 0; i < 10000; i = i + 1) begin
            pkt.randomize();
            z0 = pkt.z0;
            z1 = pkt.z1;
            @(posedge clk);
            
            received.re = wide_fixedpoint_to_float(re_received);
            received.im = wide_fixedpoint_to_float(im_received);

            z0_complex = vector_to_complex_t(z0);
            z1_complex = vector_to_complex_t(z1);

            $display("DEBUG: z0.re=%f, z0.im=%f, z1.re=%f, z1.im=%f", z0_complex.re, z0_complex.im, z1_complex.re, z1_complex.im);
            complex_mul(z0_complex, z1_complex, expected);

            if (received.re != expected.re) begin
                $display("[%t] FAIL! Expected real == %f, but get %f.", $time, expected.re, received.re);
            end
            if (received.im != expected.im) begin
                $display("[%t] FAIL! Expected image == %f, but get %f.", $time, expected.im, received.im);
            end
        end  
    end
endmodule