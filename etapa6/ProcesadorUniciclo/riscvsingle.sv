module riscvsingle(input  logic        clk, reset,
                   output logic [31:0] PCNext,
                   input  logic [31:0] Instr,
                   output logic        MemWrite,
                   output logic [31:0] ALUResult, WriteData,
                   input  logic [31:0] ReadData);

  // Senales control int
  logic       ALUSrc, RegWrite, Jump, Zero, Jalr;
  logic [1:0] ResultSrc, PCSrc, SrcASel;
  logic [2:0] ALUControl, ImmSrc;

  // Senales control float
  logic       RegWrite_f, ResultSrc_f;
  logic [1:0] Conv;
  logic [2:0] ALUControl_f;

  logic [31:0] FromInt, FromFloat;

  controller c(Instr[6:0], Instr[14:12], Instr[31:25], Zero,
               ResultSrc, MemWrite, PCSrc,
               ALUSrc, RegWrite, Jump, Jalr,
               ImmSrc, ALUControl, SrcASel,
	       ALUControl_f, Conv, RegWrite_f,
	       ResultSrc_f);
  datapath dp(clk, reset, ResultSrc, PCSrc,
              ALUSrc, RegWrite,
              ImmSrc, ALUControl, SrcASel,
              FromFloat, Zero, PCNext, FromInt, Instr,
              ALUResult, WriteData, ReadData);
  datapath_f dp_f(clk, reset, ResultSrc_f,
	      RegWrite_f, Conv, ALUControl_f,
	      Instr, FromInt, FromFloat);
endmodule
