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
endmodule
