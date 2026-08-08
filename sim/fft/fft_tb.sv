module fft_tb;
    import complex_t_package::*;
    import params_package::*;
    import fixedpoint_functions::*;

    typedef complex_t complex_array_t[N];

    import "DPI-C" function void get_complex_t_fft(complex_array_t in, int n, int scale, output complex_array_t out);

    logic clk;
    logic arst_n;

    // AXIS SLAVE
    logic [SAMPLE_WIDTH-1:0] s_tdata;
    logic s_tvalid;
    logic s_tready;

    // AXIS MASTER
    logic [SAMPLE_WIDTH-1:0] m_tdata;
    logic m_tvalid;
    logic m_tready;

    fft #(
        .N(N),
        .WIDTH(WIDTH),
        .INTEGER_WIDTH(INTEGER_WIDTH),
        .ROUND(ROUND)
    ) dut (
        .clk(clk),
        .arst_n(arst_n),

        .s_tdata(s_tdata),
        .s_tvalid(s_tvalid),
        .s_tready(s_tready),

        .m_tdata(m_tdata),
        .m_tvalid(m_tvalid),
        .m_tready(m_tready)
    );

    initial begin
        clk = 1'b0;
        forever begin
            #(CLK_PERIOD / 2);
            clk = !clk;
        end
    end

    initial begin
        arst_n = 1'b0;
        #(CLK_PERIOD + CLK_PERIOD/2);
        arst_n = 1'b1;
    end

    class AxisMaster;
        complex_array_t complex_array_in;
        rand bit [SAMPLE_WIDTH-1:0] point;
        bit [$clog2(N)-1:0] addr;

        function automatic bit [SAMPLE_WIDTH-1:0] get_point();
            return point;
        endfunction

        function automatic bit get_tvalid();
            return 1'b1;
        endfunction

        // TODO: Use function instead task, transfer the logic of wait
        task automatic set_point(ref logic [SAMPLE_WIDTH-1:0] point, ref logic tvalid, ref logic tready);
            wait (tvalid && tready);
            complex_array_in[addr] = vector_to_complex_t(point);
            addr = addr + 1'b1;
        endtask

        function automatic complex_array_t get_array();
            return complex_array_in;
        endfunction

    endclass

    class AxisSlave;
        complex_array_t complex_array_out;
        bit [SAMPLE_WIDTH-1:0] points [0:N-1];
        bit [$clog2(N)-1:0] addr;

        function automatic set_point(logic [SAMPLE_WIDTH-1:0] point);
            points[addr] = point;
            complex_array_out[addr] = vector_to_complex_t(point);
            addr = addr + 1'b1;
        endfunction

        function automatic logic get_tready();
            return 1'b1;
        endfunction

        function automatic complex_array_t get_array();
            return complex_array_out;
        endfunction

    endclass

    task automatic radix_monitor_addr();
        logic [$clog2(N)-1:0] expected_old_left_addr;
        logic [$clog2(N)-1:0] expected_old_right_addr;
        logic [$clog2(N)-1:0] expected_tw_factor_addr;
        
        for(int r = 1; r < N; r = r * 2) begin
            for(int subarray = 0; subarray < N / (2 * r); subarray = subarray + 1) begin
                for(int offset = 0; offset < r; offset = offset + 1) begin
                    wait (dut.radix2_inst.stage1_common.valid);
                    
                    if (dut.radix2_inst.stage1_common.r != $clog2(r)) begin
                        $display("[%t] FAIL! Expected stage1_common.r == %d, but get %d.", $time, $clog2(r), dut.radix2_inst.stage1_common.r);
                    end

                    if (dut.radix2_inst.stage1_common.subarray != subarray) begin
                        $display("[%t] FAIL! Expected stage1_common.subarray == %d, but get %d.", $time, subarray, dut.radix2_inst.stage1_common.subarray);
                    end

                    if (dut.radix2_inst.stage1_common.offset != offset) begin
                        $display("[%t] FAIL! Expected stage1_common.offset == %d, but get %d.", $time, offset, dut.radix2_inst.stage1_common.offset);
                    end

                    expected_old_left_addr = subarray * (r * 2) + offset;
                    expected_old_right_addr = subarray * (r * 2) + offset + r;
                    expected_tw_factor_addr = offset * (N / (2*r));

                    if (expected_old_left_addr != dut.radix2_inst.stage1.ram0_rd_addr_0) begin
                        $display("[%t] FAIL! Expected old_left_addr == %d, but get %d.", $time, expected_old_left_addr, dut.radix2_inst.stage1.ram0_rd_addr_0);
                    end

                    if (expected_old_right_addr != dut.radix2_inst.stage1.ram0_rd_addr_1) begin
                        $display("[%t] FAIL! Expected old_right_addr == %d, but get %d.", $time, expected_old_right_addr, dut.radix2_inst.stage1.ram0_rd_addr_1);
                    end

                    if (expected_tw_factor_addr != dut.radix2_inst.stage1.tw_factor_addr_0) begin
                        $display("[%t] FAIL! Expected tw_factor_addr == %d, but get %d.", $time, expected_tw_factor_addr, dut.radix2_inst.stage1.tw_factor_addr_0);
                    end
                    
                    @(posedge clk);
                    #1;
                end
            end
        end
    endtask

    task automatic random_ram_init(AxisMaster am);
        for(int i = 0; i < N; i = i + 1) begin
            am.randomize();
            s_tdata = am.get_point();
            s_tvalid = am.get_tvalid();
            am.set_point(s_tdata, s_tvalid, s_tready);
            @(posedge clk);
        end
        s_tvalid = 1'b0;
    endtask

    task automatic ram_export(AxisSlave as);
        for(int i = 0; i < N; i = i + 1) begin
            m_tready = as.get_tready();
            wait (m_tvalid && m_tready);
            @(negedge clk);

            as.set_point(m_tdata);

            @(posedge clk);
        end
    endtask

    initial begin
        AxisMaster am = new();
        AxisSlave as = new();
        
        complex_array_t in, out;
        complex_array_t model_out;

        @(posedge arst_n);

        // FFT IN
        random_ram_init(am);

        // Check idxs
        radix_monitor_addr();
        
        // FFT OUT
        ram_export(as);

        in = am.get_array();
        out = as.get_array();

        // Check result
        // TODO: Need to check results using DPI-C
        get_complex_t_fft(in, int'(N), int'(RADIX_OUT_SCALE), model_out);
        for(int i = 0; i < N; i = i + 1) begin
            $display("addr: %d", i);
            $display("%f", model_out[i]);
            $display("%f", out[i]);
            $display("%f %f", (out[i].re - model_out[i].re)**2, (out[i].im - model_out[i].im)**2);
            $display("--------");
        end
    end


endmodule