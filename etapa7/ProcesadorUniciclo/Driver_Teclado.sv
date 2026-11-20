

// =============================================================================
// Módulo: Driver_Teclado
// Descripción: Escaneo de teclado 4x4 con antirrebote, detección de tecla y flag
// Autor: J.E.Aedo
// =============================================================================

module Driver_Teclado #(
    parameter int TOPVALUE = 50_000_000
)(
    input  logic        clk,
	 input  logic        nrst,
    input  logic [3:0]  COLUMNAS,  // Entradas de columnas del teclado
    output logic [3:0]  FILAS,     // Filas activadas por el controlador
    output logic [3:0]  TECLA,     // Código de tecla detectada (0-F)
    output logic        FLAG,      // Flag alto cuando se detecta una tecla
    output logic [7:0]  DISP       // Salida al display de 7 segmentos. muestra valor de la tecla
);

    localparam int DELAY_1MS    = 10000; //
    localparam int DELAY_10MS   = 125000;
    localparam int BITS_1MS     = $clog2(DELAY_1MS);
    localparam int BITS_10MS    = $clog2(DELAY_10MS);

    logic [BITS_1MS-1:0]  conta_1ms;
    logic [BITS_10MS-1:0] conta_10ms;

    logic [4:0] tecla_detectada;
	 logic rst;

    logic [7:0] REG0;
	 logic [7:0] REG1;
	 logic [7:0] REG2;
	 logic [7:0] REG3;
	 logic [7:0] FILACOL;
	 logic [3:0] SCOL;
	 logic clkout, clkout2;
	 logic b;
	 logic [1:0] CONT;
	 
	 assign rst = ~nrst;

	// increment or reset the counter
	// DIVISOR 1MS, reloj clkout2
	always @(posedge clk) begin
		if (rst) begin
			conta_1ms <= 0;
			clkout2 <= 0;
		end else begin
			conta_1ms <= conta_1ms + 1'b1;
			if (conta_1ms == DELAY_1MS-1) begin
				clkout2 <= ~clkout2;
				conta_1ms <= 0;
			end	
		end	
	end		
 // DIVISOR 10 MS, reloj clkout
 always @(posedge clk) begin
		if (rst) begin
			conta_10ms <= 0;
			clkout <= 0;
		end else begin
			conta_10ms <= conta_10ms + 1'b1;
			if (conta_10ms == DELAY_10MS-1) begin
				clkout <= ~clkout;
				conta_10ms <= 0;
			end	
		end	
	end		
	 
	 // cuatro antirebotes por cada columna de entada.
	 //antirebote columnas 0, 1, 2, 3
	  always_ff @(posedge clkout2) begin
	      REG0 <= {REG0[6:0], COLUMNAS[0]};
         REG1 <= {REG1[6:0], COLUMNAS[1]};
			REG2 <= {REG2[6:0], COLUMNAS[2]};
			REG3 <= {REG3[6:0], COLUMNAS[3]};
	  
        if (REG0 == 8'b11111111) begin
              SCOL[0] <= 1'b1; // columna 0 detectada
			   end else begin
				  SCOL[0] <= 1'b0;
				 end
		  if (REG1 == 8'b11111111) begin
              SCOL[1] <= 1'b1; // columna 1 detectada
			   end else begin
				  SCOL[1] <= 1'b0;
				 end
			if (REG2 == 8'b11111111) begin
              SCOL[2] <= 1'b1; // columna 2 detectada
			   end else begin
				  SCOL[2] <= 1'b0;
				 end	
			if (REG3 == 8'b11111111) begin
              SCOL[3] <= 1'b1; // columna 3 detectada
			   end else begin
				  SCOL[3] <= 1'b0;
				 end
			 b<= SCOL[0] | SCOL[1] | SCOL[2] | SCOL[3]; // se activa si algunas de las columnas es detectada.
				 
		end		 
//PRUEBA se activa cada vez que detecta una tecla
		assign FLAG	= b;  // se activa cada que se detecta una tecla que se oprime.
			
     always_ff @(posedge b) begin
            if (rst) begin
			        FILACOL<= 8'b00000000;
		      end else begin
				     FILACOL<= {FILAS, SCOL};
				end
	   end			
				
	 
    
    // Escaneo de filas, se activa una fila cada ciclo de reloj
    always @(posedge clkout) begin
		if (rst) begin
			CONT <= 1'd0;
			FILAS <= 4'b0001;
		end else begin
		    CONT <= CONT + 1'd1;
        if (CONT == 2'b00) begin
              FILAS <= 4'b0001;
			   end 
		  if (CONT == 2'b01) begin
              FILAS <= 4'b0010;
			   end 
			if (CONT == 2'b10) begin
              FILAS <= 4'b0100;
				 end	
			if (CONT == 2'b11) begin
              FILAS <= 4'b1000;
			   end 
		   
        end
    end
	 
	// decodificadro de filas y columnas, termina que tecla se activo
	// de acuera la FILA y la COLUMNA.
	
    always_comb begin
        case (FILACOL) // PRIMEROS 4 BITS LA FILA Y SEGUNDOS 4 BITS LA COLUMNA ACTIVAS.
            8'b00010001: tecla_detectada = 5'b00001; // 0(1)
            8'b00010010: tecla_detectada = 5'b00010; // 0(2)
            8'b00010100: tecla_detectada = 5'b00011; // 0(3)
				8'b00011000: tecla_detectada = 5'b01010; // 0(A)
				8'b00100001: tecla_detectada = 5'b00100; // 0(4)
				8'b00100010: tecla_detectada = 5'b00101; // 0(5)
				8'b00100100: tecla_detectada = 5'b00110; // 0(6)
				8'b00101000: tecla_detectada = 5'b01011; // 0(B)
				8'b01000001: tecla_detectada = 5'b00111; // 0(7)
				8'b01000010: tecla_detectada = 5'b01000; // 0(8)
				8'b01000100: tecla_detectada = 5'b01001; // 0(9)
				8'b01001000: tecla_detectada = 5'b01100; // 0(C)
				8'b10000001: tecla_detectada = 5'b01110; // 0(E)
				8'b10000010: tecla_detectada = 5'b00000; // 0(0)
				8'b10000100: tecla_detectada = 5'b01111; // 0(F)
				8'b10001000: tecla_detectada = 5'b01101; // 0(D)
            default:  tecla_detectada = 5'b10000;
        endcase
    end
	 
	 //
	 // Decodificador 7 segmentos (DISP[6:0] = g-a, DISP[7] = punto)
    always_comb begin
        case (tecla_detectada)  // MUESTRA EL CÓDIGO DE LA TECLA DETECTADA EN EL DISPLAY.
				5'h00: DISP = 8'b11000000; // 0(0)
            5'h01: DISP = 8'b11111001; // 1(1)
            5'h02: DISP = 8'b10100100; // 2
            5'h03: DISP = 8'b10110000; // 3 
            5'h04: DISP = 8'b10011001; // 4
            5'h05: DISP = 8'b10010010; // 5
            5'h06: DISP = 8'b10000010; // 6
            5'h07: DISP = 8'b10111000; // 7
            5'h08: DISP = 8'b10000000; // 8
            5'h09: DISP = 8'b10011000; // 9
            5'h0A: DISP = 8'b10100000; // A
            5'h0B: DISP = 8'b10000011; // b
            5'h0C: DISP = 8'b11000110; // C 
            5'h0D: DISP = 8'b10100001; // d 
            5'h0E: DISP = 8'b10000110; // E 
            5'h0F: DISP = 8'b10001110; // F 
            default: DISP = 8'b00111111; //no hay ninguna tecla apretada (muestra solo el segmento g)
        endcase
    end
// salida del código de la tecla
assign TECLA = tecla_detectada[3:0];
	 
  
endmodule
