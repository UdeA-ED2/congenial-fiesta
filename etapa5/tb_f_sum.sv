
`timescale 1ns/1ps

module tb_f_sum;

    logic [31:0] a;
    logic [31:0] b;
    logic [31:0] result;

    int passed = 0;
    int failed = 0;

    // Modulo que estamos probando
    f_sum dut (
        .a(a),
        .b(b),
        .result(result)
    );

    // Tarea para ejecutar cada prueba automaticamente
    task automatic probar(
        input string nombre,
        input logic [31:0] valor_a,
        input logic [31:0] valor_b,
        input logic [31:0] esperado
    );
        begin
            a = valor_a;
            b = valor_b;

            #10; // Esperar 10 ns para que se estabilice el resultado

            if (result == esperado) begin
                $display("PASS | %s | A=%h B=%h Resultado=%h",
                         nombre, a, b, result);
                passed = passed + 1;
            end
            else begin
                $display("FAIL | %s | A=%h B=%h Obtenido=%h Esperado=%h",
                         nombre, a, b, result, esperado);
                failed = failed + 1;
            end
        end
    endtask

    initial begin
        $display("==========================================");
        $display("       PRUEBAS DEL MODULO f_sum");
        $display("==========================================");

        // 10 pruebas con numeros normales
        probar("1.  1.0 + 1.0",       32'h3F800000, 32'h3F800000, 32'h40000000);
        probar("2.  1.5 + 2.25",     32'h3FC00000, 32'h40100000, 32'h40700000);
        probar("3.  5.0 + (-3.0)",    32'h40A00000, 32'hC0400000, 32'h40000000);
        probar("4.  3.0 + (-5.0)",    32'h40400000, 32'hC0A00000, 32'hC0000000);
        probar("5.  2.5 + 2.5",      32'h40200000, 32'h40200000, 32'h40A00000);
        probar("6. -1.0 + (-2.0)",   32'hBF800000, 32'hC0000000, 32'hC0400000);
        probar("7.  4.0 + 1.5",      32'h40800000, 32'h3FC00000, 32'h40B00000);
        probar("8.  6.0 + 2.0",      32'h40C00000, 32'h40000000, 32'h41000000);
        probar("9. 10.0 + (-4.0)",   32'h41200000, 32'hC0800000, 32'h40C00000);
        probar("10. 0.5 + 0.25",     32'h3F000000, 32'h3E800000, 32'h3F400000);

        // Casos especiales: infinitos y NaN
        probar("11. +Inf + 1.0",     32'h7F800000, 32'h3F800000, 32'h7F800000);
        probar("12. -Inf + 1.0",     32'hFF800000, 32'h3F800000, 32'hFF800000);
        probar("13. +Inf + -Inf",   32'h7F800000, 32'hFF800000, 32'h7FC00000);
        probar("14. NaN + 1.0",      32'h7FC00000, 32'h3F800000, 32'h7FC00000);
        probar("15. +Inf + +Inf",   32'h7F800000, 32'h7F800000, 32'h7F800000);

/*
    probar("1.0 + 2.0 = 2.0", 32'h3F800000, 32'h40000000, 32'h40000000);
    probar("3.0 + 2.0 = 6.0", 32'h40400000, 32'h40000000, 32'h40c00000);
    probar("1.5 + 2.5 = 3.75", 32'h3FC00000, 32'h40200000, 32'h40700000);
    probar("0.5 + 0.5 = 0.25", 32'h3F000000, 32'h3F000000, 32'h3E800000);
    probar("54,432.84 + 1,000,000.5 = 52,432,866,216.42", 32'h474cd0d7, 32'h49742408, 32'h514353e1);

    probar("-1.0 + 2.0 = -2.0", 32'hBF800000, 32'h40000000, 32'hC0000000);
    probar("-1.0 + -2.0 = 2.0", 32'hBF800000, 32'hC0000000, 32'h40000000);

    probar("0 + 1.0 = 0", 32'h00000000, 32'h3F800000, 32'h00000000);
    probar("-0 + 1.0 = -0", 32'h80000000, 32'h3F800000, 32'h80000000);
    probar("0 + -0 = -0", 32'h00000000, 32'h80000000, 32'h80000000);

    probar("subnormal + 1.0 (FTZ)", 32'h00000001, 32'h3F800000, 32'h00000000);
    probar("-subnormal + 1.0 (FTZ)", 32'h807FFFFF, 32'h3F800000, 32'h80000000);

    probar("Inf + 2.0 = Inf", 32'h7F800000, 32'h40000000, 32'h7F800000);
    probar("-Inf + 2.0 = -Inf", 32'hFF800000, 32'h40000000, 32'hFF800000);
    probar("Inf + 0 = NaN", 32'h7F800000, 32'h00000000, 32'h7FC00000);
    probar("NaN + 1.0 = NaN", 32'h7FC00000, 32'h3F800000, 32'h7FC00000);

    probar("max + 2.0 = Inf (overflow)", 32'h7F7FFFFF, 32'h40000000, 32'h7F800000);

    probar("min_normal^2 = 0 (underflow)", 32'h00800000, 32'h00800000, 32'h00000000);
    probar("-min_normal^2 = -0 (underflow)", 32'h80800000, 32'h00800000, 32'h80000000);
    */

        $display("==========================================");
        $display("Pruebas aprobadas: %0d", passed);
        $display("Pruebas fallidas:  %0d", failed);
        $display("==========================================");

        $finish;
    end

endmodule
