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
_start:
main:
    lui  sp, 0x10
    la   s0, buffer_in
    add  s1, zero, s0
    la   t0, buffer_out
    sw   zero, 0(t0)


# =============================================================================
# Loop principal
# =============================================================================
read:
    jal  ReadUART
    la   t0, MASK_DATO
    lw   t0, 0(t0)
    and  t0, t0, a0
    beq  t0, zero, read
    andi t0, a0, 0xFF

    addi t1, zero, 0x7F
    beq  t0, t1, do_del
    addi t1, zero, 0x0D
    beq  t0, t1, do_enter
    addi t1, zero, 0x0A
    beq  t0, t1, do_enter
    addi t1, zero, 0x3D          # '='
    beq  t0, t1, do_calcular
    addi t1, zero, 0x6D          # 'm'
    beq  t0, t1, do_mostrar_out
    addi t1, zero, 0x63          # 'c'
    beq  t0, t1, do_clear
    addi t1, zero, 0x74          # 't' = toggle modo
    beq  t0, t1, do_toggle_mode

    sw   t0, 0(s1)
    addi s1, s1, 4
    add  a0, zero, t0
    jal  WriteUART
    j    read

# =============================================================================
# Teclas especiales
# =============================================================================
do_del:
    beq  s1, s0, read
    addi s1, s1, -4
    jal  DELChar
    j    read

do_enter:
    sw   zero, 0(s1)
    addi a0, zero, 0x0D
    jal  WriteUART
    addi a0, zero, 0x0A
    jal  WriteUART
    la   a0, buffer_in
    jal  PrintBuffer
    add  s1, zero, s0
    j    read

do_clear:
    add  s1, zero, s0
    sw   zero, 0(s0)
    addi a0, zero, 0x0D
    jal  WriteUART
    addi a0, zero, 0x0A
    jal  WriteUART
    j    read

do_toggle_mode:
    la   t0, test_mode
    lw   t1, 0(t0)
    xori t1, t1, 1
    sw   t1, 0(t0)

    la   t0, test_index
    sw   zero, 0(t0)

    addi a0, zero, 0x0D
    jal  WriteUART
    addi a0, zero, 0x0A
    jal  WriteUART
    li   a0, 'm'
    jal  WriteUART
    li   a0, 'o'
    jal  WriteUART
    li   a0, 'd'
    jal  WriteUART
    li   a0, 'o'
    jal  WriteUART
    li   a0, '='
    jal  WriteUART

    la   t0, test_mode
    lw   t1, 0(t0)
    beq  t1, zero, modo_manual_msg
    li   a0, '1'
    jal  WriteUART
    j    modo_msg_done
modo_manual_msg:
    li   a0, '0'
    jal  WriteUART
modo_msg_done:
    addi a0, zero, 0x0D
    jal  WriteUART
    addi a0, zero, 0x0A
    jal  WriteUART
    j    read

#pruebas:
load_test:
    la   t0, buffer_in

load_test_loop:
    lbu  t1, 0(a0)
    beq  t1, zero, load_test_done

    sw   t1, 0(t0)

    addi a0, a0, 1
    addi t0, t0, 4
    j    load_test_loop

load_test_done:
    sw   zero, 0(t0)
    jr   ra    

# =============================================================================
# '=' CALCULAR
# =============================================================================
do_calcular:

# ¿Modo manual o auto?
    la   t0, test_mode
    lw   t0, 0(t0)
    beq  t0, zero, do_calcular_manual

    #Modo auto:
    sw   zero, 0(s1)

    la   t0, test_index
    lw   t1, 0(t0)

    la   t2, test_list

    add  t3, t1, t1
    add  t3, t3, t3

    add  t2, t2, t3
    lw   a0, 0(t2)

    jal  load_test

    la   a0, buffer_in
    lw   t0, 0(a0)
    beq  t0, zero, calc_fin

    la   t0, parse_status
    sw   zero, 0(t0)   

    jal  parse_expr              # fa0 = resultado (float)

    la   t0, parse_status
    lw   t1, 0(t0)

    li   t2, 1
    beq  t1, t2, calc_inf

    li   t2, 2
    beq  t1, t2, calc_error

    # float -> BCD
    la   a1, bcd_out
    jal  float2Bcd

    # BCD -> float (round-trip)
    la   a1, bcd_out
    jal  bcd2Float               # fa0 = float leído del BCD
    la   t0, last_float
    fmv.x.w t1, fa0
    sw   t1, 0(t0)

    # BCD -> ASCII
    la   a0, bcd_out
    la   a1, buffer_out
    jal  bcd2Ascii

    addi a0, zero, 0x0D
    jal  WriteUART
    addi a0, zero, 0x0A
    jal  WriteUART
    la   a0, buffer_out
    jal  PrintBuffer
    addi a0, zero, 0x0D
    jal  WriteUART
    addi a0, zero, 0x0A
    jal  WriteUART

    j    calc_fin 

do_calcular_manual:

    sw   zero, 0(s1)  
    la   a0, buffer_in
    lw   t0, 0(a0)
    beq  t0, zero, calc_fin

    la   t0, parse_status
    sw   zero, 0(t0)   

    jal  parse_expr              # fa0 = resultado (float)

    la   t0, parse_status
    lw   t1, 0(t0)

    li   t2, 1
    beq  t1, t2, calc_inf

    li   t2, 2
    beq  t1, t2, calc_error

    # float -> BCD
    la   a1, bcd_out
    jal  float2Bcd

    # BCD -> float (round-trip)
    la   a1, bcd_out
    jal  bcd2Float               # fa0 = float leído del BCD
    la   t0, last_float
    fmv.x.w t1, fa0
    sw   t1, 0(t0)

    # BCD -> ASCII
    la   a0, bcd_out
    la   a1, buffer_out
    jal  bcd2Ascii

    addi a0, zero, 0x0D
    jal  WriteUART
    addi a0, zero, 0x0A
    jal  WriteUART
    la   a0, buffer_out
    jal  PrintBuffer
    addi a0, zero, 0x0D
    jal  WriteUART
    addi a0, zero, 0x0A
    jal  WriteUART

    j    calc_fin 


calc_inf:
    li   a0, 0x0D
    jal  WriteUART
    li   a0, 0x0A
    jal  WriteUART

    li   a0, 'i'
    jal  WriteUART
    li   a0, 'n'
    jal  WriteUART
    li   a0, 'f'
    jal  WriteUART

    j    calc_fin

calc_error:
    li   a0, 0x0D
    jal  WriteUART
    li   a0, 0x0A
    jal  WriteUART

    li   a0, 'e'
    jal  WriteUART
    li   a0, 'r'
    jal  WriteUART
    li   a0, 'r'
    jal  WriteUART
    li   a0, 'o'
    jal  WriteUART
    li   a0, 'r'
    jal  WriteUART

    j    calc_fin


calc_fin:
    la   t0, test_mode
    lw   t0, 0(t0)
    beq  t0, zero, calc_fin_manual

    # --- AUTO: siguiente prueba ---
    la   t0, test_index
    lw   t1, 0(t0)
    addi t1, t1, 1
    li   t2, 40
    bge  t1, t2, tests_done
    sw   t1, 0(t0)
    add  s1, zero, s0
    sw   zero, 0(s0)
    j    read

calc_fin_manual:
    add  s1, zero, s0
    sw   zero, 0(s0)
    j    read

tests_done:
    sw   zero, 0(t0)
    add  s1, zero, s0
    sw   zero, 0(s0)
    j    read


do_mostrar_out:
    addi a0, zero, 0x0D
    jal  WriteUART
    addi a0, zero, 0x0A
    jal  WriteUART
    la   a0, buffer_out
    jal  PrintBuffer
    addi a0, zero, 0x0D
    jal  WriteUART
    addi a0, zero, 0x0A
    jal  WriteUART
    j    read

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
# Helpers UART
# =============================================================================
WriteUART:
    la   t0, WriteAddrUART
    lw   t0, 0(t0)
    sw   a0, 0(t0)
    jr   ra

ReadUART:
    la   t0, ReadAddrUART
    lw   t0, 0(t0)
    lw   a0, 0(t0)
    jr   ra

DELChar:
    addi sp, sp, -4
    sw   ra, 0(sp)
    addi a0, zero, 0x08
    jal  WriteUART
    addi a0, zero, 0x20
    jal  WriteUART
    addi a0, zero, 0x08
    jal  WriteUART
    lw   ra, 0(sp)
    addi sp, sp, 4
    jr   ra

PrintBuffer:
    addi sp, sp, -4
    sw   ra, 0(sp)
    add  t2, zero, a0
print_loop:
    lw   t3, 0(t2)
    beq  t3, zero, print_done
    andi a0, t3, 0xFF
    jal  WriteUART
    addi t2, t2, 4
    j    print_loop
print_done:
    lw   ra, 0(sp)
    addi sp, sp, 4
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
parse_status:    .word 0
last_float:     .word 0
MASK_DATO:      .word 0x8000
ReadAddrUART:   .word 0xff201000
WriteAddrUART:  .word 0xff201000

msg_inf:  .word 105, 110, 102, 0          
msg_error:  .word 101, 114, 114, 111, 114, 0

DIVISOR:
    .word 1000000000, 100000000, 10000000, 1000000, 100000
    .word 10000, 1000, 100, 10, 1

const_100:       .float 100000
const_max: .float 2147483647.0

#Sumas
test1:  .asciz "2147483647+0="
test2:  .asciz "2000000000+147483647="
test3:  .asciz "2000000000+147483648="
test4:  .asciz "-2000000000+-147483647="
test5:  .asciz "-2000000000+-147483648="
test6:  .asciz "8726309.87+348274.1726="
test7:  .asciz "73000.87163+2839.38487654="
test8:  .asciz "123.45+-67.89="
test9:  .asciz "0.8307526364+0.007823="
test10: .asciz "0.0000037278+67.000000765="

#Restas
test11: .asciz "2147483647-1="
test12: .asciz "1-2147483647="
test13: .asciz "-2147483647--1="
test14: .asciz "-2000000000-147483647="
test15: .asciz "2000000000--147483647="
test16: .asciz "8726309.87-348274.1726="
test17: .asciz "73000.87163--2839.38487654="
test18: .asciz "-876.2183746473-764.27="
test19: .asciz "0.8307526364-0.007823="
test20: .asciz "0.0000037278-67.000000765="

#Multiplicaciones
test21: .asciz "46340*46340="
test22: .asciz "-46340*46340="
test23: .asciz "-46340*-46340="
test24: .asciz "20000*100000="
test25: .asciz "2147.483647*1000="
test26: .asciz "872.63*-348.274="
test27: .asciz "73000.87163*0.001="
test28: .asciz "-876.21837*0.76427="
test29: .asciz "0.8307526364*0.007823="
test30: .asciz "2000000000*2="

#Divisiones
test31: .asciz "2147483647/1="
test32: .asciz "-2147483647/1="
test33: .asciz "2147483647/-1="
test34: .asciz "-2147483647/-1="
test35: .asciz "2000000000/1000="
test36: .asciz "8726309.87/348274.1726="
test37: .asciz "73000.87163/-2839.38487654="
test38: .asciz "0.8307526364/0.007823="
test39: .asciz "0.0000037278/67.000000765="
test40: .asciz "1/100000="

.align 2
test_list:
    .word test1, test2, test3, test4, test5
    .word test6, test7, test8, test9, test10
    .word test11, test12, test13, test14, test15
    .word test16, test17, test18, test19, test20
    .word test21, test22, test23, test24, test25
    .word test26, test27, test28, test29, test30
    .word test31, test32, test33, test34, test35
    .word test36, test37, test38, test39, test40

test_index:    .word 0    #Contador pruebas
test_mode:     .word 1    #cambiar modo de pruebas (1 = auto, 0 = manual)