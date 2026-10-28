`timescale 1ns/1ps

module f_div_tb;
  logic [31:0] a, b;
  logic [31:0] result;

  f_div dut(.a(a), .b(b), .result(result));

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
    $dumpfile("f_div_tb.vcd");
    $dumpvars(0, f_div_tb);

    $display("\n=== f_div testbench ===\n");

    // Normales
    check(32'h40800000, 32'h40000000, 32'h40000000, "4.0 / 2.0 = 2.0");
    check(32'h3F800000, 32'h40000000, 32'h3F000000, "1.0 / 2.0 = 0.5");
    check(32'h40000000, 32'h3F000000, 32'h40800000, "2.0 / 0.5 = 4.0");
    check(32'h3F800000, 32'h3F800000, 32'h3F800000, "1.0 / 1.0 = 1.0");

    // Signos
    check(32'hBF800000, 32'h40000000, 32'hBF000000, "-1.0 / 2.0 = -0.5");
    check(32'hBF800000, 32'hC0000000, 32'h3F000000, "-1.0 / -2.0 = 0.5");

    // Precisión (truncado)
    check(32'h3F800000, 32'h40400000, 32'h3EAAAAAA, "1.0 / 3.0 (truncado)");

    // Ceros
    check(32'h00000000, 32'h3F800000, 32'h00000000, "0 / 1.0 = 0");
    check(32'h80000000, 32'h3F800000, 32'h80000000, "-0 / 1.0 = -0");

    // Subnormales -> 0 (FTZ)
    check(32'h00000001, 32'h3F800000, 32'h00000000, "subnormal / 1.0 (FTZ)");
    check(32'h3F800000, 32'h00000001, 32'h7F800000, "1.0 / subnormal -> Inf (FTZ)");

    // Inf / NaN
    check(32'h7F800000, 32'h40000000, 32'h7F800000, "Inf / 2.0 = Inf");
    check(32'hFF800000, 32'h40000000, 32'hFF800000, "-Inf / 2.0 = -Inf");
    check(32'h7F800000, 32'h7F800000, 32'h7FC00000, "Inf / Inf = NaN");
    check(32'h00000000, 32'h00000000, 32'h7FC00000, "0 / 0 = NaN");
    check(32'h7FC00000, 32'h3F800000, 32'h7FC00000, "NaN / 1.0 = NaN");

    // División por cero
    check(32'h3F800000, 32'h00000000, 32'h7F800000, "1.0 / 0 = Inf");
    check(32'hBF800000, 32'h00000000, 32'hFF800000, "-1.0 / 0 = -Inf");
    check(32'h3F800000, 32'h80000000, 32'hFF800000, "1.0 / -0 = -Inf");

    // Finito / Inf
    check(32'h3F800000, 32'h7F800000, 32'h00000000, "1.0 / Inf = 0");
    check(32'h3F800000, 32'hFF800000, 32'h80000000, "1.0 / -Inf = -0");

    // Overflow
    check(32'h7F7FFFFF, 32'h3F000000, 32'h7F800000, "max / 0.5 = Inf (overflow)");

    // Underflow -> 0 (FTZ)
    check(32'h00800000, 32'h40000000, 32'h00000000, "min_normal / 2 = 0 (underflow)");

    if (errors == 0) $display("\n=== ALL TESTS PASSED ===\n");
    else             $display("\n=== %0d TEST(S) FAILED ===\n", errors);

    $finish;
  end
endmodule
