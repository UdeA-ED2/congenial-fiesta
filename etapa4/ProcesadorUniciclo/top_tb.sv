`timescale 1ns/1ps

module top_tb();
    localparam int CLK_PERIOD = 10;   // periodo del reloj en ns
    localparam int N_CYCLES   = 500;  // ciclos a dejar correr el CPU
    localparam int RESULTS_START = 32'h0000_0174;
    localparam int RESULTS_WORD = RESULTS_START >> 2;
    localparam int TEST_AMOUNT = 20;

    logic clk = 0;
    logic nreset = 0;
    logic [9:0] switches = 10'b0;
    logic [9:0] leds;

    // Reloj
    always #(CLK_PERIOD/2) clk = ~clk;

    // Instancia del procesador completo.
    top cpu (
        .clk      (clk),
        .nreset   (nreset),
        .switches (switches),
        .leds     (leds)
    );

    // Estímulos principales.
    initial begin
        nreset   = 1'b0;   // reset activo bajo
        switches = 10'b0;  // switches apagados

        // Mantener reset durante 5 ciclos.
        repeat (5) @(posedge clk);

        // Quitar reset.
        nreset = 1'b1;

        // Dejar correr el CPU N_CYCLES ciclos.
        repeat (N_CYCLES) @(posedge clk);

        // Imprimir 
        // $display("PC    = %08h", cpu.rvsingle.PC);
        // for (int i = 0; i <= TEST_AMOUNT; i++) begin
            // $display("mem[%0d] = %08h", i,
            //     cpu.mem.u_mem.MEMORY.m_mem_data_a[i+RESULTS_WORD]);
        // end

        // Terminar simulacion.
        $stop;
    end
endmodule
