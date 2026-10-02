module maindec(input  logic [6:0] op,
               output logic [1:0] ResultSrc,
               output logic [1:0] SrcASel,
               output logic       MemWrite,
               output logic       Branch, ALUSrc,
               output logic       RegWrite, Jump, Jalr,
               output logic [2:0] ImmSrc,
               output logic [1:0] ALUOp);

  logic [14:0] controls;

  assign {RegWrite, ImmSrc, ALUSrc, MemWrite,
          ResultSrc, Branch, ALUOp, Jump, Jalr, SrcASel} = controls;

  always_comb
    case(op)
    // RegWrite_ImmSrc_ALUSrc_MemWrite_ResultSrc_Branch_ALUOp_Jump_Jalr_SrcASel
      7'b0000011: controls = 15'b1_000_1_0_01_0_00_0_0_00; // lw
      7'b0100011: controls = 15'b0_001_1_1_00_0_00_0_0_00; // sw
      7'b0110011: controls = 15'b1_xxx_0_0_00_0_10_0_0_00; // R-type 
      7'b1100011: controls = 15'b0_010_0_0_00_1_01_0_0_00; // beq
      7'b0010011: controls = 15'b1_000_1_0_00_0_10_0_0_00; // I-type ALU
      7'b1101111: controls = 15'b1_011_0_0_10_0_00_1_0_00; // jal
      7'b1100111: controls = 15'b1_000_1_0_10_0_00_0_1_00; // jalr
      7'b0110111: controls = 15'b1_100_1_0_00_0_00_0_0_10; // lui (SrcA = zero)
      7'b0010111: controls = 15'b1_100_1_0_00_0_00_0_0_01; // auipc (SrcA = PC)
      default:    controls = 15'bx_xxx_x_x_xx_x_xx_x_x_xx; // non-implemented instruction
    endcase
endmodule
