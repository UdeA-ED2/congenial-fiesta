module lcd2004_driver #(
    parameter int CLK_FREQ_HZ = 50_000_000
)(
    input  logic         clk,
    input  logic         rst_n,      // Reset activo en bajo (conectar a 1'b1 si no se usa)
    // Entradas de texto: 20 caracteres ASCII (20 x 8 = 160 bits) por línea
    input  logic [159:0] line1,
    input  logic [159:0] line2,
    input  logic [159:0] line3,
    input  logic [159:0] line4,
    // Estado opcional para tu proyecto futuro
    output logic         busy,
    // Interfaz física hacia la LCD 2004 (pin RW de la LCD debe ir a GND)
    output logic         Rs,
    output logic         En,
    output logic [7:0]   data
);
    // Constantes de temporización escalables según el reloj
    localparam int T_50MS     = (CLK_FREQ_HZ / 1000) * 100;      // 100 ms estabilización inicial
    localparam int T_5MS      = (CLK_FREQ_HZ / 1000) * 5;       // 5 ms tras primer 0x30
    localparam int T_2MS      = (CLK_FREQ_HZ / 1000) * 2;       // 2 ms para Clear Display
    localparam int T_200US    = (CLK_FREQ_HZ / 1_000_000) * 200;// 200 us entre comandos init
    localparam int T_50US     = (CLK_FREQ_HZ / 1_000_000) * 50; // 50 us ejecución normal
    localparam int T_1US      = (CLK_FREQ_HZ / 1_000_000) * 1;  // 1 us setup/hold/pulso En

    typedef enum logic [4:0] {
        S_POWER_ON,
        S_INIT_1,
        S_INIT_2,
        S_INIT_3,
        S_FUNC_SET,
        S_DISP_OFF,
        S_CLEAR,
        S_ENTRY_MODE,
        S_DISP_ON,
        S_SET_LINE1,
        S_WRITE_LINE1,
        S_SET_LINE2,
        S_WRITE_LINE2,
        S_SET_LINE3,
        S_WRITE_LINE3,
        S_SET_LINE4,
        S_WRITE_LINE4,
        S_IDLE,
        S_EN_SETUP,
        S_EN_HIGH,
        S_EN_HOLD,
        S_WAIT_DELAY
    } state_t;

    state_t        state        = S_POWER_ON;
    state_t        next_state   = S_INIT_1;
    logic [23:0]   timer        = '0;
    logic [23:0]   delay_target = '0;
    logic [4:0]    char_idx     = '0;

    // Registros sombra para detectar cambios en cualquiera de las 4 líneas
    logic [159:0]  latched_l1, latched_l2, latched_l3, latched_l4;

    logic          r_rs   = 1'b0;
    logic          r_e    = 1'b0;
    logic [7:0]    r_data = 8'h00;

    assign Rs   = r_rs;
    assign En   = r_e;
    assign data = r_data;
    assign busy = (state != S_IDLE);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= S_POWER_ON;
            next_state   <= S_INIT_1;
            timer        <= '0;
            delay_target <= '0;
            char_idx     <= '0;
            r_rs         <= 1'b0;
            r_e          <= 1'b0;
            r_data       <= 8'h00;
            latched_l1   <= '0;
            latched_l2   <= '0;
            latched_l3   <= '0;
            latched_l4   <= '0;
        end else begin
            case (state)
                // 1. Espera de estabilización tras encender (50 ms)
                S_POWER_ON: begin
                    r_rs <= 1'b0;
                    r_e  <= 1'b0;
                    if (timer >= T_50MS - 1) begin
                        timer <= '0;
                        state <= S_INIT_1;
                    end else begin
                        timer <= timer + 1'b1;
                    end
                end

                // 2. Secuencia oficial de reset por software HD44780 (0x30 tres veces)
                S_INIT_1: begin
                    r_rs <= 1'b0; r_data <= 8'h30; delay_target <= T_5MS;
                    next_state <= S_INIT_2; state <= S_EN_SETUP;
                end
                S_INIT_2: begin
                    r_rs <= 1'b0; r_data <= 8'h30; delay_target <= T_200US;
                    next_state <= S_INIT_3; state <= S_EN_SETUP;
                end
                S_INIT_3: begin
                    r_rs <= 1'b0; r_data <= 8'h30; delay_target <= T_200US;
                    next_state <= S_FUNC_SET; state <= S_EN_SETUP;
                end

                // 3. Configuración de bus de 8 bits, 2+ líneas, fuente 5x8 (0x38)
                S_FUNC_SET: begin
                    r_rs <= 1'b0; r_data <= 8'h38; delay_target <= T_50US;
                    next_state <= S_DISP_OFF; state <= S_EN_SETUP;
                end
                S_DISP_OFF: begin
                    r_rs <= 1'b0; r_data <= 8'h08; delay_target <= T_50US;
                    next_state <= S_CLEAR; state <= S_EN_SETUP;
                end
                S_CLEAR: begin
                    r_rs <= 1'b0; r_data <= 8'h01; delay_target <= T_2MS;
                    next_state <= S_ENTRY_MODE; state <= S_EN_SETUP;
                end
                S_ENTRY_MODE: begin
                    r_rs <= 1'b0; r_data <= 8'h06; delay_target <= T_50US;
                    next_state <= S_DISP_ON; state <= S_EN_SETUP;
                end
                S_DISP_ON: begin
                    r_rs <= 1'b0; r_data <= 8'h0C; delay_target <= T_50US;
                    // Capturamos los mensajes actuales antes de escribirlos
                    latched_l1 <= line1;
                    latched_l2 <= line2;
                    latched_l3 <= line3;
                    latched_l4 <= line4;
                    next_state <= S_SET_LINE1;
                    state      <= S_EN_SETUP;
                end

                // 4. Escritura de las 4 líneas (DDRAM: 0x80, 0xC0, 0x94, 0xD4)
                S_SET_LINE1: begin
                    r_rs <= 1'b0; r_data <= 8'h80; delay_target <= T_50US;
                    char_idx <= '0; next_state <= S_WRITE_LINE1; state <= S_EN_SETUP;
                end
                S_WRITE_LINE1: begin
                    r_rs <= 1'b1;
                    r_data <= latched_l1[159 - char_idx*8 -: 8];
                    delay_target <= T_50US;
                    state <= S_EN_SETUP;
                    if (char_idx == 5'd19) begin
                        char_idx <= '0; next_state <= S_SET_LINE2;
                    end else begin
                        char_idx <= char_idx + 1'b1; next_state <= S_WRITE_LINE1;
                    end
                end

                S_SET_LINE2: begin
                    r_rs <= 1'b0; r_data <= 8'hC0; delay_target <= T_50US;
                    char_idx <= '0; next_state <= S_WRITE_LINE2; state <= S_EN_SETUP;
                end
                S_WRITE_LINE2: begin
                    r_rs <= 1'b1;
                    r_data <= latched_l2[159 - char_idx*8 -: 8];
                    delay_target <= T_50US;
                    state <= S_EN_SETUP;
                    if (char_idx == 5'd19) begin
                        char_idx <= '0; next_state <= S_SET_LINE3;
                    end else begin
                        char_idx <= char_idx + 1'b1; next_state <= S_WRITE_LINE2;
                    end
                end

                S_SET_LINE3: begin
                    r_rs <= 1'b0; r_data <= 8'h94; delay_target <= T_50US;
                    char_idx <= '0; next_state <= S_WRITE_LINE3; state <= S_EN_SETUP;
                end
                S_WRITE_LINE3: begin
                    r_rs <= 1'b1;
                    r_data <= latched_l3[159 - char_idx*8 -: 8];
                    delay_target <= T_50US;
                    state <= S_EN_SETUP;
                    if (char_idx == 5'd19) begin
                        char_idx <= '0; next_state <= S_SET_LINE4;
                    end else begin
                        char_idx <= char_idx + 1'b1; next_state <= S_WRITE_LINE3;
                    end
                end

                S_SET_LINE4: begin
                    r_rs <= 1'b0; r_data <= 8'hD4; delay_target <= T_50US;
                    char_idx <= '0; next_state <= S_WRITE_LINE4; state <= S_EN_SETUP;
                end
                S_WRITE_LINE4: begin
                    r_rs <= 1'b1;
                    r_data <= latched_l4[159 - char_idx*8 -: 8];
                    delay_target <= T_50US;
                    state <= S_EN_SETUP;
                    if (char_idx == 5'd19) begin
                        char_idx <= '0; next_state <= S_IDLE;
                    end else begin
                        char_idx <= char_idx + 1'b1; next_state <= S_WRITE_LINE4;
                    end
                end

                // 5. Reposo: actualiza automáticamente si cambia algún carácter en las entradas
                S_IDLE: begin
                    r_e <= 1'b0;
                    if ({line1, line2, line3, line4} != {latched_l1, latched_l2, latched_l3, latched_l4}) begin
                        latched_l1 <= line1;
                        latched_l2 <= line2;
                        latched_l3 <= line3;
                        latched_l4 <= line4;
                        state      <= S_SET_LINE1;
                    end
                end

                // 6. Subrutina segura de pulso Enable (1 us setup + 1 us high + 1 us hold)
                S_EN_SETUP: begin
                    r_e <= 1'b0;
                    if (timer >= T_1US - 1) begin
                        timer <= '0; state <= S_EN_HIGH;
                    end else timer <= timer + 1'b1;
                end
                S_EN_HIGH: begin
                    r_e <= 1'b1;
                    if (timer >= T_1US - 1) begin
                        timer <= '0; r_e <= 1'b0; state <= S_EN_HOLD;
                    end else timer <= timer + 1'b1;
                end
                S_EN_HOLD: begin
                    r_e <= 1'b0;
                    if (timer >= T_1US - 1) begin
                        timer <= '0; state <= S_WAIT_DELAY;
                    end else timer <= timer + 1'b1;
                end
                S_WAIT_DELAY: begin
                    if (timer >= delay_target - 1) begin
                        timer <= '0; state <= next_state;
                    end else timer <= timer + 1'b1;
                end

                default: state <= S_POWER_ON;
            endcase
        end
    end
endmodule