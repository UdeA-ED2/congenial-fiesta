.data

float_prueba: .float 123.45678

DIVISOR:
    .word 1000000000, 100000000, 10000000, 1000000, 100000
    .word 10000, 1000, 100, 10, 1

# ============================================================
# ARREGLO DE SALIDA BCD (palabras)
# Formato: [signo][11 dígitos enteros][punto][5 decimales]
# Posiciones: 0 + 11 + 1 + 5 = 18 palabras
# Reservamos 20 por margen
# ============================================================
bcd_out:        .space 84        # 21 palabras * 4 bytes

# ============================================================
# BUFFER TEMPORAL PARA PARTE FRACCIONARIA
# (la parte entera la escribe bin2Bcd directo en bcd_out)
# ============================================================
buf_frac:       .space 84        # 21 palabras

# ============================================================
# CONSTANTES FLOTANTES (se cargan con lw + fmv.w.x)
# ============================================================
const_10:       .float 10.0      # multiplicar fracción por 10

# ============================================================
# CONSTANTES ENTERAS / CARACTERES
# ============================================================
const_signo_pos: .word 0xC       # signo positivo
const_signo_neg: .word 0xD       # signo negativo
const_punto:     .word 0x2E      # punto decimal '.'

.text

main:
    la   t0, float_prueba
    lw   t1, 0(t0)
    fmv.w.x fa0, t1

    la   a1, bcd_out
    jal  ra, float2bcd

fin:
    j fin

# ============================================================
# FUNCIÓN: bin2Bcd 
# Entrada: a0 = puntero al arreglo destino
#          a1 = número entero a convertir
#          a2 = cantidad de dígitos (11)
# Salida:  escribe 11 palabras en [a0]
# ============================================================

 bin2Bcd:
    # t0: Loop index i
    # t1: first for the sign, then the digit
    # t3: DIVISOR pointer
    # t2: DIVISOR[i]
    add t0, zero, zero # i = 0

    # First Loop
    1:
        sw zero, 0(a0)
        addi a0, a0, 4
        addi t0, t0, 1
        blt t0, a2, 1b

    add t0, zero, zero
    addi a0, a0, -44
    # addi a0, a0, 0xFD4

    bge a1, zero, 2f    # If number is positive, then jump
    sub a1, zero, a1    # Turn into positive number
    addi t1, zero, 1    # Sign of num is negative
    sw t1, 0(a0)        # Store a 1 in digits[0]
    2:
        addi a0, a0, 4  # Move to digits[1]
        addi t0, zero, 1    # i = 1
        lui t3, %hi(DIVISOR)
        addi t3, t3, %lo(DIVISOR)
        lui t4, 0x80000

    3:
        bge t0, a2, return_bin2Bcd  # from i = 1 until 11
        add t1, zero, zero
        lw t2, 0(t3)
    5:
        # Bit Magic (Makes negative numbers be under positive ones)
        xor t5, a1, t4  # t5 = num ^ sign_bit
        xor t6, t2, t4  # t6 = divisor ^ sign_bit

        # bltu a1, t2, 4f # if num < divisor, jump, but using unsigned instruction
        blt t5, t6, 4f  # if num < divisor (unsigned), jump
        addi t1, t1, 1
        sub a1, a1, t2
        j 5b            # j 5b = jal zero, 5b
    4:
        sw t1, 0(a0)    # digits[i] = t1
        addi t0, t0, 1  # i += 1
        addi a0, a0, 4  # Match i in digits[i]
        addi t3, t3, 4  # Next divisor
        j 3b

return_bin2Bcd:
    jr ra

# ============================================================
# FUNCIÓN: float2bcd
# Entrada: fa0 = float a convertir
#          a1  = dirección de bcd_out
# Salida:  escribe BCD en bcd_out
# Formato: [0]=signo, [1..11]=entero, [12]=0 relleno,
#          [13]=punto, [14..18]=5 decimales
# ============================================================
float2bcd:
    addi sp, sp, -16
    sw   ra, 0(sp)
    sw   a1, 4(sp)          # guardo &bcd_out
    sw   s0, 8(sp)          # guardo s0 (lo voy a usar)

    # ---------- 1. SIGNO ----------
    fmv.x.w t0, fa0         # t0 = bits crudos del float
    li   t2, 0xD            # asumimos negativo
    blt  t0, zero, 1f       # si t0 < 0, salta y deja 0xD
    li   t2, 0xC            # si llegó aquí, era positivo
1:
    sw   t2, 0(a1)          # bcd_out[0] = signo

    # ---------- 2. VALOR ABSOLUTO ----------
    lui  t1, 0x80000
    addi t1, t1, -1         # t1 = 0x7FFFFFFF
    and  t0, t0, t1         # borra bit 31
    fmv.w.x fa0, t0         # fa0 = |float|

    # ---------- 3. PARTE ENTERA ----------
    fcvt.w.s t3, fa0        # t3 = parte entera truncada
    add  s0, zero, t3       # s0 = parte entera (para usar después)

    # ---------- 4. LLAMAR bin2Bcd ----------
    lw   a1, 4(sp)          # recupero &bcd_out
    addi a0, a1, 4          # a0 = &bcd_out[1]
    add  a1, zero, s0       # a1 = entero
    addi a2, zero, 12       # a2 = 12 dígitos
    jal  ra, bin2Bcd

    # ---------- 5. ESCRIBIR PUNTO ----------
    lw   a1, 4(sp)          # recupero &bcd_out
    li   t0, 0x2E           # punto decimal (uso t0 en vez de t7)
    sw   t0, 52(a1)        # bcd_out[13] = 0x2E

    # ---------- 6. CALCULAR FRACCIÓN ----------
    fcvt.s.w ft0, s0        # ft0 = parte_entera como float
    fsub.s   ft1, fa0, ft0  # ft1 = fracción

    # ---------- 7. CARGAR 10.0 ----------
    la   t0, const_10
    lw   t1, 0(t0)
    fmv.w.x ft2, t1         # ft2 = 10.0

    # ---------- 8. LOOP 5 DECIMALES ----------
    addi t4, a1, 56         # &bcd_out[14]
    addi t5, zero, 5        # contador = 5

loop_frac:
    fmul.s  ft1, ft1, ft2   # frac *= 10
    #fcvt.w.s t6, ft1        # t6 = dígito (truncado)
    fcvt.w.s t6, ft1, rtz
    sw      t6, 0(t4)       # bcd_out[14+i] = dígito
    fcvt.s.w ft3, t6        # ft3 = dígito como float
    fsub.s  ft1, ft1, ft3   # frac -= dígito
    addi    t4, t4, 4       # siguiente posición
    addi    t5, t5, -1      # contador--
    bne     t5, zero, loop_frac

    addi t0, zero, 0xB
    sw t0, 80(a1)          # bcd_out[20] = 0xB (fin de cadena)

    # ---------- 9. EPÍLOGO ----------
    lw   ra, 0(sp)
    lw   s0, 8(sp)
    addi sp, sp, 16
    jr   ra














# ============================================================
# FUNCIÓN: float2bcd
# Entrada: fa0 = float a convertir
#          a1  = dirección de bcd_out
# Salida:  escribe BCD en bcd_out
# Formato: [0]=signo, [1..11]=entero, [12]=punto, [13..17]=decimales
# ============================================================

float2bcd:
    addi sp, sp, -8
    sw   ra, 0(sp)
    sw   a1, 4(sp)          # guardo &bcd_out

    # ---------- 1. SIGNO ----------
    fmv.x.w t0, fa0
    li   t2, 0xD            # asumimos negativo
    blt  t0, zero, 1f       # si negativo, salta y deja 0xD
    li   t2, 0xC            # si llegó aquí, era positivo
1:
    sw   t2, 0(a1)          # bcd_out[0] = signo

    # ---------- 2. VALOR ABSOLUTO ----------
    lui  t1, 0x80000
    addi t1, t1, -1         # t1 = 0x7FFFFFFF
    and  t0, t0, t1         # borra bit 31
    fmv.w.x fa0, t0         # fa0 = |float|

    # ---------- 3. PARTE ENTERA ----------
    fcvt.w.s t3, fa0        # t3 = parte entera truncada

    # ---------- 4. LLAMAR bin2Bcd ----------
    lw   a1, 4(sp)          # recupero &bcd_out
    addi a0, a1, 4          # a0 = &bcd_out[1]
    add  a1, zero, t3       # a1 = entero
    addi a2, zero, 11       # a2 = 11 dígitos
    jal  ra, bin2Bcd

        # ---------- 5. ESCRIBIR PUNTO ----------
    lw   a1, 4(sp)          # recupero &bcd_out
    la   t0, const_punto
    lw   t7, 0(t0)
    sw   t7, 48(a1)         # bcd_out[12] = 0x2E

    # ---------- 6. CALCULAR FRACCIÓN ----------
    fcvt.s.w ft0, t3        # ft0 = parte_entera como float
    fsub.s   ft1, fa0, ft0  # ft1 = fracción

    # ---------- 7. CARGAR 10.0 ----------
    la   t0, const_10
    lw   t1, 0(t0)
    fmv.w.x ft2, t1         # ft2 = 10.0

    # ---------- 8. LOOP 5 DECIMALES ----------
    addi t4, a1, 52         # &bcd_out[13]
    addi t5, zero, 5

loop_frac:
    fmul.s  ft1, ft1, ft2
    fcvt.w.s t6, ft1
    sw      t6, 0(t4)
    fcvt.s.w ft3, t6
    fsub.s  ft1, ft1, ft3
    addi    t4, t4, 4
    addi    t5, t5, -1
    bne     t5, zero, loop_frac

    # ---------- 5. (PENDIENTE) PUNTO Y FRACCIÓN ----------
    # Aquí irá la Parte 3

    lw   ra, 0(sp)
    addi sp, sp, 8
    jr   ra