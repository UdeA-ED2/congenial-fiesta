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
          // TODO: Algoritmo conversion float 2 int
          FromFloat = SrcA;
      end
  end

  always_comb begin
      FromIntResult = FromInt;
      if(Conv == 2'b10) begin
          // TODO: Algoritmo conversion int 2 float
          FromIntResult = FromInt;
      end
  end
endmodule
