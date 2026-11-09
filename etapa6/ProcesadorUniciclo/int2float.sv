// Conversión int32 -> IEEE-754 binary32 (TRUNCAMIENTO, sin redondeo).
// El puerto rm se mantiene por compatibilidad con datapath_f; NO se usa.
module int2float (
    input  logic [31:0] x,
    input  logic [2:0]  rm,      // unused (TODO: rounding modes)
    output logic [31:0] result
);
    logic        s;
    logic [7:0]  E;
    logic [22:0] f;
    logic [23:0] m;
    logic [31:0] mag;
    logic [4:0]  p;

    always_comb begin
        result = 32'b0;
        s      = 1'b0;
        E      = 8'b0;
        f      = 23'b0;
        m      = 24'b0;
        mag    = 32'b0;
        p      = 5'b0;

        if (x != 0) begin
            s = x[31];
            mag = s ? -x : x;

            // posición del bit más significativo (0..31)
            p = 5'd0;
            for (int i = 0; i < 32; i++)
                if (mag[i]) p = i[4:0];

            E = p + 8'd127;

            if (p > 5'd23)       m = mag >> (p - 5'd23);       // truncar
            else if (p < 5'd23)  m = mag << (5'd23 - p);       // alinear
            else                 m = mag;

            f      = m[22:0];
            result = {s, E, f};
        end
    end
endmodule
