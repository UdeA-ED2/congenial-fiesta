/*
 * This module is the Floating Point Register File
 */ 
module regfile_f(input  logic        clk, 
                 input  logic        we3, 
                 input  logic [ 4:0] a1, a2, a3, 
                 input  logic [31:0] wd3, 
                 output logic [31:0] rd1, rd2);

  logic [31:0] rf[31:0];

  // three ported register file
  // read two ports combinationally (A1/RD1, A2/RD2)
  // write third port on rising edge of clock (A3/WD3/WE3)
  // This one does allow to write data on f0

  always_ff @(posedge clk)
    if (we3) rf[a3] <= wd3;	

  assign rd1 = rf[a1];
  assign rd2 = rf[a2];
endmodule
