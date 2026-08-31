.data
DIVISOR:
    .word 1000000000, 100000000, 10000000, 1000000, 100000
    .word 10000, 1000, 100, 10, 1
NUMS:
    .word 0, 4, 12, 548, 1589, 23741, 64279, 213400, 2396205
    .word 57192836, 912348577, 1285633993, -1, -31, -343, -1784
    .word -45795, -123456, -3458678, -23134529, -2147483648
BCD_NUMS:
    .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4
    .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2
    .word 0, 0, 0, 0, 0, 0, 0, 0, 5, 4, 8
    .word 0, 0, 0, 0, 0, 0, 0, 1, 5, 8, 9
    .word 0, 0, 0, 0, 0, 0, 2, 3, 7, 4, 1
    .word 0, 0, 0, 0, 0, 0, 6, 4, 2, 7, 9
    .word 0, 0, 0, 0, 0, 2, 1, 3, 4, 0, 0
    .word 0, 0, 0, 0, 2, 3, 9, 6, 2, 0, 5
    .word 0, 0, 0, 5, 7, 1, 9, 2, 8, 3, 6
    .word 0, 0, 9, 1, 2, 3, 4, 8, 5, 7, 7
    .word 0, 1, 2, 8, 5, 6, 3, 3, 9, 9, 3
    .word 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
    .word 1, 0, 0, 0, 0, 0, 0, 0, 0, 3, 1
    .word 1, 0, 0, 0, 0, 0, 0, 0, 3, 4, 3
    .word 1, 0, 0, 0, 0, 0, 0, 1, 7, 8, 4
    .word 1, 0, 0, 0, 0, 0, 4, 5, 7, 9, 5
    .word 1, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6
    .word 1, 0, 0, 0, 3, 4, 5, 8, 6, 7, 8
    .word 1, 0, 0, 2, 3, 1, 3, 4, 5, 2, 9
    .word 1, 2, 1, 4, 7, 4, 8, 3, 6, 4, 8

.bss
DIGITS: .space 44
TEST_RESULT: .space 84

.text
.global _start

# This file is just to rewrite everything in algorithm.c
# Obviously using the RV32I instructions available in the processor
_start:
    lui sp, 0x1000
    lui s2, %hi(DIGITS)         # digits pointer high
    addi s2, s2, %lo(DIGITS)    # digits pointer low
    addi s3, zero, 11           # digits length
    addi s4, zero, 21           # nums size

    lui s0, %hi(NUMS)           # nums pointer high
    addi s0, s0, %lo(NUMS)      # nums pointer low

    lui s6, %hi(BCD_NUMS)         # bcd_nums pointer high
    addi s6, s6, %lo(BCD_NUMS)    # bcd_nums pointer low
    
    lui s7, %hi(TEST_RESULT)      # test_result pointer high
    addi s7, s7, %lo(TEST_RESULT) # test_result pointer low

    add s5, zero, zero          # Loop index main
    # Function calls
    1:
        lw s1, 0(s0)
        add a0, s2, zero
        add a1, s1, zero
        add a2, s3, zero

        jal ra, bin2Bcd

        add t0, zero, zero
        add t2, s2, zero

        sw zero, 0(s7)
        2:
            lw t5, 0(t2)
            lw t6, 0(s6)
            sub t1, t5, t6
            bne t1, zero, set_error
            3:
                addi s6, s6, 4
                addi t2, t2, 4
                addi t0, t0, 1
                blt t0, s3, 2b

        addi s7, s7, 4

        addi s5, s5, 1
        addi s0, s0, 4
        blt s5, s4, 1b

    jal zero, done

set_error:
    addi t4, zero, 1
    sw t4, 0(s7)
    j 3b


# bin2Bcd, this is the function that makes the conversion
# a0: digits pointer
# a1: num
# a2: digits length
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

done:
    jal zero, done
