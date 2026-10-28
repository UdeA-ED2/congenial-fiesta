// Conversión IEEE-754 binary32 -> int32 (truncamiento hacia cero).
// Saturation: |x| >= 2^31  ->  INT_MAX / INT_MIN
// Subnormales y |x| < 1    ->  0
module float2int (
    input  logic [31:0] f,
    output logic [31:0] result
);
    logic        s;
    logic [7:0]  E;
    logic [22:0] frac;
    logic [23:0] m;
    logic [7:0]  e;
    int          shift;
    logic [31:0] mag_result;

    always_comb begin
        s          = f[31];
        E          = f[30:23];
        frac       = f[22:0];
        result     = 32'b0;
        mag_result = 32'b0;
        e          = 8'b0;
        m          = 24'b0;
        shift      = 0;

        if (E > 8'd157) begin
            // exp_real > 30  =>  |x| >= 2^31  =>  saturar
            result = s ? 32'h8000_0000 : 32'h7FFF_FFFF;
        end
        else if (E == 0) begin
            // cero o subnormal  =>  0
            result = 32'b0;
        end
        else if (E < 8'd127) begin
            // |x| < 1  =>  truncar a 0
            result = 32'b0;
        end
        else begin
            e     = E - 8'd127;
            m     = {1'b1, frac};
            shift = 23 - e;

            if (shift <= 0)
                mag_result = m << (-shift);
            else
                mag_result = m >> shift;

            result = s ? -mag_result : mag_result;
        end
    end
endmodule
