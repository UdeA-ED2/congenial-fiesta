module f_sum (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] result
);

    logic sign_a, sign_b, sign_result;
    logic [7:0] exp_a, exp_b, exp_result, exp_diff;
    logic [22:0] frac_a, frac_b;

    logic [23:0] sig_a, sig_b;
    logic [23:0] sig_large, sig_small;
    logic [23:0] sig_small_shifted, sig_result;
    logic [24:0] sig_sum;

    logic a_is_larger;

    always_comb begin

        sign_a  = a[31];
        exp_a   = a[30:23];
        frac_a   = a[22:0];

        sign_b  = b[31];
        exp_b   = b[30:23];
        frac_b  = b[22:0];

        sig_a = {1'b1, frac_a};
        sig_b = {1'b1, frac_b};

        result            = 32'b0;
        sign_result       = 1'b0;
        exp_result        = 8'b0;
        exp_diff          = 8'b0;
        sig_large         = 24'b0;
        sig_small         = 24'b0;
        sig_small_shifted = 24'b0;
        sig_result        = 24'b0;
        sig_sum           = 25'b0;
        a_is_larger       = 1'b1;

        // ====================================================================
        // 2. EVALUACIÓN DE CASOS ESPECIALES
        // ====================================================================
        
        // NaN: exponente FF y fraccion distinta de cero
        if ((exp_a == 8'hFF && frac_a != 0) || (exp_b == 8'hFF && frac_b != 0)) begin
            result = 32'h7FC00000; // NaN 
        end

        // Ambos operandos son infinitos
        else if (exp_a == 8'hFF && exp_b == 8'hFF) begin
            if (sign_a != sign_b)
                result = 32'h7FC00000; // +inf + -inf = NaN
            else
                result = {sign_a, 8'hFF, 23'b0}; // mismo infinito
        end

        // Solo 'a' es infinito
        else if (exp_a == 8'hFF) begin
            result = {sign_a, 8'hFF, 23'b0};
        end

        // Solo 'b' es infinito
        else if (exp_b == 8'hFF) begin
            result = {sign_b, 8'hFF, 23'b0};
        end
        
        // Operación con números normales/subnormales
        else begin
            // Elegir el operando de mayor magnitud
            if ({exp_a, frac_a} >= {exp_b, frac_b}) begin
                a_is_larger = 1'b1;
                exp_result  = exp_a;
                exp_diff    = exp_a - exp_b;
                sig_large   = sig_a;
                sig_small   = sig_b;
            end else begin
                a_is_larger = 1'b0;
                exp_result  = exp_b;
                exp_diff    = exp_b - exp_a;
                sig_large   = sig_b;
                sig_small   = sig_a;
            end

            // Alinear los exponentes
            sig_small_shifted = sig_small >> exp_diff;

            // Sumar si los signos coinciden; restar si son diferentes
            if (sign_a == sign_b) begin
                sig_sum     = {1'b0, sig_large} + {1'b0, sig_small_shifted};
                sign_result = sign_a;

                // Acarreo: desplazar y aumentar el exponente
                if (sig_sum[24]) begin
                    sig_result = sig_sum[24:1];
                    exp_result = exp_result + 1'b1;
                end else begin
                    sig_result = sig_sum[23:0];
                end

            end else begin
                sig_result = sig_large - sig_small_shifted;

                // El resultado conserva el signo de la mayor magnitud
                if (a_is_larger)
                    sign_result = sign_a;
                else
                    sign_result = sign_b;

                // Normalizar la resta desplazando hacia la izquierda
                for (int i = 0; i < 23; i = i + 1) begin
                    if (sig_result != 0 && sig_result[23] == 1'b0 && exp_result > 1) begin
                        sig_result = sig_result << 1;
                        exp_result = exp_result - 1'b1;
                    end
                end
            end

            // Construir el resultado final
            if (sig_result == 0) begin
                result = 32'b0;
            end else begin
                result = {sign_result, exp_result, sig_result[22:0]};
            end
        end
    end

endmodule