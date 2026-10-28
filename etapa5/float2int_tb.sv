`timescale 1ns/1ps

module float2int_tb;
    logic [31:0] f, result;

    float2int dut(.f(f), .result(result));

    integer errors = 0;

    task automatic check(input [31:0] tf, input [31:0] expected,
                         input string label);
        begin
            f = tf;
            #1;
            if (result !== expected) begin
                $display("[FAIL] %-34s f=%h -> got %h expected %h",
                         label, tf, result, expected);
                errors++;
            end else
                $display("[PASS] %-34s f=%h -> %h", label, tf, result);
        end
    endtask

    initial begin
        $dumpfile("float2int_tb.vcd");
        $dumpvars(0, float2int_tb);

        $display("\n=== float2int testbench ===\n");

        // ------- cero / signo de cero -------
        check(32'h00000000, 32'h00000000, "0.0 -> 0");
        check(32'h80000000, 32'h00000000, "-0.0 -> 0 (E=0)");

        // ------- enteros exactos -------
        check(32'h3F800000, 32'h00000001, " 1.0 ->  1");
        check(32'hBF800000, 32'hFFFFFFFF, "-1.0 -> -1");
        check(32'h40000000, 32'h00000002, " 2.0 ->  2");
        check(32'hC0000000, 32'hFFFFFFFE, "-2.0 -> -2");
        check(32'h40400000, 32'h00000003, " 3.0 ->  3");
        check(32'h42C80000, 32'h00000064, " 100.0 ->  100");
        check(32'hC2C80000, 32'hFFFFFF9C, "-100.0 -> -100");
        check(32'h4640E400, 32'h00003039, " 12345.0 ->  12345");
        check(32'hC640E400, 32'hFFFFCFC7, "-12345.0 -> -12345");

        // ------- truncamiento hacia cero -------
        check(32'h3FC00000, 32'h00000001, " 1.5 -> 1 (trunc)");
        check(32'hBFC00000, 32'hFFFFFFFF, "-1.5 -> -1 (trunc hacia 0)");
        check(32'h40200000, 32'h00000002, " 2.5 -> 2 (trunc)");
        check(32'hC0200000, 32'hFFFFFFFE, "-2.5 -> -2 (trunc hacia 0)");
        check(32'h3FFFC000, 32'h00000001, "~1.999 -> 1");
        check(32'h3F7FBE77, 32'h00000000, "~0.999 -> 0");
        check(32'h3F800001, 32'h00000001, " 1+1ulp -> 1");

        // ------- |x| < 1  ->  0 -------
        check(32'h3F000000, 32'h00000000, " 0.5 -> 0");
        check(32'hBF000000, 32'h00000000, "-0.5 -> 0");
        check(32'h00000001, 32'h00000000, "min subnormal -> 0");
        check(32'h007FFFFF, 32'h00000000, "max subnormal -> 0");

        // ------- potencias de 2 -------
        // 2^23 -> exp_real=23, shift=0, m=0x800000 -> 0x800000
        check(32'h4B000000, 32'h00800000, "2^23 -> 8388608");
        check(32'h4B800000, 32'h01000000, "2^24 -> 16777216");
        // 2^30 -> exp_real=30, shift=-7, m<<7 = 0x40000000
        check(32'h4E800000, 32'h40000000, "2^30 -> 1073741824");
        check(32'hCE800000, 32'hC0000000, "-2^30 -> -1073741824");

        // ------- borde de saturación -------
        // E=157 (exp_real=30) aún no satura: 0xFFFFFF<<7 = 0x7FFFFF80 = 2147483520
        check(32'h4EFFFFFF, 32'h7FFFFF80, "max float pre-sat -> 2147483520");
        check(32'hCEFFFFFF, 32'h80000080, "min float pre-sat -> -2147483520");
        // E=158 ya satura
        check(32'h4F000000, 32'h7FFFFFFF, "2^31 -> INT_MAX (sat)");
        check(32'hCF000000, 32'h80000000, "-2^31 -> INT_MIN (sat)");
        check(32'h7F800000, 32'h7FFFFFFF, "+Inf -> INT_MAX (sat)");
        check(32'hFF800000, 32'h80000000, "-Inf -> INT_MIN (sat)");
        check(32'h7FC00000, 32'h7FFFFFFF, "NaN  -> INT_MAX (sat)");
        check(32'hFFC00000, 32'h80000000, "-NaN -> INT_MIN (sat)");

        if (errors == 0) $display("\n=== ALL TESTS PASSED ===\n");
        else             $display("\n=== %0d TEST(S) FAILED ===\n", errors);
        $finish;
    end
endmodule
