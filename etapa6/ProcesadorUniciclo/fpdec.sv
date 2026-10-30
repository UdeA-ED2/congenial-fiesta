module fpdec(
    input  logic       is_fp,
    input  logic [6:0] funct7,
    input  logic       RegWrite_int,
    input  logic [1:0] ResultSrc_int,
    output logic [2:0] ALUControl_f,
    output logic [1:0] Conv,
    output logic       ResultSrc_f,
    output logic       RegWrite_f,
    output logic       RegWrite,
    output logic [1:0] ResultSrc);

    logic [4:0] funct5;
    assign funct5 = funct7[6:2];

    logic [9:0]  controls_f;

    assign {RegWrite_f, ResultSrc_f, ALUControl_f, Conv, RegWrite, ResultSrc} = controls_f;

    always_comb begin
        controls_f = {1'b0, 1'b0, 3'b000, 2'b00, RegWrite_int, ResultSrc_int};

        if (is_fp) begin
            // RegWriteF_ResultSrcF_ALUControlF_Conv_RegWrite_ResultSrc
            case (funct5)
                5'b00000: controls_f = 10'b1_0_000_00_0_00; // fadd.s
                5'b00001: controls_f = 10'b1_0_001_00_0_00; // fsub.s
                5'b00010: controls_f = 10'b1_0_010_00_0_00; // fmul.s
                5'b00011: controls_f = 10'b1_0_011_00_0_00; // fdiv.s
                5'b11010: controls_f = 10'b1_1_000_10_0_00; // fcvt.s.w
                5'b11000: controls_f = 10'b0_0_000_01_1_11; // fcvt.w.s
                5'b11110: controls_f = 10'b1_1_000_00_0_00; // fmv.w.x
                5'b11100: controls_f = 10'b0_0_000_00_1_11; // fmv.x.w
                default: ;
            endcase
        end
    end

endmodule
