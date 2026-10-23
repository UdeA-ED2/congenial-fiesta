module controller(input  logic [6:0] op,
                  input  logic [2:0] funct3,
                  input  logic [6:0] funct7,
                  input  logic       Zero,
                  // Int
                  output logic [1:0] ResultSrc,
                  output logic       MemWrite,
                  output logic [1:0] PCSrc,
                  output logic       ALUSrc, RegWrite, Jump, Jalr,
                  output logic [2:0] ImmSrc,
                  output logic [2:0] ALUControl,
                  output logic [1:0] SrcASel,
                  // Float
                  output logic [2:0] ALUControl_f,
                  output logic [1:0] Conv,
                  output logic       RegWrite_f,
                  output logic       ResultSrc_f);
  logic [1:0] ALUOp;
  logic       Branch;
  logic       BranchCond;
  logic       funct7b5;
  logic       is_fp;

  logic [1:0] ResultSrc_int;
  logic       RegWrite_int;

  assign funct7b5 = funct7[5];
  assign is_fp    = (op == 7'b1000011);

  maindec md(op, ResultSrc_int, SrcASel, MemWrite, Branch,
             ALUSrc, RegWrite_int, Jump, Jalr, ImmSrc, ALUOp);
  aludec  ad(op[5], funct3, funct7b5, ALUOp, ALUControl);
  fpdec   fpd(is_fp, funct7, RegWrite_int, ResultSrc_int, 
             ALUControl_f, Conv, ResultSrc_f, RegWrite_f,
             RegWrite, ResultSrc);
  
  assign PCSrc[0] = Branch & BranchCond | Jump;
  assign PCSrc[1] = Jalr;

  always_comb begin
    BranchCond = 1'b0;
    if(Branch) begin
        case(funct3)
            3'b000: BranchCond  = Zero;  // beq
            3'b001: BranchCond  = ~Zero; // bne
            3'b100: BranchCond  = ~Zero; // blt
            3'b101: BranchCond  = Zero;  // bge
            default: BranchCond = 1'bx;
        endcase
    end
  end
endmodule
