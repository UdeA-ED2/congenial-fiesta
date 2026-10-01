/*
 * This module is the Adder of the Datapath Unit
 */ 
module adder(input  [31:0] a, b,
             output [31:0] y);

  assign y = a + b;
endmodule