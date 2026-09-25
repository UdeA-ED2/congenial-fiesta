# =============================================================================
# Calculadora UART - RISC-V
#
# Layout de bcd_out (producido por float2Bcd, leído por bcd2Float y bcd2Ascii):
#   [0]       signo ASCII ('+'/'-')
#   [1..10]   10 dígitos enteros (crudos 0-9)
#   [11]      '.' (0x2E)
#   [12..16]  5 decimales (crudos 0-9)
#   [17]      0xB terminador
#
# Teclas:
#   [Enter] -> termina buffer_in y lo imprime (eco)
#   [DEL]   -> retroceso
#   '='     -> CALCULA: parse_expr -> float2Bcd -> bcd2Float -> bcd2Ascii -> UART
#   'm'     -> muestra buffer_out
#   'c'     -> limpia buffer_in
# =============================================================================

.global _start
.text

# =============================================================================
# Inicio
# =============================================================================
# =============================================================================
# Inicio - Banco de pruebas
# =============================================================================
_start:
main:
    lui  sp, 0x10

    la   s0, test_cases          # puntero a array de strings de entrada
    la   s1, expected_cases      # puntero a array de strings esperados
    la   s2, test_results        # puntero a resultados 1/0

test_loop:
    lw   a0, 0(s0)
    beq  a0, zero, test_done

    # Copiar string ASCII a buffer_in como words (simula entrada UART)
    la   a1, buffer_in
    jal  str_to_wordbuf

    # Mismo proceso que hacia do_calcular, pero sin UART
    jal  calcular_test

    # Comparar buffer_out contra expected
    la   a0, buffer_out
    lw   a1, 0(s1)
    jal  cmp_buffer_ascii
    sw   a0, 0(s2)

    addi s0, s0, 4
    addi s1, s1, 4
    addi s2, s2, 4
    j    test_loop

test_done:
    j    test_done

# =============================================================================
# calcular_test
#   Mismo flujo que do_calcular, sin UART.
#   Entrada: buffer_in ya cargado
#   Salida:  buffer_out con ASCII, o "inf"/"error"
# =============================================================================
calcular_test:
    addi sp, sp, -4
    sw   ra, 0(sp)

    la   t0, parse_status
    sw   zero, 0(t0)

    la   a0, buffer_in
    lw   t0, 0(a0)
    beq  t0, zero, ct_done

    jal  parse_expr

    la   t0, parse_status
    lw   t1, 0(t0)

    li   t2, 1
    beq  t1, t2, ct_inf

    li   t2, 2
    beq  t1, t2, ct_error

    # float -> BCD
    la   a1, bcd_out
    jal  float2Bcd

    # BCD -> float (round-trip)
    la   a1, bcd_out
    jal  bcd2Float
    la   t0, last_float
    fmv.x.w t1, fa0
    sw   t1, 0(t0)

    # BCD -> ASCII
    la   a0, bcd_out
    la   a1, buffer_out
    jal  bcd2Ascii
    j    ct_done

ct_inf:
    la   t0, buffer_out
    li   t1, 'i'
    sw   t1, 0(t0)
    li   t1, 'n'
    sw   t1, 4(t0)
    li   t1, 'f'
    sw   t1, 8(t0)
    sw   zero, 12(t0)
    j    ct_done

ct_error:
    la   t0, buffer_out
    li   t1, 'e'
    sw   t1, 0(t0)
    li   t1, 'r'
    sw   t1, 4(t0)
    sw   t1, 8(t0)
    li   t1, 'o'
    sw   t1, 12(t0)
    li   t1, 'r'
    sw   t1, 16(t0)
    sw   zero, 20(t0)

ct_done:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

# =============================================================================
# str_to_wordbuf
#   a0 = fuente .asciz
#   a1 = destino word-array
# =============================================================================
str_to_wordbuf:
st_loop:
    lb   t0, 0(a0)
    sw   t0, 0(a1)
    beq  t0, zero, st_done
    addi a0, a0, 1
    addi a1, a1, 4
    j    st_loop
st_done:
    ret

# =============================================================================
# cmp_buffer_ascii
#   a0 = buffer_out word-array
#   a1 = string esperado .asciz
#   retorna a0 = 1 si son iguales, 0 si no
# =============================================================================
cmp_buffer_ascii:
    add  t0, a0, zero
    add  t1, a1, zero
cmp_loop:
    lw   t2, 0(t0)
    lb   t3, 0(t1)
    bne  t2, t3, cmp_fail
    beq  t2, zero, cmp_ok
    addi t0, t0, 4
    addi t1, t1, 1
    j    cmp_loop
cmp_fail:
    li   a0, 0
    ret
cmp_ok:
    li   a0, 1
    ret

# =============================================================================
# PARSER
#
#   expr := term (('+'|'-') term)*
#   term := num  (('*'|'/') num)*
#   num  := ['-'] digitos ['.' digitos]
#
#   Convencion:
#     - parse_expr recibe a0 = puntero inicial
#     - El puntero actual vive en parse_ptr (memoria)
#     - Todos los registros usados son a0-a7, t0-t6 (caller-saved)
#     - fa0 = resultado float
# =============================================================================
parse_expr:
    addi sp, sp, -8
    sw   ra, 0(sp)

    la   t0, parse_ptr
    sw   a0, 0(t0)

    jal  parse_term

    la   t1, parse_status
    lw   t1, 0(t1)
    bne  t1, zero, pe_error

    fmv.x.w t0, fa0
    sw   t0, 4(sp)               # acumulador en pila

pe_loop:
    la   t1, parse_ptr
    lw   a0, 0(t1)
    lw   t1, 0(a0)
    andi t1, t1, 0xFF
    li   t2, 0x2B                # '+'
    beq  t1, t2, pe_op_add
    li   t2, 0x2D                # '-'
    beq  t1, t2, pe_op_sub
    j    pe_end

pe_op_add:
    la   t1, parse_ptr
    lw   a0, 0(t1)
    addi a0, a0, 4
    sw   a0, 0(t1)

    jal  parse_term

    la   t1, parse_status
    lw   t1, 0(t1)
    bne  t1, zero, pe_error

    lw   t0, 4(sp)
    fmv.w.x ft0, t0
    fadd.s  ft0, ft0, fa0

    # Valor absoluto del resultado
    fmv.x.w t0, ft0
    lui    t1, 0x80000
    xor    t0, t0, t1
    fmv.w.x ft1, t0

    # ¿|resultado| > 2147483647?
    la     t1, const_max
    flw    ft2, 0(t1)
    flt.s  t2, ft2, ft1
    bne    t2, zero, pe_error

    fmv.x.w t0, ft0
    sw   t0, 4(sp)
    j    pe_loop

pe_op_sub:
    la   t1, parse_ptr
    lw   a0, 0(t1)
    addi a0, a0, 4
    sw   a0, 0(t1)

    jal  parse_term

    la   t1, parse_status
    lw   t1, 0(t1)
    bne  t1, zero, pe_error

    lw   t0, 4(sp)
    fmv.w.x ft0, t0
    fsub.s  ft0, ft0, fa0

    # Valor absoluto del resultado
    fmv.x.w t0, ft0
    lui    t1, 0x80000
    xor    t0, t0, t1
    fmv.w.x ft1, t0

    # ¿|resultado| > 2147483647?
    la     t1, const_max
    flw    ft2, 0(t1)
    flt.s  t2, ft2, ft1
    bne    t2, zero, pe_error

    fmv.x.w t0, ft0
    sw   t0, 4(sp)
    j    pe_loop

pe_error:
    lw   ra, 0(sp)
    addi sp, sp, 8
    jr   ra

pe_end:
    lw   t0, 4(sp)
    fmv.w.x fa0, t0
    lw   ra, 0(sp)
    addi sp, sp, 8
    jr   ra

# -----------------------------------------------------------------------------
# parse_term
# -----------------------------------------------------------------------------
parse_term:
    addi sp, sp, -8
    sw   ra, 0(sp)

    jal  parse_num

    la   t1, parse_status
    lw   t1, 0(t1)
    bne  t1, zero, pt_error

    fmv.x.w t0, fa0
    sw   t0, 4(sp)

pt_loop:
    la   t1, parse_ptr
    lw   a0, 0(t1)
    lw   t1, 0(a0)
    andi t1, t1, 0xFF
    li   t2, 0x2A                # '*'
    beq  t1, t2, pt_op_mul
    li   t2, 0x2F                # '/'
    beq  t1, t2, pt_op_div
    j    pt_end

pt_op_mul:
    la   t1, parse_ptr
    lw   a0, 0(t1)
    addi a0, a0, 4
    sw   a0, 0(t1)

    jal  parse_num
    lw   t0, 4(sp)
    fmv.w.x ft0, t0
    fmul.s  ft0, ft0, fa0

    # Obtener valor absoluto de ft0
    fmv.x.w t0, ft0
    lui   t1, 0x80000
    xor   t0, t0, t1
    fmv.w.x ft1, t0

    # ft1 > 2147483647.0 ?
    la    t1, const_max
    flw   ft2, 0(t1)
    flt.s t2, ft2, ft1
    bne   t2, zero, pt_error

    # Guardar resultado
    fmv.x.w t0, ft0
    sw   t0, 4(sp)
    j    pt_loop

pt_op_div:
    la   t1, parse_ptr
    lw   a0, 0(t1)
    addi a0, a0, 4
    sw   a0, 0(t1)

    jal  parse_num

    # ¿El divisor ya tenía error?
    la   t1, parse_status
    lw   t1, 0(t1)
    bne  t1, zero, pt_error

    # ¿División entre cero?
    fmv.x.w t1, fa0
    beq   t1, zero, pt_div_zero

    lw   t0, 4(sp)
    fmv.w.x ft0, t0
    fdiv.s  ft0, ft0, fa0

    # Obtener valor absoluto del resultado
    fmv.x.w t0, ft0
    lui    t1, 0x80000
    xor    t0, t0, t1
    fmv.w.x ft1, t0

    # ¿|resultado| > 2147483647?
    la     t1, const_max
    flw    ft2, 0(t1)
    flt.s  t2, ft2, ft1
    bne    t2, zero, pt_error

    fmv.x.w t0, ft0
    sw   t0, 4(sp)
    j    pt_loop

pt_error:
    lw   ra, 0(sp)
    addi sp, sp, 8
    jr   ra

pt_div_zero:
    li   t1, 2
    la   t0, parse_status
    sw   t1, 0(t0)

    lw   ra, 0(sp)
    addi sp, sp, 8
    jr   ra

pt_end:
    lw   t0, 4(sp)
    fmv.w.x fa0, t0
    lw   ra, 0(sp)
    addi sp, sp, 8
    jr   ra

parse_num:
    la   t0, parse_ptr
    lw   a0, 0(t0)

    # saltar espacios
pn_skip:
    lw   t1, 0(a0)
    andi t1, t1, 0xFF
    li   t2, 0x20
    bne  t1, t2, pn_sign
    addi a0, a0, 4
    j    pn_skip

pn_sign:
    li   t3, 0                   # signo: 0=+, 1=-
    li   t2, 0x2D
    bne  t1, t2, pn_nosign
    li   t3, 1
    addi a0, a0, 4
pn_nosign:

    # parte entera
    li   t4, 0
pn_int_loop:
    lw   t1, 0(a0)
    andi t1, t1, 0xFF
    li   t2, 48
    blt  t1, t2, pn_int_done
    li   t2, 57
    blt  t2, t1, pn_int_done

    # t2 = dígito actual (0..9)
    addi t2, t1, -48

    # Verificar si t4 * 10 + dígito > 2147483647
    li   t5, 214748364
    blt  t5, t4, pn_overflow

    bne  t5, t4, pn_int_build

    # t4 == 214748364
    # Solo se permite un último dígito <= 7
    li   t5, 7
    blt  t5, t2, pn_overflow

pn_int_build:
    # t4 = t4 * 10
    add  t5, t4, t4
    add  t6, t5, t5
    add  t6, t6, t6
    add  t4, t6, t5

    # t4 = t4 + dígito
    add  t4, t4, t2

    addi a0, a0, 4
    j    pn_int_loop

pn_overflow:
    li   t5, 1
    la   t6, parse_status
    sw   t5, 0(t6)

    jr   ra


pn_int_done:
    fcvt.s.w fa0, t4

    # parte fraccionaria
    lw   t1, 0(a0)
    andi t1, t1, 0xFF
    li   t2, 0x2E
    bne  t1, t2, pn_sign_apply
    addi a0, a0, 4

    li   t4, 0
    li   t5, 0
pn_frac_loop:
    lw   t1, 0(a0)
    andi t1, t1, 0xFF
    li   t2, 48
    blt  t1, t2, pn_frac_done
    li   t2, 57
    blt  t2, t1, pn_frac_done
    add  t2, t4, t4
    add  t6, t2, t2
    add  t6, t6, t6
    add  t4, t6, t2
    addi t2, t1, -48
    add  t4, t4, t2
    addi a0, a0, 4
    addi t5, t5, 1
    j    pn_frac_loop
pn_frac_done:
    fcvt.s.w ft0, t4
    li   t4, 1
    add  t6, zero, t5
pn_pow_loop:
    beq  t6, zero, pn_pow_done
    add  t2, t4, t4
    add  t1, t2, t2
    add  t1, t1, t1
    add  t4, t1, t2
    addi t6, t6, -1
    j    pn_pow_loop
pn_pow_done:
    fcvt.s.w ft1, t4
    fdiv.s   ft0, ft0, ft1
    fadd.s   fa0, fa0, ft0

pn_sign_apply:
    beq  t3, zero, pn_save
    lui  t0, 0x80000
    fmv.x.w t1, fa0
    xor  t1, t1, t0
    fmv.w.x fa0, t1
pn_save:
    la   t0, parse_ptr
    sw   a0, 0(t0)
    jr   ra

# =============================================================================
# CONVERSIONES
# =============================================================================

# -----------------------------------------------------------------------------
# float2Bcd
#   Entrada: fa0 = float, a1 = &bcd_out
#   Layout de salida:
#       [0]      signo ASCII
#       [1..10]  10 dígitos enteros (crudos)
#       [11]     '.' (0x2E)
#       [12..16] 5 decimales (crudos)
#       [17]     0xB terminador
# -----------------------------------------------------------------------------
float2Bcd:
    addi sp, sp, -12
    sw   ra, 0(sp)
    sw   a1, 4(sp)
    sw   s0, 8(sp)

    # signo ASCII
    fmv.x.w t0, fa0
    li   t2, 0x2D
    blt  t0, zero, 1f
    li   t2, 0x2B
1:
    sw   t2, 0(a1)

    # |fa0|
    lui  t1, 0x80000
    addi t1, t1, -1
    and  t0, t0, t1
    fmv.w.x fa0, t0

    # parte entera -> [1..10]
    fcvt.w.s t3, fa0, rtz
    add  s0, zero, t3

    lw   a1, 4(sp)
    addi a0, a1, 4
    add  a1, zero, s0
    addi a2, zero, 10
    jal  ra, bin2Bcd

    # '.' en [11]
    lw   a1, 4(sp)
    li   t0, 0x2E
    sw   t0, 44(a1)

    # fracción -> [12..16]
    fcvt.s.w ft0, s0
    fsub.s   ft1, fa0, ft0
    la   t0, const_100
    lw   t1, 0(t0)
    fmv.w.x ft2, t1
    fmul.s   ft3, ft1, ft2
    fcvt.w.s t6, ft3, rtz
    lw   a1, 4(sp)
    addi a0, a1, 48
    add  a1, zero, t6
    addi a2, zero, 5
    jal  ra, bin2Bcd

    # terminador 0xB en [17]
    lw   a1, 4(sp)
    addi t0, zero, 0xB
    sw   t0, 68(a1)

    lw   ra, 0(sp)
    lw   s0, 8(sp)
    addi sp, sp, 12
    jr   ra

# -----------------------------------------------------------------------------
# bin2Bcd
#   Entrada: a0 = destino, a1 = entero NO negativo, a2 = 10 o 5
# -----------------------------------------------------------------------------
bin2Bcd:
    lui  t3, %hi(DIVISOR)
    addi t3, t3, %lo(DIVISOR)
    li   t6, 5
    bne  a2, t6, bcd_div_ok
    addi t3, t3, 20              # &DIVISOR[5] = 10000
bcd_div_ok:
    add  t0, a2, zero
    lui  t4, 0x80000
bcd_loop:
    beq  t0, zero, bcd_done
    add  t1, zero, zero
    lw   t2, 0(t3)
bcd_sub_loop:
    xor  t5, a1, t4
    xor  t6, t2, t4
    blt  t5, t6, bcd_store
    addi t1, t1, 1
    sub  a1, a1, t2
    j    bcd_sub_loop
bcd_store:
    sw   t1, 0(a0)
    addi a0, a0, 4
    addi t3, t3, 4
    addi t0, t0, -1
    j    bcd_loop
bcd_done:
    jr   ra

# -----------------------------------------------------------------------------
# bcd2Float
#   Entrada: a1 = &bcd_out
#   Salida:  fa0 = valor float
# -----------------------------------------------------------------------------
bcd2Float:
    addi sp, sp, -12
    sw   ra, 0(sp)
    sw   s0, 4(sp)
    sw   s1, 8(sp)

    # parte entera [1..10]
    addi t2, a1, 4
    li   s0, 0
    li   t3, 10
bf_int_loop:
    beq  t3, zero, bf_int_done
    lw   t4, 0(t2)
    andi t4, t4, 0xF
    add  t5, s0, s0
    add  t6, t5, t5
    add  t6, t6, t6
    add  s0, t6, t5
    add  s0, s0, t4
    addi t2, t2, 4
    addi t3, t3, -1
    j    bf_int_loop
bf_int_done:

    # decimales [12..16]
    addi t2, a1, 48
    li   s1, 0
    li   t3, 5
bf_frac_loop:
    beq  t3, zero, bf_frac_done
    lw   t4, 0(t2)
    andi t4, t4, 0xF
    add  t5, s1, s1
    add  t6, t5, t5
    add  t6, t6, t6
    add  s1, t6, t5
    add  s1, s1, t4
    addi t2, t2, 4
    addi t3, t3, -1
    j    bf_frac_loop
bf_frac_done:

    fcvt.s.w ft0, s0
    fcvt.s.w ft1, s1
    li   t0, 10
    fcvt.s.w ft2, t0
    li   t3, 5
bf_scale:
    beq  t3, zero, bf_scale_done
    fdiv.s ft1, ft1, ft2
    addi t3, t3, -1
    j    bf_scale
bf_scale_done:
    fadd.s fa0, ft0, ft1

    lw   t0, 0(a1)
    li   t1, 0x2D
    bne  t0, t1, bf_pos
    fmv.w.x ft0, zero
    fsub.s fa0, ft0, fa0
bf_pos:

    lw   ra, 0(sp)
    lw   s0, 4(sp)
    lw   s1, 8(sp)
    addi sp, sp, 12
    ret

# -----------------------------------------------------------------------------
# bcd2Ascii
#   Entrada: a0 = &bcd_out, a1 = &buffer_out
#   Salida:  escribe ASCII + terminador 0
# -----------------------------------------------------------------------------
bcd2Ascii:
    add  t0, a0, zero
    add  t1, a1, zero

    # signo [0]
    lw   t2, 0(t0)
    sw   t2, 0(t1)
    addi t0, t0, 4
    addi t1, t1, 4

    # 10 dígitos enteros [1..10], saltando ceros a la izquierda
    li   t3, 0
    li   t4, 10
bcd_ascii_int_loop:
    beq  t4, zero, bcd_ascii_int_done
    lw   t2, 0(t0)
    bne  t2, zero, bcd_ascii_print_digit
    beq  t3, zero, bcd_ascii_skip
bcd_ascii_print_digit:
    li   t3, 1
    addi t2, t2, 48
    sw   t2, 0(t1)
    addi t1, t1, 4
bcd_ascii_skip:
    addi t0, t0, 4
    addi t4, t4, -1
    j    bcd_ascii_int_loop
bcd_ascii_int_done:
    bne  t3, zero, bcd_ascii_dot
    li   t2, 0x30
    sw   t2, 0(t1)
    addi t1, t1, 4

bcd_ascii_dot:
    lw   t2, 0(t0)               # [11] = '.'
    sw   t2, 0(t1)
    addi t0, t0, 4
    addi t1, t1, 4

    li   t4, 5
bcd_ascii_frac_loop:
    beq  t4, zero, bcd_ascii_done
    lw   t2, 0(t0)
    addi t2, t2, 48
    sw   t2, 0(t1)
    addi t0, t0, 4
    addi t1, t1, 4
    addi t4, t4, -1
    j    bcd_ascii_frac_loop
bcd_ascii_done:
    sw   zero, 0(t1)
    jr   ra

# =============================================================================
# Datos
# =============================================================================
.data
buffer_in:      .space 1024
buffer_out:     .space 1024
bcd_out:        .space 84
parse_ptr:      .word 0
parse_status:   .word 0
last_float:     .word 0

# Resultados del banco: 1 = coincide, 0 = no coincide
test_results:   .space 160

# =============================================================================
# Casos de prueba
# =============================================================================
test_cases:
    .word t01, t02, t03, t04, t05, t06, t07, t08, t09, t10
    .word t11, t12, t13, t14, t15, t16, t17, t18, t19, t20
    .word t21, t22, t23, t24, t25, t26, t27, t28, t29, t30
    .word t31, t32, t33, t34, t35, t36, t37, t38, t39, t40
    .word 0

expected_cases:
    .word e01, e02, e03, e04, e05, e06, e07, e08, e09, e10
    .word e11, e12, e13, e14, e15, e16, e17, e18, e19, e20
    .word e21, e22, e23, e24, e25, e26, e27, e28, e29, e30
    .word e31, e32, e33, e34, e35, e36, e37, e38, e39, e40
    .word 0

# --- Suma ---
t01: .asciz "2147483647 + 1"
t02: .asciz "2147483647 - 1"
t03: .asciz "46340 * 46340"
t04: .asciz "2147483647 / 1"

# --- Resta ---
t05: .asciz "-2147483647 + -1"
t06: .asciz "1 - 2147483647"
t07: .asciz "-46340 * 46340"
t08: .asciz "-2147483647 / 1"

# --- Multiplicacion ---
t09: .asciz "0.8307526364 + 0.007823"
t10: .asciz "-2147483647 - -1"
t11: .asciz "-46340 * -46340"
t12: .asciz "2147483647 / -1"

# --- Division ---
t13: .asciz "2000000000 + 147483647"
t14: .asciz "-2000000000 - 147483647"
t15: .asciz "20000 * 100000"
t16: .asciz "-2147483647 / -1"

t17: .asciz "-2000000000 + 147483647"
t18: .asciz "2000000000 - -147483647"
t19: .asciz "2147.483647 * 1000"
t20: .asciz "2000000000 / 1000"

t21: .asciz "8726309.87 + 348274.1726"
t22: .asciz "8726309.87 - 348274.1726"
t23: .asciz "872.63 * -348.274"
t24: .asciz "8726309.87 / 348274.1726"

t25: .asciz "73000.87163 + 2839.38487654"
t26: .asciz "73000.87163 - -2839.38487654"
t27: .asciz "73000.87163 * 0.001"
t28: .asciz "73000.87163 / -2839.38487654"

t29: .asciz "876.2183746473 + 764.27"
t30: .asciz "-876.2183746473 - 764.27"
t31: .asciz "-876.21837 * 0.76427"
t32: .asciz "0.8307526364 / 0.007823"

t33: .asciz "123.45 + -67.89"
t34: .asciz "0.8307526364 - 0.007823"
t35: .asciz "0.8307526364 * 0.007823"
t36: .asciz "0.0000037278 / 67.000000765"

t37: .asciz "0.0000037278 + 67.000000765"
t38: .asciz "0.0000037278 - 67.000000765"
t39: .asciz ".0000037278 * 67.000000765"
t40: .asciz "1 / 100000"

# --- Esperados con formato de bcd2Ascii: signo + 5 decimales ---
e01: .asciz "+2147483648.00000"
e02: .asciz "+2147483646.00000"
e03: .asciz "+2147395600.00000"
e04: .asciz "+2147483647.00000"

e05: .asciz "-2147483648.00000"
e06: .asciz "-2147483646.00000"
e07: .asciz "-2147395600.00000"
e08: .asciz "-2147483647.00000"

e09: .asciz "+0.83857"
e10: .asciz "-2147483646.00000"
e11: .asciz "+2147395600.00000"
e12: .asciz "-2147483647.00000"

e13: .asciz "+2147483647.00000"
e14: .asciz "-2147483647.00000"
e15: .asciz "+2000000000.00000"
e16: .asciz "+2147483647.00000"

e17: .asciz "-1852516353.00000"
e18: .asciz "+2147483647.00000"
e19: .asciz "+2147483.64700"
e20: .asciz "+2000000.00000"

e21: .asciz "+9074584.04260"
e22: .asciz "+8378035.69740"
e23: .asciz "-303914.34062"
e24: .asciz "+25.05586"

e25: .asciz "+75840.25650"
e26: .asciz "+75840.25650"
e27: .asciz "+73.00087"
e28: .asciz "-25.71010"

e29: .asciz "+1640.48837"
e30: .asciz "-1640.48837"
e31: .asciz "-669.66741"
e32: .asciz "+106.19361"

e33: .asciz "+55.56000"
e34: .asciz "+0.82292"
e35: .asciz "+0.00649"
e36: .asciz "+0.00000"

e37: .asciz "+67.00000"
e38: .asciz "-66.99999"
e39: .asciz "+0.00024"
e40: .asciz "+0.00001"

DIVISOR:
    .word 1000000000, 100000000, 10000000, 1000000, 100000
    .word 10000, 1000, 100, 10, 1

const_100: .float 100000
const_max: .float 2147483647.0