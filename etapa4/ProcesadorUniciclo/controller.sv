module controller(input  logic [6:0] op,
                  input  logic [2:0] funct3,
                  input  logic [6:0] funct7,
                  input  logic       Zero,
                  output logic [1:0] ResultSrc,
                  output logic       MemWrite,
                  output logic [1:0] PCSrc,
                  output logic       ALUSrc, RegWrite, Jump, Jalr,
                  output logic [2:0] ImmSrc,
                  output logic [2:0] ALUControl,
                  output logic [1:0] SrcASel);
  logic [1:0] ALUOp;
  logic       Branch;
  logic       BranchCond;
  logic       funct7b5;
  assign funct7b5 = funct7[5];

  maindec md(op, ResultSrc, SrcASel, MemWrite, Branch,
             ALUSrc, RegWrite, Jump, Jalr, ImmSrc, ALUOp);
  aludec  ad(op[5], funct3, funct7b5, ALUOp, ALUControl);

  assign PCSrc[0] = Branch & BranchCond | Jump;
  assign PCSrc[1] = Jalr;
  always_comb begin
    case(funct3)
        3'b000: BranchCond  = Zero;  // beq
        3'b001: BranchCond = ~Zero;  // beq
        default: BranchCond = 1'bx;
    endcase
  end
endmodule
