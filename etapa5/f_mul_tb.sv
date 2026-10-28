`timescale 1ns/1ps

module f_mul_tb;
  logic [31:0] a, b;
  logic [31:0] result;

  f_mul dut(.a(a), .b(b), .result(result));

  integer errors = 0;

  task automatic check(input [31:0] ta, input [31:0] tb,
                       input [31:0] expected, input string label);
    begin
      a = ta; b = tb;
      #1;
      if (result !== expected) begin
        $display("[FAIL] %-28s a=%h b=%h -> got %h expected %h",
                 label, ta, tb, result, expected);
        errors++;
      end else
        $display("[PASS] %-28s a=%h b=%h -> %h", label, ta, tb, result);
    end
  endtask

  initial begin
    $dumpfile("f_mul_tb.vcd");
    $dumpvars(0, f_mul_tb);

    $display("\n=== f_mul testbench ===\n");

    // Normales
    check(32'h3F800000, 32'h40000000, 32'h40000000, "1.0 * 2.0 = 2.0");
    check(32'h40400000, 32'h40000000, 32'h40c00000, "3.0 * 2.0 = 6.0");
    check(32'h3FC00000, 32'h40200000, 32'h40700000, "1.5 * 2.5 = 3.75");
    check(32'h3F000000, 32'h3F000000, 32'h3E800000, "0.5 * 0.5 = 0.25");
    check(32'h474cd0d7, 32'h49742408, 32'h514353e1, "54,432.84 * 1,000,000.5 = 52,432,866,216.42");

    // Signos
    check(32'hBF800000, 32'h40000000, 32'hC0000000, "-1.0 * 2.0 = -2.0");
    check(32'hBF800000, 32'hC0000000, 32'h40000000, "-1.0 * -2.0 = 2.0");

    // Ceros
    check(32'h00000000, 32'h3F800000, 32'h00000000, "0 * 1.0 = 0");
    check(32'h80000000, 32'h3F800000, 32'h80000000, "-0 * 1.0 = -0");
    check(32'h00000000, 32'h80000000, 32'h80000000, "0 * -0 = -0");

    // Subnormales -> 0 (FTZ/DAZ)
    check(32'h00000001, 32'h3F800000, 32'h00000000, "subnormal * 1.0 (FTZ)");
    check(32'h807FFFFF, 32'h3F800000, 32'h80000000, "-subnormal * 1.0 (FTZ)");

    // Inf / NaN
    check(32'h7F800000, 32'h40000000, 32'h7F800000, "Inf * 2.0 = Inf");
    check(32'hFF800000, 32'h40000000, 32'hFF800000, "-Inf * 2.0 = -Inf");
    check(32'h7F800000, 32'h00000000, 32'h7FC00000, "Inf * 0 = NaN");
    check(32'h7FC00000, 32'h3F800000, 32'h7FC00000, "NaN * 1.0 = NaN");

    // Overflow
    check(32'h7F7FFFFF, 32'h40000000, 32'h7F800000, "max * 2.0 = Inf (overflow)");

    // Underflow -> 0 (FTZ)
    check(32'h00800000, 32'h00800000, 32'h00000000, "min_normal^2 = 0 (underflow)");
    check(32'h80800000, 32'h00800000, 32'h80000000, "-min_normal^2 = -0 (underflow)");

    if (errors == 0) $display("\n=== ALL TESTS PASSED ===\n");
    else             $display("\n=== %0d TEST(S) FAILED ===\n", errors);

    $finish;
  end
endmodule
