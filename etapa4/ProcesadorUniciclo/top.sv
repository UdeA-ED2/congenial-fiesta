/*
 * This module is the TOP of the ARM single-cycle processor
 */ 
module top(input logic clk, nreset,
			  input logic [9:0] switches,
			  output logic [9:0] leds);
	
	
	// Internal signals
	logic MemWrite, nSyncReset, syncReset;
	logic [31:0] PCNext, Instr, ReadData;
	logic [31:0] WriteData, DataAdr;	
	
	assign syncReset = ~nSyncReset;
	
	// Instantiate Memory
	mem mem(clk, syncReset, MemWrite, PCNext, DataAdr, WriteData, Instr, ReadData, switches, leds);
	
	// Instantiate processor
	//arm arm (clk, syncReset, PCNext, Instr, MemWrite, DataAdr, WriteData, ReadData);
	//riscvsingle rvsingle(clk, reset, PC, Instr, MemWrite, DataAdr, WriteData, ReadData);
	riscvsingle rvsingle(clk, syncReset, PCNext, Instr, MemWrite, DataAdr, WriteData, ReadData);
	
	// Create a synchronous reset, required by memory
	flopr #(1) resetReg(clk, ~nreset, 1'b1, nSyncReset);

endmodule

