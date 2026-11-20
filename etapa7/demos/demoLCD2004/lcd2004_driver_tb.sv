`timescale 1ns / 1ps

module lcd2004_driver_tb;

    // Reloj de 2 MHz (periodo = 500 ns) para simular rápido con divisiones exactas
    localparam int CLK_FREQ_HZ = 2_000_000;
    localparam real CLK_PERIOD = 500.0;

    // Tiempos mínimos esperados en ciclos de reloj
    localparam int MIN_CYCLES_50US  = (CLK_FREQ_HZ / 1_000_000) * 50;   // 100 ciclos
    localparam int MIN_CYCLES_200US = (CLK_FREQ_HZ / 1_000_000) * 200;  // 400 ciclos
    localparam int MIN_CYCLES_2MS   = (CLK_FREQ_HZ / 1000) * 2;         // 4000 ciclos
    localparam int MIN_CYCLES_5MS   = (CLK_FREQ_HZ / 1000) * 5;         // 10000 ciclos

    // Señales hacia el DUT (Device Under Test)
    logic         clk   = 1'b0;
    logic         rst_n = 1'b0;
    logic [159:0] line1;
    logic [159:0] line2;
    logic [159:0] line3;
    logic [159:0] line4;
    logic         busy;
    logic         Rs;
    logic         En;
    logic [7:0]   data;

    // Contadores de verificación
    int errors = 0;
    int checks_passed = 0;
    longint cycle_count = 0;
    longint last_en_fall_cycle = 0;
    int required_gap_cycles = 0;

    // Instancia del módulo a probar
    lcd2004_driver #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ)
    ) dut (
        .clk   (clk),
        .rst_n (rst_n),
        .line1 (line1),
        .line2 (line2),
        .line3 (line3),
        .line4 (line4),
        .busy  (busy),
        .Rs    (Rs),
        .En    (En),
        .data  (data)
    );

    // Generador de reloj y contador global de ciclos
    always #(CLK_PERIOD / 2.0) clk = ~clk;
    always_ff @(posedge clk) cycle_count <= cycle_count + 1;

    // Monitor continuo: verifica que Rs y data no cambien mientras En está en alto
    logic       en_prev = 1'b0;
    logic       rs_snap;
    logic [7:0] data_snap;

    always_ff @(posedge clk) begin
        en_prev <= En;
        if (En && !en_prev) begin
            rs_snap   <= Rs;
            data_snap <= data;
        end else if (En && en_prev) begin
            if (Rs !== rs_snap || data !== data_snap) begin
                $display("[ERROR] Tiempo %0t ns: Rs o data cambiaron mientras En=1", $time);
                errors <= errors + 1;
            end
        end
    end

    // Tarea que espera un pulso En y valida RS, byte enviado y retardo previo
    task automatic expect_lcd_write(
        input logic       exp_rs,
        input logic [7:0] exp_data,
        input int         next_min_delay_cycles,
        input string      desc
    );
        longint gap;
        @(negedge En);
        gap = cycle_count - last_en_fall_cycle;

        if (last_en_fall_cycle != 0 && gap < required_gap_cycles) begin
            $display("[ERROR] (%s) Tiempo insuficiente entre escrituras: %0d ciclos (minimo esperado: %0d)",
                     desc, gap, required_gap_cycles);
            errors++;
        end

        if (Rs !== exp_rs || data !== exp_data) begin
            $display("[ERROR] (%s) Esperado RS=%b DATA=0x%02h ('%c') | Recibido RS=%b DATA=0x%02h ('%c')",
                     desc, exp_rs, exp_data, (exp_rs ? exp_data : 8'h2E),
                     Rs, data, (Rs ? data : 8'h2E));
            errors++;
        end else begin
            checks_passed++;
        end

        last_en_fall_cycle  = cycle_count;
        required_gap_cycles = next_min_delay_cycles;
    endtask

    // Tarea que valida una línea completa (comando de dirección DDRAM + 20 caracteres)
    task automatic expect_lcd_line(
        input logic [7:0]   ddram_cmd,
        input logic [159:0] exp_text,
        input string        line_name
    );
        logic [7:0] expected_char;
        expect_lcd_write(1'b0, ddram_cmd, MIN_CYCLES_50US, {line_name, " - Comando DDRAM"});
        for (int i = 0; i < 20; i++) begin
            expected_char = exp_text[159 - i*8 -: 8];
            expect_lcd_write(1'b1, expected_char, MIN_CYCLES_50US,
                             $sformatf("%s - Caracter %0d", line_name, i));
        end
    endtask

    // Watchdog anti-bloqueo (evita simulación infinita si la FSM se queda pegada)
    initial begin
        #300_000_000; // 300 ms simulados
        $display("\n[ERROR FATAL] TIMEOUT: El modulo no completo las escrituras a tiempo (busy=%b).", busy);
        $finish;
    end

    // Secuencia principal de pruebas
    initial begin
        $dumpfile("tb_lcd2004_driver.vcd");
        $dumpvars(0, tb_lcd2004_driver);

        // Mensajes iniciales (20 caracteres exactos cada uno)
        line1 = "   FPGA LCD 2004    ";
        line2 = " Inicializacion OK! ";
        line3 = "Modulo reutilizable ";
        line4 = "Listo para proyecto ";

        $display("==========================================================");
        $display(" INICIANDO TESTBENCH AUTOMATICO: lcd2004_driver");
        $display("==========================================================");

        // Aplicar Reset
        rst_n = 1'b0;
        repeat (5) @(posedge clk);
        if (busy !== 1'b1 || En !== 1'b0) begin
            $display("[ERROR] Estado incorrecto durante reset (busy=%b, En=%b)", busy, En);
            errors++;
        end
        rst_n = 1'b1;

        // --- PRUEBA 1: Secuencia de inicialización HD44780 ---
        $display("[INFO] Verificando secuencia de inicializacion HD44780...");
        expect_lcd_write(1'b0, 8'h30, MIN_CYCLES_5MS,   "Init 1 (0x30)");
        expect_lcd_write(1'b0, 8'h30, MIN_CYCLES_200US, "Init 2 (0x30)");
        expect_lcd_write(1'b0, 8'h30, MIN_CYCLES_200US, "Init 3 (0x30)");
        expect_lcd_write(1'b0, 8'h38, MIN_CYCLES_50US,  "Function Set (0x38)");
        expect_lcd_write(1'b0, 8'h08, MIN_CYCLES_50US,  "Display OFF (0x08)");
        expect_lcd_write(1'b0, 8'h01, MIN_CYCLES_2MS,   "Clear Display (0x01)");
        expect_lcd_write(1'b0, 8'h06, MIN_CYCLES_50US,  "Entry Mode (0x06)");
        expect_lcd_write(1'b0, 8'h0C, MIN_CYCLES_50US,  "Display ON (0x0C)");

        // --- PRUEBA 2: Escritura inicial de las 4 líneas ---
        $display("[INFO] Verificando escritura inicial de las 4 lineas (80 caracteres)...");
        expect_lcd_line(8'h80, line1, "Linea 1");
        expect_lcd_line(8'hC0, line2, "Linea 2");
        expect_lcd_line(8'h94, line3, "Linea 3");
        expect_lcd_line(8'hD4, line4, "Linea 4");

        // Esperar a que termine el último retardo y baje busy a 0
        wait (busy == 1'b0);
        repeat (10) @(posedge clk);
        if (busy !== 1'b0 || En !== 1'b0) begin
            $display("[ERROR] El modulo no quedo en reposo estable tras escribir.");
            errors++;
        end else begin
            checks_passed++;
        end

        // --- PRUEBA 3: Actualización dinámica de mensajes en tiempo de ejecución ---
        $display("[INFO] Probando actualizacion dinamica con nuevo mensaje...");
        @(posedge clk);
        line1 = "PRUEBA DINAMICA  #2 ";
        line2 = "Actualizando datos..";
        line3 = "Valor sensor: 1234  ";
        line4 = "Estado: OPERATIVO   ";

        @(posedge clk);
        if (busy !== 1'b1) begin
            $display("[ERROR] El modulo no detecto el cambio en las entradas (busy sigue en 0).");
            errors++;
        end else begin
            checks_passed++;
        end

        expect_lcd_line(8'h80, line1, "Refresco Linea 1");
        expect_lcd_line(8'hC0, line2, "Refresco Linea 2");
        expect_lcd_line(8'h94, line3, "Refresco Linea 3");
        expect_lcd_line(8'hD4, line4, "Refresco Linea 4");

        wait (busy == 1'b0);
        repeat (20) @(posedge clk);

        // --- RESUMEN FINAL ---
        $display("==========================================================");
        if (errors == 0) begin
            $display(" [EXITO] TODAS LAS PRUEBAS PASARON (%0d verificaciones OK)", checks_passed);
            $display(" - Inicializacion HD44780 y tiempos verificados");
            $display(" - Direcciones DDRAM (0x80, 0xC0, 0x94, 0xD4) verificadas");
            $display(" - Escritura inicial y refresco dinamico verificados");
        end else begin
            $display(" [ERROR] FALLO LA VERIFICACION: Se encontraron %0d errores.", errors);
        end
        $display("==========================================================");
        $finish;
    end

endmodule