module alu_f(input  logic [31:0] a, b,
           input  logic [2:0]  alucontrol,
           output logic [31:0] result);

  logic [31:0] sum;

  always_comb
    case (alucontrol)
      3'b000:  result = sum;         // add
      3'b001:  result = sum;         // subtract
      default: result = 32'bx;
    endcase
  
endmodule
