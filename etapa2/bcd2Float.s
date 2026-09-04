.text
.global _start

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
