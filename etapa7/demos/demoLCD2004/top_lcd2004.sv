module top_lcd2004 (
    input  logic        MAX10_CLK1_50,
    output logic [35:0] GPIO
);
    logic       lcd_rs;
    logic       lcd_e;
    logic [7:0] lcd_data;

    // Mapeo de pines GPIO de tu placa
    assign GPIO[1]  = lcd_rs;
    assign GPIO[3]  = lcd_e;
    assign GPIO[5]  = lcd_data[0];
    assign GPIO[7]  = lcd_data[1];
    assign GPIO[8]  = lcd_data[2];
    assign GPIO[9]  = lcd_data[3];
    assign GPIO[10] = lcd_data[4];
    assign GPIO[12] = lcd_data[5];
    assign GPIO[14] = lcd_data[6];
    assign GPIO[16] = lcd_data[7];

    // Instancia portátil: en tu proyecto futuro solo cambias estas 4 señales por registros
    lcd2004_driver #(
        .CLK_FREQ_HZ(50_000_000)
    ) u_lcd (
        .clk   (MAX10_CLK1_50),
        .rst_n (1'b1),
        .line1 ("   FPGA LCD 2004    "), // 20 caracteres exactos
        .line2 (" Inicializacion OK! "), // 20 caracteres exactos
        .line3 ("Modulo reutilizable "), // 20 caracteres exactos
        .line4 ("Listo para proyecto "), // 20 caracteres exactos
        .busy  (),
        .Rs    (lcd_rs),
        .En    (lcd_e),
        .data  (lcd_data)
    );
endmodule
