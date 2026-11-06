module alu_f(input  logic [31:0] a, b,
           input  logic [2:0]  alucontrol,
           output logic [31:0] result);

  logic [31:0] add;
  // logic [31:0] sub;
  logic [31:0] mul;
  logic [31:0] div;
  logic        bSign;
  
  assign bSign = alucontrol[0] ? ~b[31] : b[31];
  
  f_sum suma(a, {bSign,b[30:0]}, add);
  // f_sum resta(a, {~b[31],b[30:0]}, sub);
  // f_sub resta(a, b, sub);
  f_mul prod(a, b, mul);
  f_div ditto(a, b, div);

  always_comb begin
    case (alucontrol)
      3'b000:  result = add;         // add
      3'b001:  result = add;         // subtract
      3'b010:  result = mul;
      3'b011:  result = div;
      default: result = 32'bx;
    endcase
  end
endmodule
