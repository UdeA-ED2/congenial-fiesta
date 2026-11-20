
// =============================================================================
// Testbench para Driver_Teclado (teclado 4x4)
// Simula presionar una tecla y observa la salida TECLA y FLAG
// =============================================================================

`timescale 1ns/1ps

module tb_Driver_Teclado;

    // Parámetros
    parameter int TOPVALUE = 50_000;

    // Señales internas
    logic clk;
    logic [3:0] columnas;
    logic [3:0] filas;
    logic [3:0] tecla;
    logic flag;

    // Instancia del módulo
    Driver_Teclado #(
        .TOPVALUE(TOPVALUE)
    ) dut (
        .clk(clk),
        .COLUMNAS(columnas),
        .FILAS(filas),
        .TECLA(tecla),
        .FLAG(flag)
    );

    // Generador de reloj
    initial clk = 0;
    always #10 clk = ~clk; // 50 MHz

    // Simulación
    initial begin
        $display("Inicio de simulación");
        columnas = 4'b1111; // ninguna tecla presionada

        // Esperar algunos ciclos
        #100_000;

        // Simular presión de la tecla correspondiente a fila 2 (fila_sel = 2) y columna 1 (index = 9)
            forever begin
                wait (filas == 4'b1111 & ~(4'b0001 << 2)); // fila activada (inverso de shift)
                columnas[1] = 0; // Presionar columna 1
                #2000;
                columnas[1] = 1; // Soltar tecla
            end

        // Esperar suficiente tiempo para que se detecte la tecla
        #500_000;

        $display("FIN. TECLA DETECTADA = %h, FLAG = %b", tecla, flag);
        $finish;
    end

endmodule
