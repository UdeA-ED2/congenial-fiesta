# =========================================================
#  test_instrucciones.s
#
#  Instrucciones ACTIVAS:
#    add, addi, sub, and, or, andi, ori,
#    slt, slti, lw, sw, jal, beq, bne, blt, bge,
#    jalr, xor, xori, auipc, lui
# =========================================================

.data
    resultados: .space 96          # 24 words
    scratch:    .word 0            # variable auxiliar para lw/sw

.text
.globl main

main:
    la    s0, resultados           # s0 = base del arreglo de resultados

    # -----------------------------------------------------
    #  [0] ADD -> rd = rs1 + rs2
    # -----------------------------------------------------
    li    t0, 100
    li    t1, 250
    add   t2, t0, t1               # 350
    sw    t2, 0(s0)

    # -----------------------------------------------------
    #  [1] ADDI -> rd = rs1 + imm
    # -----------------------------------------------------
    li    t0, 100
    addi  t2, t0, -50              # 50
    sw    t2, 4(s0)

    # -----------------------------------------------------
    #  [2] SUB -> rd = rs1 - rs2
    # -----------------------------------------------------
    li    t0, 250
    li    t1, 100
    sub   t2, t0, t1               # 150
    sw    t2, 8(s0)

    # -----------------------------------------------------
    #  [3] AND -> bit a bit
    # -----------------------------------------------------
    li    t0, 0xFF00FF00
    li    t1, 0x0FF00FF0
    and   t2, t0, t1               # 0x0F000F00
    sw    t2, 12(s0)

    # -----------------------------------------------------
    #  [4] OR -> bit a bit
    # -----------------------------------------------------
    li    t0, 0x00FF00FF
    li    t1, 0xFF00FF00
    or    t2, t0, t1               # 0xFFFFFFFF
    sw    t2, 16(s0)

    # -----------------------------------------------------
    #  [5] ANDI -> bit a bit con inmediato
    # -----------------------------------------------------
    li    t0, 0xFF00FF00
    andi  t2, t0, 0x0FF            # 0x00000000
    sw    t2, 20(s0)

    # -----------------------------------------------------
    #  [6] ORI -> bit a bit con inmediato
    # -----------------------------------------------------
    li    t0, 0x00FF00FF
    ori   t2, t0, 0x0F0            # 0x00FF00FF
    sw    t2, 24(s0)

    # -----------------------------------------------------
    #  [7] SLT -> rd = (rs1 < rs2) ? 1 : 0   (con signo)
    # -----------------------------------------------------
    li    t0, -1
    li    t1,  1
    slt   t2, t0, t1               # 1
    sw    t2, 28(s0)

    # -----------------------------------------------------
    #  [8] SLTI -> rd = (rs1 < imm) ? 1 : 0
    # -----------------------------------------------------
    li    t0, 5
    slti  t2, t0, 10               # 1
    sw    t2, 32(s0)

    # -----------------------------------------------------
    #  [9] SW -> store word
    #     Guardamos y despues leemos con LW para verificar.
    #     Si el valor leido coincide, SW funciono.
    # -----------------------------------------------------
    li    t0, 0xCAFEBABE
    la    t1, scratch
    sw    t0, 0(t1)                # guardar
    lw    t2, 0(t1)                # leer para verificar
    sw    t2, 36(s0)               # = 0xCAFEBABE si SW ok

    # -----------------------------------------------------
    #  [10] LW -> load word
    #     Precargamos la variable y la traemos con LW.
    # -----------------------------------------------------
    li    t0, 0x12345678
    la    t1, scratch
    sw    t0, 0(t1)                # pre-cargar
    lw    t2, 0(t1)                # cargar con LW
    sw    t2, 40(s0)               # = 0x12345678 si LW ok

    # -----------------------------------------------------
    #  [11] JAL -> saltar y guardar direccion de retorno
    # -----------------------------------------------------
    jal   ra, subrutina_jal
    sw    a1, 44(s0)               # = valor devuelto por subrutina (0xABCD)

    # -----------------------------------------------------
    #  [12] BEQ -> branch if equal
    # -----------------------------------------------------
    li    t0, 5
    li    t1, 5
    li    t2, 0
    beq   t0, t1, beq_ok           # como t0==t1, salta
    li    t2, -1                   # NO deberia ejecutarse
beq_ok:
    sw    t2, 48(s0)               # = 0 si BEQ salto bien

    # -----------------------------------------------------
    #  [13] BNE -> branch if not equal
    # -----------------------------------------------------
    li    t0, 5
    li    t1, 6
    li    t2, 0
    bne   t0, t1, bne_ok           # como t0!=t1, salta
    li    t2, -1                   # NO deberia ejecutarse
bne_ok:
    sw    t2, 52(s0)               # = 0 si BNE salto bien

    # -----------------------------------------------------
    #  [14] BLT
    # -----------------------------------------------------
    li    t0, -1
    li    t1,  1
    li    t2, 8
    blt   t0, t1, blt_ok
    li    t2, -1
    blt_ok:
    sw    t2, 56(s0)             # = 0 si BLT salto bien

    # -----------------------------------------------------
    #  [15] BGE
    # -----------------------------------------------------
    li    t0, 5
    li    t1, 5
    li    t2, 14
    bge   t0, t1, bge_ok
    li    t2, -1
    bge_ok:
    sw    t2, 60(s0)             # = 0 si BGE salto bien

    # -----------------------------------------------------
    #  [16] JALR -> salto indirecto via registro
    # -----------------------------------------------------
    la    t0, destino_jalr
    jalr  ra, 0(t0)                # PC = t0, ra = dir. de retorno
    j     continuar                # (no deberia pasar por aca)

destino_jalr:
    li    t2, 0xBEEF               # marca de exito
    sw    t2, 64(s0)               # = 0xBEEF si JALR ok

continuar:

    # -----------------------------------------------------
    #  [17] XOR -> bit a bit
    # -----------------------------------------------------
    li    t0, 0xF0F0F0F0
    li    t1, 0x0FF00FF0
    xor   t2, t0, t1               # 0xFF00FF00
    sw    t2, 68(s0)

    # -----------------------------------------------------
    #  [18] XORI -> bit a bit con inmediato
    # -----------------------------------------------------
    li    t0, 0x000000FF
    xori  t2, t0, 0x0F0            # 0x0000000F
    sw    t2, 72(s0)

    # -----------------------------------------------------
    #  [19] AUIPC -> rd = PC + (imm << 12)
    # -----------------------------------------------------
    auipc t2, 0                    # t2 = direccion de esta instruccion
    sw    t2, 76(s0)

    # -----------------------------------------------------
    #  [20] LUI -> rd = imm << 12
    # -----------------------------------------------------
    lui   t2, 0x12345              # 0x12345000
    sw    t2, 80(s0)

    # -----------------------------------------------------
    # Fin
    # -----------------------------------------------------
    j done

done:
    j done

# =========================================================
# Subrutina llamada por JAL
# =========================================================
subrutina_jal:
    li    a1, 0xABCD               # valor a devolver
    jr    ra                       # retorno (alias de jalr x0, 0(ra))
