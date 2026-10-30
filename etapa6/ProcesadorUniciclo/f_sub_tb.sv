`timescale 1ns/1ps

// Requiere: f_sum.sv compilado junto con f_sub.sv
module f_sub_tb;
  logic [31:0] a, b;
  logic [31:0] result;

  f_sub dut(.a(a), .b(b), .result(result));

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
    $dumpfile("f_sub_tb.vcd");
    $dumpvars(0, f_sub_tb);

    $display("\n=== f_sub testbench ===\n");
    $display("(requiere f_sum.sv en el mismo proyecto)\n");

    // Basicos
    check(32'h40400000, 32'h40000000, 32'h3F800000, "3.0 - 2.0 = 1.0");
    check(32'h40000000, 32'h40400000, 32'hBF800000, "2.0 - 3.0 = -1.0");
    check(32'h40000000, 32'h40000000, 32'h00000000, "2.0 - 2.0 = 0.0");
    check(32'h3F800000, 32'h40400000, 32'hC0000000, "1.0 - 3.0 = -2.0");
    check(32'h40A00000, 32'h40000000, 32'h40400000, "5.0 - 2.0 = 3.0");
    check(32'h40200000, 32'h3FC00000, 32'h3F800000, "2.5 - 1.5 = 1.0");

    // Signos
    check(32'hC0000000, 32'h40000000, 32'hC0400000, "-2.0 - 2.0 = -4.0");
    check(32'h40000000, 32'hC0000000, 32'h40800000, "2.0 - (-2.0) = 4.0");

    // Ceros
    check(32'h3F800000, 32'h00000000, 32'h3F800000, "1.0 - 0.0 = 1.0");
    check(32'h00000000, 32'h3F800000, 32'hBF800000, "0.0 - 1.0 = -1.0");
    check(32'h00000000, 32'h00000000, 32'h00000000, "0.0 - 0.0 = 0.0");

    if (errors == 0) $display("\n=== ALL TESTS PASSED ===\n");
    else             $display("\n=== %0d TEST(S) FAILED ===\n", errors);

    $finish;
  end
endmodule