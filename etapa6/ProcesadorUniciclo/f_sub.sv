module f_sub(input  logic [31:0] a,
             input  logic [31:0] b,
             output logic [31:0] result);
  logic [31:0] bSub;
  assign bSub = {~b[31], b[30:0]};
  f_sum addition2Substract(a, bSub, result);
endmodule