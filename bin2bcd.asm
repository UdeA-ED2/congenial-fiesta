# Ejemplo: 548

# s0 = numero
# s1 = direccion de DIVISOR
# s2 = direccion de digits
# s3 = j
#
# t1 = j * 4
# t2 = direccion de DIVISOR[j]
# t3 = DIVISOR[j]
# t4 = direccion de digits[j]
# t5 = digits[j]


.data

DIVISOR:
    .word 1000000000
    .word 100000000
    .word 10000000
    .word 1000000
    .word 100000
    .word 10000
    .word 1000
    .word 100
    .word 10
    .word 1

digits:
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0
    .word 0

.text

main:

    # num = 548
    addi s0, zero, 548

    #Suponiendo direcciones:

    addi s1, zero, 100       # direccion DIVISOR
    addi s2, zero, 140       # direccion digits

    # j = 0
    addi s3, zero, 0


loop_j:

    # ¿j < 10?, para terminar 
    slti t0, s3, 10

    # Si j >= 10, terminar
    beq t0, zero, fin


    # t1 = j * 4, equivale a pasar a siguiente divisor
    add t1, s3, s3   
    add t1, t1, t1


    # t2 = direccion DIVISOR[j]
    add t2, s1, t1                  #suma a direccion original de div j*4 

    # t3 = DIVISOR[j]
    lw t3, 0(t2)


loop_resta:

    # ¿num < DIVISOR[j]?
    blt s0, t3, siguiente_j


    # t4 = direccion digits[j]
    add t4, s2, t1

    # t5 = digits[j]
    lw t5, 0(t4)

    # digits[j] = digits[j] + 1  # para pasar a siguiente div
    addi t5, t5, 1

    # Guardar digits[j]
    sw t5, 0(t4)

    # num = num - DIVISOR[j]
    sub s0, s0, t3

    # Repetir
    jal zero, loop_resta


siguiente_j:

    # j = j + 1
    addi s3, s3, 1

    # Volver al ciclo principal
    jal zero, loop_j


fin:

    # quedarse aquí
    jal zero, fin

