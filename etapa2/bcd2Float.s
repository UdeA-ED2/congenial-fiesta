# ============================================================================
# bcd2Float_tester.s
# 
# ============================================================================

.data

# ----------------------------------------------------------------------------
# BCD
# Format: [sign (0xC = positive, 0xD = negative)] [digits (0-9) or dot (0x2E)] ... [0xB]
# ----------------------------------------------------------------------------
    seq1:   .word 0xC, 1, 2, 3, 4, 5, 0xB
    seq2:   .word 0xD, 9, 8, 7, 6, 5, 0xB
    seq3:   .word 0xC, 1, 2, 0x2E, 3, 4, 0xB
    seq4:   .word 0xD, 5, 6, 0x2E, 7, 8, 0xB
    seq5:   .word 0xC, 0, 0, 1, 2, 0x2E, 3, 4, 5, 0xB
    seq6:   .word 0xD, 1, 2, 0x2E, 3, 4, 0, 0, 0xB
    seq7:   .word 0xC, 7, 0xB
    seq8:   .word 0xD, 3, 0xB
    seq9:   .word 0xC, 0x2E, 5, 6, 7, 0xB
    seq10:  .word 0xD, 0x2E, 1, 2, 3, 0xB
    seq11:  .word 0xC, 0, 0xB
    seq12:  .word 0xD, 0, 0xB
    seq13:  .word 0xC, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 0xB
    seq14:  .word 0xD, 1, 2, 3, 4, 5, 0x2E, 6, 7, 8, 9, 0xB
    seq15:  .word 0xC, 1, 0x2E, 2, 3, 4, 5, 6, 7, 8, 9, 0xB
    seq16:  .word 0xC, 1, 0, 0, 0, 0, 0, 0, 0x2E, 0, 6, 0xB

    test_cases:
        .word seq1,  7
        .word seq2,  7
        .word seq3,  7
        .word seq4,  7
        .word seq5,  10
        .word seq6,  9
        .word seq7,  3
        .word seq8,  3
        .word seq9,  6
        .word seq10, 6
        .word seq11, 3
        .word seq12, 3
        .word seq13, 12
        .word seq14, 12
        .word seq15, 12
        .word seq16, 12

    final_float:
        .word 0x4640E400   # seq1: +12345
        .word 0xC7C0E680   # seq2: -98765
        .word 0x414570A4   # seq3: +12.34
        .word 0xC2631EB8   # seq4: -56.78
        .word 0x4145851F   # seq5: +12.345
        .word 0xC14570A4   # seq6: -12.34
        .word 0x40E00000   # seq7: +7
        .word 0xC0400000   # seq8: -3
        .word 0x3F1126E9   # seq9: +0.567
        .word 0xBDFBE76D   # seq10: -0.123
        .word 0x00000000   # seq11: +0
        .word 0x80000000   # seq12: -0
        .word 0x4E932C06   # seq13: +1234567890
        .word 0xC640E6B7   # seq14: -12345.6789
        .word 0x3F9E0652   # seq15: +1.23456789
        .word 0x49742401   # seq16: +1000000.06

.equ NUM_TESTS, 16

.align 4
bcd2float_out:
    .space NUM_TESTS * 4

bcd2float_results:
    .space NUM_TESTS * 4

.text
.global _start

_start:
    # Stack pointer 
    lui sp, 0x8000

    # Load test cases and results table
    la   s0, test_cases
    la   s1, bcd2float_out
    li   s2, NUM_TESTS
    li   s3, 0
    la   s4, bcd2float_results

test_loop:
    # Load BCD and it's size
    lw   a1, 0(s0)
    lw   a2, 4(s0)          # Size

    jal  ra, bcd2Float

    # Store result
    fsw  fa0, 0(s1)

    # Go to next case
    addi s0, s0, 8           # Each entry is 8 bytes (ptr + size)
    addi s1, s1, 4           # Each result is 4 bytes
    addi s3, s3, 1
    blt  s3, s2, test_loop

    # Compare obtained floats with expected values
    la   s0, bcd2float_out   # obtained
    la   s1, final_float     # expected
    la   s4, bcd2float_results # status (0/1)
    li   s2, NUM_TESTS
    li   s3, 0

compare_loop:
    flw  ft0, 0(s0)          # obtained float
    flw  ft1, 0(s1)          # expected float
    feq.s t0, ft0, ft1       # t0 = 1 if equal, 0 if different
    xori t0, t0, 1           # invert: 1 -> 0 (OK), 0 -> 1 (ERROR)
    sw   t0, 0(s4)           # store status

    addi s0, s0, 4
    addi s1, s1, 4
    addi s4, s4, 4
    addi s3, s3, 1
    blt  s3, s2, compare_loop

done:
    j done

bcd2Float:
    # fa0: final float
    # a1: BCD
    # a2: BCD size
    #
    # Find dot and store position
    addi t0, a1, 4      # After the sign
    addi t2, zero, 0x2E # The char of a dot ('.') in ascii is a 46 in base 10 and that in hex
    addi t3, zero, 0xB  # Final numero (Yeah, perdonen, kamehameha)
    add t4, zero, zero  # dotPosition
    1:
        lw t1, 0(t0)

        beq t1, t2, bcd2Float_dot
        beq t1, t3, bcd2Float_int

        addi t4, t4, 1
        addi t0, t0, 4
        j 1b

# Includes the dot
bcd2Float_dot:
    mv t6, t0
    addi t0, a1, 4  # Again, after the sign
    
    addi sp, sp, -16
    sw a1,  0(sp)
    sw ra,  4(sp)
    sw t4,  8(sp)
    sw t6, 12(sp)

    mv a0, t0
    mv a1, t4

    jal ra, bcd2Int
    
    lw a1,  0(sp)
    lw ra,  4(sp)
    lw t4,  8(sp)
    lw t6, 12(sp)
    addi sp, sp, 16

    addi t6, t6, 4
    sub t5, a2, t4
    addi t5, t5, -3

    addi sp, sp, -24
    sw a1,  0(sp)
    sw ra,  4(sp)
    sw t4,  8(sp)
    sw a0, 12(sp)
    sw t6, 16(sp)
    sw t5, 20(sp)

    mv a0, t6
    mv a1, t5

    jal ra, bcd2Int
    
    lw a1,  0(sp)
    lw ra,  4(sp)
    lw t0,  8(sp)
    lw t3, 12(sp)
    lw t6, 16(sp)
    lw t5, 20(sp)
    addi sp, sp, 24

    fcvt.s.w ft0, t3    # Before the dot int->float
    fcvt.s.w ft1, a0    # After the dot int->float (not scaled)

    add t1, t5, zero
    addi t3, zero, 10
    fcvt.s.w ft2, t3
    beq t1, zero, 3f
    2:
        fdiv.s ft1, ft1, ft2
        addi t1, t1, -1
        bne t1, zero, 2b
        
    3:
        fadd.s fa0, ft0, ft1
    # If sign says it's negative then it's a negative
    li t0, 0xD
    lw t1, 0(a1)
    bne t1, t0, 1f
    fsgnjn.s fa0, fa0, fa0  # Turn into a negative
    # That is the same as: fneg.s rd, rs
    1:
        ret


# No dot, just integer
bcd2Float_int:
    addi t0, a1, 4  # Again, after the sign

    # Storing relevant data
    addi sp, sp, -8
    sw a1, 0(sp)
    sw ra, 4(sp)

    mv a0, t0
    mv a1, t4
    jal ra, bcd2Int 

    lw a1, 0(sp)
    lw ra, 4(sp)
    addi sp, sp, 8

    fcvt.s.w fa0, a0
    li t0, 0xD
    lw t1, 0(a1)
    # If sign says it's negative
    bne t1, t0, 1f
    fsgnjn.s fa0, fa0, fa0  # Turn into a negative
    # That is the same as: fneg.s rd, rs
    1:
        ret


bcd2Int:
    mv    t1, a0          # t1 = current pointer
    mv    t2, a1          # t2 = loop counter
    li    t0, 0           # t0 = result accumulator

    1:
        beq t2, zero, 2f    # if counter == 0, exit

        lw t3, 0(t1)
        andi t3, t3, 0xF    # mask to extract the digit (0-9)

        add t4, t0, t0      # t4 = result * 2
        add t5, t4, t4      # t5 = result * 4
        add t6, t5, t5      # t6 = result * 8
        add t0, t6, t4      # t0 = result * 10

        add t0, t0, t3      # add the current digit

        addi t1, t1, 4      # advance to next word
        addi t2, t2, -1     # decrement counter
        j 1b

    2:
        mv a0, t0
        ret 
