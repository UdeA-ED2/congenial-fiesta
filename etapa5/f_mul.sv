module f_mul(input  logic [31:0] a,
             input  logic [31:0] b,
             output logic [31:0] result);
  logic        sign_a, sign_b;
  logic [7:0]  exp_a, exp_b;
  logic [22:0] frac_a, frac_b;
  logic [23:0] man_a, man_b;
  
  logic        sign_r;
  logic signed [10:0]  exp_r;
  logic [22:0] frac_r;
  logic [47:0] man_r;
  
  logic a_isNaN, b_isNaN;
  logic a_isInf, b_isInf;
  logic a_isZero, b_isZero;
  
  assign sign_a = a[31];
  assign sign_b = b[31];
  assign exp_a  = a[30:23];
  assign exp_b  = b[30:23];
  assign frac_a = a[22:0];
  assign frac_b = b[22:0];
  
  assign man_a  = {1'b1, frac_a};
  assign man_b  = {1'b1, frac_b};
  
  assign a_isZero = (exp_a == 0);
  assign b_isZero = (exp_b == 0);
  assign a_isInf  = (exp_a == 8'hFF) && (frac_a == 0);
  assign b_isInf  = (exp_b == 8'hFF) && (frac_b == 0);
  assign a_isNaN  = (exp_a == 8'hFF) && (frac_a != 0);
  assign b_isNaN  = (exp_b == 8'hFF) && (frac_b != 0);
  
  always_comb begin
    sign_r = sign_a ^ sign_b;
    man_r = man_a * man_b;
    
    // Normalizar mantissa y obtener fraccion
    if (man_r[47]) begin
      exp_r = $signed({3'b0, exp_a}) + $signed({3'b0, exp_b}) - 11'sd126;
      frac_r = man_r[46:24];
    end else begin
      exp_r = $signed({3'b0, exp_a}) + $signed({3'b0, exp_b}) - 11'sd127;
      frac_r = man_r[45:23];
    end
    
    // Casos especiales magicos
    if (a_isNaN || b_isNaN)
      result = {sign_r, 8'hFF, 23'h400000};
    else if ((a_isInf && b_isZero) || (b_isInf && a_isZero))
      result = {sign_r, 8'hFF, 23'h400000};
    else if (a_isInf || b_isInf)
      result = {sign_r, 8'hFF, 23'h000000};
    else if (a_isZero || b_isZero)
      result = {sign_r, 8'h00, 23'h000000};
    else if (exp_r >= 11'sd255)
      result = {sign_r, 8'hFF, 23'h000000};
    else if (exp_r <= 11'sd0)
      result = {sign_r, 8'h00, 23'h000000};
    else
      result = {sign_r, exp_r[7:0], frac_r};
  end
  
endmodule