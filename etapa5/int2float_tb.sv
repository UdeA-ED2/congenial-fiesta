`timescale 1ns/1ps

module int2float_tb;
    logic [31:0] x, result;
    logic [2:0]  rm = 3'b000;

    int2float dut(.x(x), .rm(rm), .result(result));

    integer errors = 0;

    task automatic check(input [31:0] tx, input [31:0] expected,
                         input string label);
        begin
            x = tx;
            #1;
            if (result !== expected) begin
                $display("[FAIL] %-34s x=%h -> got %h expected %h",
                         label, tx, result, expected);
                errors++;
            end else
                $display("[PASS] %-34s x=%h -> %h", label, tx, result);
        end
    endtask

    initial begin
        $dumpfile("int2float_tb.vcd");
        $dumpvars(0, int2float_tb);

        $display("\n=== int2float testbench ===\n");

        // ------- cero -------
        check(32'h00000000, 32'h00000000, "0 -> 0.0");

        // ------- enteros pequenos exactos -------
        check(32'h00000001, 32'h3F800000, " 1 ->  1.0");
        check(32'hFFFFFFFF, 32'hBF800000, "-1 -> -1.0");
        check(32'h00000002, 32'h40000000, " 2 ->  2.0");
        check(32'hFFFFFFFE, 32'hC0000000, "-2 -> -2.0");
        check(32'h00000003, 32'h40400000, " 3 ->  3.0");
        check(32'h00000064, 32'h42C80000, " 100 ->  100.0");
        check(32'hFFFFFF9C, 32'hC2C80000, "-100 -> -100.0");
        check(32'h00003039, 32'h4640E400, " 12345 ->  12345.0");
        check(32'hFFFFCFC7, 32'hC640E400, "-12345 -> -12345.0");

        // ------- potencias de 2 -------
        // 2^23: p=23 -> m = mag (sin shift), E = 150 = 0x96
        check(32'h00800000, 32'h4B000000, "2^23 -> 8388608.0");
        // 2^24: p=24 -> m = mag>>1 = 0x800000, E = 151 = 0x97
        check(32'h01000000, 32'h4B800000, "2^24 -> 16777216.0");
        // 2^30: p=30 -> m = mag>>7 = 0x800000, E = 157 = 0x9D
        check(32'h40000000, 32'h4E800000, "2^30 -> 1073741824.0");
        check(32'hC0000000, 32'hCE800000, "-2^30 -> -1073741824.0");

        // ------- INT_MIN (exacto) -------
        // mag = 0x80000000, p=31, E = 158 = 0x9E, m = mag>>8 = 0x800000
        check(32'h80000000, 32'hCF000000, "INT_MIN -> -2^31 (exacto)");

        // ------- INT_MAX (truncado) -------
        // mag = 0x7FFFFFFF, p=30, E=157, m = mag>>7 = 0xFFFFFF -> f=0x7FFFFF
        // resultado = 0x4EFFFFFF = 2147483520 (NO redondea a 2^31)
        check(32'h7FFFFFFF, 32'h4EFFFFFF, "INT_MAX -> 2147483520 (trunc)");

        // ------- negativo cuyo positivo tambien trunca -------
        check(32'h80000001, 32'hCF000000, "INT_MIN+1 -> -2^31 (trunc)");
        // mag = 0x7FFFFFFF, p=30, E=157, m=0xFFFFFF -> 0xCEFFFFFF (signo 1)
        check(32'h80000002, 32'hCEFFFFFF, "INT_MIN+2 -> -2147483520 (trunc)");

        if (errors == 0) $display("\n=== ALL TESTS PASSED ===\n");
        else             $display("\n=== %0d TEST(S) FAILED ===\n", errors);
        $finish;
    end
endmodule
