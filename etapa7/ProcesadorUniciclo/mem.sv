module mem #(parameter WIDTH=32, DEPTH=1<<10)(
    input  logic clk, reset, we2, 
    input  logic [WIDTH-1:0] a1, a2, wd, 
    output logic [WIDTH-1:0] rd1, rd2, 
    input  logic [9:0] switches, 
    output logic [9:0] leds,
    input  logic [3:0] key,
    input  logic kb_flag,
    output logic [0:3][159:0] lines,
	 input  logic lcd_busy
);
    localparam addr_bits = $clog2(DEPTH); 

    logic [WIDTH-1:0] rd_A, rd_B;
    logic [addr_bits-1:0] addr_A, addr_B;
    logic we_B, led_in, switches_in, memoryMappedDevice;
    logic kb_in, lcd_in;
    logic lcd_busy_sel;
    logic [4:0] lcd_idx;

    altsyncram #(
        .OPERATION_MODE("BIDIR_DUAL_PORT"),
        .INIT_FILE("mem.mif"),
        .WIDTH_A(WIDTH),
        .WIDTHAD_A(addr_bits),
        .WIDTH_B(WIDTH),
        .WIDTHAD_B(addr_bits)
    ) u_mem (
        .clock0(clk),
        .address_a(addr_A),
        .q_a(rd_A),
        .clock1(~clk),
        .address_b(addr_B),
        .wren_b(we_B),
        .data_b(wd),
        .q_b(rd_B)
    );

    always_comb begin
        if (reset) begin
            addr_A = '0;
            we_B   = 1'b0;
        end else begin
            addr_A = a1[addr_bits+1:2];
            we_B   = memoryMappedDevice ? 1'b0 : we2;
        end
    end

    assign rd1         = rd_A;
    assign addr_B      = a2[addr_bits+1:2];
    assign led_in      = (a2 == 32'hFF20_0000);
    assign switches_in = (a2 == 32'hFF20_0040);
    assign kb_in       = (a2 == 32'hFF20_0080);
    // Rango de 20 palabras (80 bytes) para las 4 lineas de la LCD
    assign lcd_in      = (a2 >= 32'hFF20_00C0) && (a2 <= 32'hFF20_010C);
	assign lcd_busy_sel= (a2 == 32'hFF20_0110);
    assign lcd_idx     = 5'((a2 - 32'hFF20_00C0) >> 2);
    assign memoryMappedDevice = led_in || switches_in || kb_in || lcd_in;

    // Lectura unificada de memoria o periféricos
    always_comb begin
        if (switches_in)
            rd2 = {22'b0, switches};
        else if (kb_in)
            rd2 = {27'b0, kb_flag, key};
        else if (lcd_busy_sel)
            rd2 = {31'b0, lcd_busy};
        else
            rd2 = rd_B;
    end

    // Escritura en LEDs
    always_ff @(posedge clk) begin
        if (reset)
            leds <= 10'b0;
        else if (led_in && we2)
            leds <= wd[9:0];
    end

    // Escritura en las 4 líneas de la LCD (4 caracteres ASCII por cada sw)
    always_ff @(posedge clk) begin
        if (reset) begin
            lines[0] <= "                    ";
            lines[1] <= "                    ";
            lines[2] <= "                    ";
            lines[3] <= "                    ";
        end else if (lcd_in && we2) begin
            case (lcd_idx)
                // Fila 1
                5'd0:  lines[0][159:128] <= wd;
                5'd1:  lines[0][127:96]  <= wd;
                5'd2:  lines[0][95:64]   <= wd;
                5'd3:  lines[0][63:32]   <= wd;
                5'd4:  lines[0][31:0]    <= wd;
                // Fila 2
                5'd5:  lines[1][159:128] <= wd;
                5'd6:  lines[1][127:96]  <= wd;
                5'd7:  lines[1][95:64]   <= wd;
                5'd8:  lines[1][63:32]   <= wd;
                5'd9:  lines[1][31:0]    <= wd;
                // Fila 3
                5'd10: lines[2][159:128] <= wd;
                5'd11: lines[2][127:96]  <= wd;
                5'd12: lines[2][95:64]   <= wd;
                5'd13: lines[2][63:32]   <= wd;
                5'd14: lines[2][31:0]    <= wd;
                // Fila 4
                5'd15: lines[3][159:128] <= wd;
                5'd16: lines[3][127:96]  <= wd;
                5'd17: lines[3][95:64]   <= wd;
                5'd18: lines[3][63:32]   <= wd;
                5'd19: lines[3][31:0]    <= wd;
                default: ;
            endcase
        end
    end

endmodule
