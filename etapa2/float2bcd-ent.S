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
