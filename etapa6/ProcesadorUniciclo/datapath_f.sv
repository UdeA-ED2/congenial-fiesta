module datapath_f(input  logic        clk, reset,
                input  logic        ResultSrc, 
                input  logic        RegWrite,
                input  logic [1:0]  Conv,
                input  logic [2:0]  ALUControl,
                input  logic [31:0] Instr,
                input  logic [31:0] FromInt,
                output logic [31:0] FromFloat);

  logic [31:0] SrcA, SrcB;
  logic [31:0] Result;
  logic [31:0] FromIntResult;
  logic [31:0] ALUResult;
  logic [31:0] i2f, f2i;
  logic [2:0]  rm;
  
  assign rm = Instr[14:12];
 
  // register file logic
  regfile     rf(clk, RegWrite, Instr[19:15], Instr[24:20], 
                 Instr[11:7], Result, SrcA, SrcB);

  // ALU logic
  alu_f       alu(SrcA, SrcB, ALUControl, ALUResult);
  mux2 #(32)  resultmux(ALUResult, FromIntResult, ResultSrc, Result);

  float2int float_to_int(SrcA, f2i);
  int2float int_to_float(FromInt, rm, i2f);

  // Conversion
  // Conv: 2'b00: None; 2'b10: Int2Float; 2'b01: Float2Int
  always_comb begin
      FromFloat = SrcA;
      if(Conv == 2'b01) begin
          // FromFloat = f2i(SrcA);
          FromFloat = f2i;
      end
  end

  always_comb begin
      FromIntResult = FromInt;
      if(Conv == 2'b10) begin
          // FromIntResult = i2f(FromInt, rm);
          FromIntResult = i2f;
      end
  end

  /*
  function automatic logic [31:0] f2i(input logic [31:0] f);
      logic        s;
      logic [7:0]  E;
      logic [22:0] frac;
      logic [23:0] m;
      logic [7:0]  e;
      logic [31:0] result;

      int shift;
      
      s = f[31];
      E = f[30:23];
      frac = f[22:0];

      if (E > 8'd157) return s ? 32'h8000_0000 : 32'h7FFF_FFFF;
      if (E == 0)     return 0;
      if (E < 8'd127) return 0;

      e = E - 127;
      m = {1'b1, frac};

      shift = 23 - e;
      if (shift <= 0) result = m << (-shift);
      else result = m >> shift;

      return s ? -result : result;
  endfunction

    // TODO: Rounding Modes (rm que sirva pa algo)
  function automatic logic [31:0] i2f(input logic [31:0] x, input logic [2:0] rm);
      logic        s;
      logic [7:0]  E;
      logic [22:0] f;
      logic [23:0] m;
      logic [31:0] mag;
      logic [4:0]  p;

      if (x == 0) return 0;
      
      s = x[31];
      
      if (s) mag = -x;
      else   mag =  x;
      
      p = 5'd0;
      for (int i = 0; i < 32; i++)
        if (mag[i]) p = i[4:0];
        
      E = p + 127;
      
      if (p > 23)      m = mag >> (p - 23);
      else if (p < 23) m = mag << (23 - p);
      else             m = mag;
      
      f = m[22:0];
      return {s, E, f};
  endfunction
  */
endmodule
