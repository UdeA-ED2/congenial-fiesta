.data
DIVISOR:
    .word 1000000000, 100000000, 10000000, 1000000, 100000
    .word 10000, 1000, 100, 10, 1

.text
.global main

# This file is just to rewrite everything in algorithm.c
# Obviously using the RV32I instructions available in the processor
main:
    addi s0, zero, 548
    li s1, -372
    
    addi sp, sp, -44    # Allocation for digits[11]
    add s2, zero, sp    # digits pointer
    addi s3, zero, 11   # digits length
    

    # Function call
    add a0, s2, zero
    addi a1, zero, 548
    add a2, s3, zero
    # addi a1, zero, 0xE8C
    jal ra, bin2Bcd

    addi sp, sp, 44     # Free memory
    jal zero, done

# bin2Bcd, this is the function that makes the conversion
# a0: digits pointer
# a1: num
# a2: digits length
bin2Bcd:
    # t0: Loop index i
    # t1: first for the sign, then the digit
    # a4: DIVISOR pointer
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
        lui a4, %hi(DIVISOR)
        addi a4, a4, %lo(DIVISOR)
        lui t4, 0x80000

    3:
        bge t0, a2, return_bin2Bcd  # from i = 1 until 11
        add t1, zero, zero
        lw t2, 0(a4)
    5:
        bltu a1, t2, 4f
        addi t1, t1, 1
        sub a1, a1, t2
        j 5b            # j 5b = jal zero, 5b
    4:
        sw t1, 0(a0)    # digits[i] = t1
        addi t0, t0, 1  # i += 1
        addi a0, a0, 4  # Match i in digits[i]
        addi a4, a4, 4  # Next divisor
        j 3b

return_bin2Bcd:
    jr ra

done:
    jal zero, done
