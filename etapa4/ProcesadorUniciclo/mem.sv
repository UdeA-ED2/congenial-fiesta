module mem #(parameter WIDTH=32, DEPTH=1<<10)(
			input logic clk, reset, we2, 
			input logic [WIDTH-1:0] a1, a2, wd, 
			output logic [WIDTH-1:0] rd1, rd2, 
			input logic [9:0] switches, 
			output logic [9:0] leds);
	
	localparam addr_bits = $clog2(DEPTH); 
	
	logic [WIDTH-1:0] rd_A, rd_B;
	logic [addr_bits-1:0] addr_A, addr_B;
	logic we_B, led_in, switches_in, memoryMappedDevice;
	
	
	altsyncram #(
		.OPERATION_MODE("BIDIR_DUAL_PORT"),
		.INIT_FILE("mem.mif"),
		
		.WIDTH_A(WIDTH),
		.WIDTHAD_A(addr_bits),
		
		.WIDTH_B(WIDTH),
		.WIDTHAD_B(addr_bits)
	) 
	u_mem(
		.clock0(clk),
		.address_a(addr_A),
		.q_a(rd_A),
	
		.clock1(~clk),
		.address_b(addr_B),
		.wren_b(we_B),
		.data_b(wd),
		.q_b(rd_B)
	);
    /*
    // ---- RAM Verilog pura (reemplaza al altsyncram) ----
    logic [WIDTH-1:0] RAM [0:DEPTH-1];

    initial begin
        $readmemh("memory.hex", RAM);
    end

    // Puerto A: lectura combinacional (instrucciones)
    assign rd_A = RAM[addr_A];

    // Puerto B: lectura combinacional (datos)
    assign rd_B = RAM[addr_B];

    // Puerto B: escritura síncrona
    always_ff @(posedge clk) begin
        if (we_B)
            RAM[addr_B] <= wd;
    end
    // -----------------------------------------------------
    */
	

	always_comb begin
		
		if(reset) begin
			addr_A = 1'b0;    // se requiere porque modulo recibe PCNext o sea empieza en 0x4
			we_B   = 1'b0;  // para asegurar que no se escriba en la memoria en reset
		end
		else  begin
			addr_A = a1[addr_bits+1:2];
			we_B   = (memoryMappedDevice) ? '0 : we2;  // se escribe en memoria si direccion no es a dispositivo mapeado en memoria
		end
	end
	
	assign rd1    = rd_A;
	assign addr_B = a2[addr_bits+1:2];
	assign led_in = (a2 == 32'hFF20_0000);
	assign switches_in = (a2 == 32'hFF20_0040);
	assign memoryMappedDevice = led_in || switches_in;
	
	// read memory or Memory mapped Device
	always_comb
		if (switches_in)
			rd2 = {22'b0, switches};
		else
			rd2 = rd_B;
			
	// write to output device
	always_ff @(posedge clk)
		if (led_in && we2)
			leds <= wd[9:0];
	
endmodule
