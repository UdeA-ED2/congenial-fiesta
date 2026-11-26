module top(
    input  logic       max_clk, nreset,
    input  logic [9:0] switches,
    output logic [9:0] leds,
    // Pines Teclado 4x4
    input  logic [3:0] COLUMNAS,
    output logic [3:0] FILAS,
    output logic [7:0] DISP,
    // Pines LCD 2004
    output logic       Rs,
    output logic       Rw,
    output logic       En,
    output logic [7:0] data
);

    // Señales internas del procesador y memoria
    logic MemWrite, nSyncReset, syncReset;
    logic [31:0] PCNext, Instr, ReadData;
    logic [31:0] WriteData, DataAdr;
    logic clk;

    // Señales internas de conexión entre perifericos y memoria
    logic [3:0]        key_code;
    logic              kb_flag;
    logic [0:3][159:0] lcd_lines;
    logic              lcd_busy;

    assign syncReset = ~nSyncReset;
    assign Rw        = 1'b0; // Modo solo escritura hacia la LCD

    // Divisor de reloj para el procesador y la memoria
    cntdiv_n #(10) clkdiv (max_clk, ~nreset, clk);

    // Memoria principal + mapeo de E/S
    mem u_mem (
        .clk      (clk),
        .reset    (syncReset),
        .we2      (MemWrite),
        .a1       (PCNext),
        .a2       (DataAdr),
        .wd       (WriteData),
        .rd1      (Instr),
        .rd2      (ReadData),
        .switches (switches),
        .leds     (leds),
        .key      (key_code),
        .kb_flag  (kb_flag),
        .lines    (lcd_lines),
		  .lcd_busy (lcd_busy)
    );

    // Procesador RISC-V monociclo
    riscvsingle rvsingle (
        clk, syncReset, PCNext, Instr, MemWrite, DataAdr, WriteData, ReadData
    );

    // Driver del teclado
    Driver_Teclado #(
        .TOPVALUE(5_000_000)
    ) u_teclado (
        .clk      (clk),
        .nrst     (nreset),
        .COLUMNAS (COLUMNAS),
        .FILAS    (FILAS),
        .TECLA    (key_code),
        .FLAG     (kb_flag),
        .DISP     (DISP)
    );

    // Driver de la LCD 20x4
    lcd2004_driver #(
        .CLK_FREQ_HZ(5_000_000)
    ) u_lcd (
        .clk   (clk),
        .rst_n (nreset),
        .line1 (lcd_lines[0]),
        .line2 (lcd_lines[1]),
        .line3 (lcd_lines[2]),
        .line4 (lcd_lines[3]),
        .busy  (lcd_busy),
        .Rs    (Rs),
        .En    (En),
        .data  (data)
    );

    // Reset sincrono para memoria y procesador
    flopr #(1) resetReg (clk, ~nreset, 1'b1, nSyncReset);

endmodule
