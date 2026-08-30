module twiddle_factors_rom_tb;
    import params_package::*;
    import fixedpoint_functions::*;
    import complex_t_package::*;

    import "DPI-C" function void get_tw(int num, int nfft, output complex_t out);

    logic clk;
    logic arst_n;
    logic [$clog2(N)-1:0] addr;
    logic [SAMPLE_WIDTH-1:0] data_out;

    twiddle_factors_rom #(
        .N(N),
        .WIDTH(WIDTH),
        .INIT_FILE(INIT_FILE)
    ) dut (
        .clk(clk),
        .arst_n(arst_n),
        .addr(addr),
        .data_out(data_out)
    );

    initial begin
        clk = 1'b0;
        forever begin
            clk = ~clk;
            #(CLK_PERIOD / 2);
        end   
    end

    initial begin
        arst_n = 1'b0;
        #(CLK_PERIOD + CLK_PERIOD/2);
        arst_n = 1'b1;
    end

    real rom_re, rom_im;
    complex_t complex;
    initial begin
        @(posedge arst_n);
        @(posedge clk);
        $display("addr, real (expected), real (rom), image (expected), image (rom)");
        for(int i = 0; i < N; i = i + 1) begin
            addr = i;

            @(posedge clk);

            rom_re = Fixedpoint#(WIDTH)::get_real(data_out[SAMPLE_WIDTH-1:WIDTH]);
            rom_im = Fixedpoint#(WIDTH)::get_real(data_out[WIDTH-1:0]);
            get_tw(i, int'(N), complex);
            $display("%d %f %f %f %f", addr, complex.re, rom_re, complex.im, rom_im);
            // TODO: Check epsilon
            if ((complex.re - rom_re)**2 > (2**(-1 * (FRAC_WIDTH/2 + FRAC_WIDTH%2) * 0.5))**2 ) begin
                $display("FAIL in addr %d, expected real = %f, but get = %f", addr, complex.re, rom_re);
            end
            if ((complex.im - rom_im)**2 > (2**(-1 * (FRAC_WIDTH/2 + FRAC_WIDTH%2) * 0.5))**2 ) begin
                $display("FAIL in addr %d, expected image = %f, but get = %f", addr, complex.im, rom_im);
            end
        end
    end

endmodule
