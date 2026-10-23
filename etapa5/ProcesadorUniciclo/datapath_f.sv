module datapath_f(input  logic        clk, reset,
                input  logic        ResultSrc, 
                input  logic        RegWrite,
                input  logic [1:0]  Conv,
                input  logic [2:0]  ALUControl,
                input  logic [31:0] Instr,
                input  logic [31:0] FromInt,
                output logic [31:0] FromFloat,
                output logic [31:0] ALUResult);

  logic [31:0] SrcA, SrcB;
  logic [31:0] Result;
  logic [31:0] FromIntResult;
 
  // register file logic
  regfile     rf(clk, RegWrite, Instr[19:15], Instr[24:20], 
                 Instr[11:7], Result, SrcA, SrcB);

  // ALU logic
  alu_f       alu(SrcA, SrcB, ALUControl, ALUResult);
  mux2 #(32)  resultmux(ALUResult, FromIntResult, ResultSrc, Result);

  // Conversion
  // Conv: 2'b00: None; 2'b10: Int2Float; 2'b01: Float2Int
  always_comb begin
      FromFloat = SrcA;
      if(Conv == 2'b01) begin
          FromFloat = f2i(SrcA);
      end
  end

  always_comb begin
      FromIntResult = FromInt;
      if(Conv == 2'b10) begin
          // TODO: Algoritmo conversion int 2 float
          FromIntResult = FromInt;
      end
  end

  function automatic logic [31:0] f2i(input logic [31:0] f);
      logic        s;
      logic [7:0]  E;
      logic [22:0] f;
      logic [23:0] m;
      logic [7:0]  e;
      logic [31:0] result;

      int shift;

      if (E == 255) return 32'h7FFF_FFFF;
      if (E == 0)   return 0;

      e = E - 127;
      m = {1'b1, f};

      if (e < 0)    return 0;
      if (e > 30)   return s ? 32'h8000_0000 : 32'h7FFF_FFFF;

      shift = 23 - e;
      if (shift <= 0) result = m << (-shift);
      else result = m >> shift;

      return s ? -result : result;
  endfunction

  function automatic logic [31:0] i2f(input logic [31:0] x, input logic [2:0] rm);
      logic        s;
      logic [7:0]  E;
      logic [22:0] f;
      logic [23:0] m;
      logic [7:0]  e;
      logic [31:0] mag;

      if (x == 0) return 0;
      
      // TODO: Terminar algoritmo, no falta tanto :]
  endfunction
endmodule
