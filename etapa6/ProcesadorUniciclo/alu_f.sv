module alu_f(input  logic [31:0] a, b,
           input  logic [2:0]  alucontrol,
           output logic [31:0] result);

  logic [31:0] add;
  logic [31:0] sub;
  logic [31:0] mul;
  logic [31:0] div;
  
  f_sum suma(a, b, add);
  f_sub resta(a, b, sub);
  f_mul prod(a, b, mul);
  f_div ditto(a, b, div);

  always_comb begin
    case (alucontrol)
      3'b000:  result = add;         // add
      3'b001:  result = sub;         // subtract
      3'b010:  result = mul;
      3'b011:  result = div;
      default: result = 32'bx;
    endcase
  end
endmodule
