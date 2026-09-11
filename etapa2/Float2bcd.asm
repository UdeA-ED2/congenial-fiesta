.data
float_val:
    .word 0x43D9CCCD     # 435.8 en IEEE-754
BCD:
    .space 16

.text
.global _start

_start:
    # Cargar el float desde memoria
    la a0, float_val     # a0 = dirección de float_val
    lw a0, 0(a0)         # a0 = 0x43D9CCCD ✅
    
    # Dirección destino
    la a1, BCD           # a1 = dirección de BCD
    
    # LLAMAR A LA FUNCIÓN
    jal ra, float2Bcd

fin:
    jal zero, fin

# ==================================================
# FLOAT -> BCD
# ==================================================
float2Bcd:

    addi sp, sp, -4
    sw ra, 0(sp)
    
    # EXTRAER SIGNO (bit 31)

    lui t0, 0x80000
    and t1, a0, t0        # t1 = signo
    
    # EXTRAER EXPONENTE (bits 30-23)

    lui t0, 0x7F800
    and t2, a0, t0        # t2 = exponente con bias

    # Restar 127 al exponente
    lui t0, 0x3F800       # t0 = 0x3F800000 (127 << 23)
    sub t2, t2, t0        # t2 = exponente real
    
    # EXTRAER FRACCIÓN (bits 22-0)

    lui t0, 0x00800       # t0 = 0x00800000
    addi t0, t0, -1       # t0 = 0x007FFFFF (máscara de 23 bits)
    and t3, a0, t0        # t3 = fracción (bits 22-0)
    

    # Agregar bit implícito (USANDO OR ENTRE REGISTROS)
    lui t4, 0x800        # t4 = 0x00800000
    or t3, t3, t4        # t3 = t3 | t4 (mantisa completa)


    # CALCULAR PARTE ENTERA
    
    # 1. Extraer el exponente real

    # t2 = 0x04000000 (8 << 23)
    #contar cuántas veces cabe 0x800000 en t2
    
    li t5, 0              # t5 = exponente (empieza en 0)
    li t6, 0x800000       # t6 = 1 << 23 (8388608)
    
extraer_exp:
    blt t2, t6, fin_ext   # Si t2 < 0x800000, salir
    sub t2, t2, t6        # Restar 0x800000
    addi t5, t5, 1        # exponente + 1
    j extraer_exp
fin_ext:
    # t5 = 8 (exponente real)
    
    # --------------------------------------------
    # 2. Calcular desplazamiento = 23 - exponente
    # --------------------------------------------
    li t6, 23
    sub t6, t6, t5        # t6 = 15
    
    # --------------------------------------------
    # 3. Calcular 2^desplazamiento
    # --------------------------------------------
    li t4, 1              # divisor = 1
    li s5, 0              # contador = 0
    
calc_div:
    beq s5, t6, fin_div    # Si contador == desplazamiento, salir
    add t4, t4, t4         # divisor = divisor * 2
    addi s5, s5, 1         # contador + 1
    j calc_div
fin_div:
    # t4 = 32768 (2^15)
    
    # --------------------------------------------
    # 4. Dividir mantisa entre divisor
    # --------------------------------------------
    # t3 = 0x00D9CCCD (mantisa completa)
    li t5, 0              # t5 = parte entera
    
dividir:
    blt t3, t4, fin_divis  # Si mantisa < divisor, salir
    sub t3, t3, t4         # mantisa = mantisa - divisor
    addi t5, t5, 1         # parte_entera + 1
    j dividir
fin_divis:

    # t5 = PARTE ENTERA = 435
    # t3 = RESIDUO
    # Ahora sacar 5 dígitos decimales

    # Guardar parte entera en BCD
    sw t5, 0(a1)

    # a1 apunta ahora al siguiente espacio de BCD
    addi a1, a1, 4

    # t6 = contador de decimales
    li t6, 0

decimal_loop:

    # --------------------------------------------
    # 1. residuo = residuo * 10
    # --------------------------------------------
    # t0 = 2 * residuo
    add t0, t3, t3

    # t4 = 4 * residuo
    add t4, t0, t0

    # t4 = 8 * residuo
    add t4, t4, t4

    # t0 = 10 * residuo
    add t0, t4, t0


    # --------------------------------------------
    # 2. Dividir (residuo * 10) entre 32768
    # --------------------------------------------
    # t4 = 32768 = 2^15
    # t5 = dígito decimal

    li t5, 0

division_decimal:

    blt t0, t4, fin_division_decimal

    sub t0, t0, t4

    addi t5, t5, 1

    j division_decimal


fin_division_decimal:

    # --------------------------------------------
    # 3. Guardar el dígito decimal en BCD
    # --------------------------------------------
    sw t5, 0(a1)

    # --------------------------------------------
    # 4. El nuevo residuo queda en t0
    # --------------------------------------------
    add t3, t0, zero

    # siguiente posición BCD
    addi a1, a1, 4

    # contador++
    addi t6, t6, 1

    # ¿Ya tenemos 5 decimales?
    li t0, 5
    blt t6, t0, decimal_loop

    # FIN

    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra


# BINARIO -> BCD 

bin2Bcd:

    DIVISOR:
    .word 1000000000, 100000000, 10000000, 1000000, 100000
    .word 10000, 1000, 100, 10, 1

    
    jr ra





.data

float_val:
    .word 0x43D9CCCD       # 435.8 aproximadamente

BCD:
    .space 32              # espacio para los dígitos


.text
.global _start

_start:

    # ============================================
    # CARGAR EL FLOAT
    # ============================================

    la a0, float_val
    lw a0, 0(a0)

    # a0 contiene los bits IEEE-754
    # 0x43D9CCCD


    # Dirección donde guardaremos BCD
    la a1, BCD

    jal ra, float2Bcd


fin:
    jal zero, fin


# ==================================================
# FLOAT -> BCD
# ==================================================

float2Bcd:

    addi sp, sp, -4
    sw ra, 0(sp)


    # ============================================
    # 1. OBTENER SIGNO
    # ============================================

    lui t0, 0x80000
    and t1, a0, t0

    # t1 = 0 si positivo
    # t1 = 0x80000000 si negativo


    # ============================================
    # 2. PASAR LOS BITS IEEE A FLOAT
    # ============================================

    fmv.w.x ft0, a0

    # ft0 ahora contiene 435.8


    # ============================================
    # 3. OBTENER PARTE ENTERA
    # ============================================

    fcvt.w.s t5, ft0, rtz

    # t5 = 435


    # Guardar 435 temporalmente
    sw t5, 0(a1)


    # ============================================
    # 4. CONVERTIR 435 OTRA VEZ A FLOAT
    # ============================================

    fcvt.s.w ft1, t5


    # ============================================
    # 5. OBTENER PARTE DECIMAL
    # ============================================

    fsub.s ft2, ft0, ft1

    # ft2 = 435.8 - 435
    # ft2 = 0.8


    # ============================================
    # 6. SACAR PRIMER DECIMAL
    # ============================================

    li t6, 10
    fcvt.s.w ft3, t6

    fmul.s ft2, ft2, ft3

    # ft2 = 0.8 * 10
    # ft2 = 8.0


    fcvt.w.s t5, ft2, rtz

    # t5 = 8

    addi a1, a1, 4
    sw t5, 0(a1)


    # ============================================
    # 7. QUITAR EL 8
    # ============================================

    fcvt.s.w ft3, t5

    fsub.s ft2, ft2, ft3

    # ft2 = 8.0 - 8
    # ft2 = 0.0


    # ============================================
    # 8. SEGUNDO DECIMAL
    # ============================================

    li t6, 10
    fcvt.s.w ft3, t6

    fmul.s ft2, ft2, ft3

    fcvt.w.s t5, ft2, rtz

    addi a1, a1, 4
    sw t5, 0(a1)


    # ============================================
    # 9. TERCER DECIMAL
    # ============================================

    fcvt.s.w ft3, t5
    fsub.s ft2, ft2, ft3

    li t6, 10
    fcvt.s.w ft3, t6

    fmul.s ft2, ft2, ft3

    fcvt.w.s t5, ft2, rtz

    addi a1, a1, 4
    sw t5, 0(a1)


    # ============================================
    # 10. CUARTO DECIMAL
    # ============================================

    fcvt.s.w ft3, t5
    fsub.s ft2, ft2, ft3

    li t6, 10
    fcvt.s.w ft3, t6

    fmul.s ft2, ft2, ft3

    fcvt.w.s t5, ft2, rtz

    addi a1, a1, 4
    sw t5, 0(a1)


    # ============================================
    # 11. QUINTO DECIMAL
    # ============================================

    fcvt.s.w ft3, t5
    fsub.s ft2, ft2, ft3

    li t6, 10
    fcvt.s.w ft3, t6

    fmul.s ft2, ft2, ft3

    fcvt.w.s t5, ft2, rtz

    addi a1, a1, 4
    sw t5, 0(a1)


    # ============================================
    # RETORNAR
    # ============================================

    lw ra, 0(sp)
    addi sp, sp, 4

    jr ra


#NUEVO:

.data

DIVISOR:
    .word 1000000000, 100000000, 10000000, 1000000, 100000
    .word 10000, 1000, 100, 10, 1

float_val:
    .word 0xC3D9CCCD #0x43D9CCCD       # 435.8 en IEEE-754

BCD:
    .space 64              # espacio para 6 palabras de 32 bits


.text
.global _start

_start:

    # Dirección del número float
    la a0, float_val
    lw a0, 0(a0)

    # Dirección donde vamos a guardar el BCD
    la a1, BCD

    # Entrar a la función
    jal ra, float2Bcd


fin:
    jal zero, fin


float2Bcd:

    addi sp, sp, -20
    sw s5, 0(sp)
    sw ra, 4(sp)

    add s5, a1, zero


    # SIGNO: bit 31
    lui t0, 0x80000
    and t1, a0, t0

    # Guardar signo en BCD
    #sw t1, 0(s5)
    sw t1, 8(sp)   #guardar temporalmente

    # EXPONENTE: bits 30..23
    lui t0, 0x7F800
    and t2, a0, t0

    # t6 = 2^23
    lui t6, 0x00800     # t6 = 0x00800000

    # t5 = contador
    addi t5, zero, 0

    extraer_exponente:
        blt t2, t6, fin_exponente
        sub t2, t2, t6
        addi t5, t5, 1
        jal zero, extraer_exponente

    fin_exponente:
        # t5 = exponente almacenado = 135

        addi t5, t5, -127
        # t5 = exponente real = 8          

        # FRACCION: bits 22..0
        lui t0, 0x007FF
        addi t0, t0, 2047
        addi t0, t0, 2047
        addi t0, t0, 1
        and t3, a0, t0

    # AGREGAR 1 IMPLÍCITO DE LA MANTISA
    lui t4, 0x00800
    or t3, t3, t4

    # CALCULAR 23 - E
    addi t6, zero, 23
    sub t6, t6, t5

    # CONSTRUIR 2^(23-E)

    addi t4, zero, 1      # t4 = 1
    addi t0, zero, 0      # contador = 0

    construir_2:
        beq t0, t6, fin_2
        add t4, t4, t4     # duplicar
        addi t0, t0, 1     # contador++
        jal zero, construir_2

    fin_2:

    # CALCULAR PARTE ENTERA

    addi t0, zero, 0       # contador = 0

    dividir_entero:
        blt t3, t4, fin_entero
        sub t3, t3, t4
        addi t0, t0, 1
        jal zero, dividir_entero

    fin_entero:

    #sw t0, 0(s5)

    # PRIMER DECIMAL

    # t3 tiene el residuo
    # t4 tiene 32768

    fin_entero:

    # Guardar lo que necesitamos para los decimales
    sw t3, 12(sp)       # residuo
    sw t4, 16(sp)      # 32768

    # Convertir 435 directamente en BCD
    add a0, s5, zero   # BCD
    add a1, t0, zero   # entero = 435
    addi a2, zero, 11
    jal ra, bin2Bcd

    # Recuperar estado para los decimales
    lw t3, 12(sp)
    lw t4, 16(sp)

    lw t1, 8(sp)
    sw t1, 0(s5)

# PRIMER DECIMAL

    # multiplicar residuo por 10
    add t0, t3, t3
    add t1, t0, t0
    add t1, t1, t1
    add t0, t1, t0

    # dividir entre 32768
    addi t1, zero, 0

    sacar_decimal:
        blt t0, t4, fin_decimal
        sub t0, t0, t4
        addi t1, t1, 1
        jal zero, sacar_decimal

    fin_decimal:

       sw t1, 44(s5)

    # SEGUNDO DECIMAL

    add t0, t0, t0      # 2t0
    add t2, t0, t0      # 4t0
    add t2, t2, t2      # 8t0
    add t0, t2, t0      # 10t0

    addi t1, zero, 0

    sacar_decimal2:
        blt t0, t4, fin_decimal2
        sub t0, t0, t4
        addi t1, t1, 1
        jal zero, sacar_decimal2

    fin_decimal2:

       sw t1, 48(s5)

    # TERCER DECIMAL

    add t0, t0, t0
    add t2, t0, t0
    add t2, t2, t2
    add t0, t2, t0

    addi t1, zero, 0

    sacar_decimal3:
        blt t0, t4, fin_decimal3
        sub t0, t0, t4
        addi t1, t1, 1
        jal zero, sacar_decimal3

    fin_decimal3:

       sw t1, 52(s5)

    # CUARTO DECIMAL

    add t0, t0, t0
    add t2, t0, t0
    add t2, t2, t2
    add t0, t2, t0

    addi t1, zero, 0

    sacar_decimal4:
        blt t0, t4, fin_decimal4
        sub t0, t0, t4
        addi t1, t1, 1
        jal zero, sacar_decimal4

    fin_decimal4:

       sw t1, 56(s5)

    # QUINTO DECIMAL

    add t0, t0, t0
    add t2, t0, t0
    add t2, t2, t2
    add t0, t2, t0

    addi t1, zero, 0

    sacar_decimal5:
        blt t0, t4, fin_decimal5
        sub t0, t0, t4
        addi t1, t1, 1
        jal zero, sacar_decimal5

    fin_decimal5:

       sw t1, 60(s5)

    #lw s5, 0(sp)
    #addi sp, sp, 4

    lw ra, 4(sp)
    lw s5, 0(sp)
    addi sp, sp, 20

    jr ra


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




#Nuevo con operaciones punto flotante
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
bcd_out:        .space 80        # 20 palabras * 4 bytes

# ============================================================
# BUFFER TEMPORAL PARA PARTE FRACCIONARIA
# (la parte entera la escribe bin2Bcd directo en bcd_out)
# ============================================================
buf_frac:       .space 80        # 20 palabras

# ============================================================
# CONSTANTES FLOTANTES (se cargan con lw + fmv.w.x)
# ============================================================
const_10:       .float 10.0      # multiplicar fracción por 10
const_100000:   .float 100000.0  # para 5 decimales (alternativa)

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
    #la   t0, const_punto
    #lw   t7, 0(t0)
    #sw   t7, 52(a1) 
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