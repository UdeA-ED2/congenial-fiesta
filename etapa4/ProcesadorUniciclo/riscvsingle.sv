module riscvsingle(input  logic        clk, reset,
                   output logic [31:0] PC,
                   input  logic [31:0] Instr,
                   output logic        MemWrite,
                   output logic [31:0] ALUResult, WriteData,
                   input  logic [31:0] ReadData);

  logic       ALUSrc, RegWrite, Jump, Zero, Jalr;
  logic [1:0] ResultSrc, PCSrc, SrcASel;
  logic [2:0] ALUControl, ImmSrc;

  controller c(Instr[6:0], Instr[14:12], Instr[31:25], Zero,
               ResultSrc, MemWrite, PCSrc,
               ALUSrc, RegWrite, Jump, Jalr,
               ImmSrc, ALUControl, SrcASel);
  datapath dp(clk, reset, ResultSrc, PCSrc,
              ALUSrc, RegWrite,
              ImmSrc, ALUControl, SrcASel,
              Zero, PC, Instr,
              ALUResult, WriteData, ReadData);
endmodule
