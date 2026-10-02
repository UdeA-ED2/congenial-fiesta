# =========================================================
#  test_reducido.s
#
#  Pruebas reducidas: bne, blt, bge, jalr, xor, xori, auipc, lui
# =========================================================

.text
.globl main

main:
    la    s0, resultados           # s0 = base del arreglo de resultados

    # -----------------------------------------------------
    #  [0] BNE -> t0 != t1, debe saltar
    #      si salta, deja el marcador 0x11111111
    # -----------------------------------------------------
    li    t0, 5
    li    t1, 6
    li    t2, 0x11111111           # marcador de exito
    bne   t0, t1, bne_ok           # 5 != 6, debe saltar
    li    t2, -1                   # NO deberia ejecutarse
bne_ok:
    sw    t2, 0(s0)                # = 0x11111111 si BNE ok

    # -----------------------------------------------------
    #  [1] BLT -> t0 < t1 con signo (-1 < 1), debe saltar
    # -----------------------------------------------------
    li    t0, -1
    li    t1,  1
    li    t2, 0x22222222           # marcador de exito
    blt   t0, t1, blt_ok           # -1 < 1, debe saltar
    li    t2, -1                   # NO deberia ejecutarse
blt_ok:
    sw    t2, 4(s0)                # = 0x22222222 si BLT ok

    # -----------------------------------------------------
    #  [2] BGE -> t0 >= t1 (5 >= 5), debe saltar
    # -----------------------------------------------------
    li    t0, 5
    li    t1, 5
    li    t2, 0x33333333           # marcador de exito
    bge   t0, t1, bge_ok           # 5 >= 5, debe saltar
    li    t2, -1                   # NO deberia ejecutarse
bge_ok:
    sw    t2, 8(s0)                # = 0x33333333 si BGE ok

    # -----------------------------------------------------
    #  [3] JALR -> salto indirecto via registro
    #      guarda direccion de retorno en ra
    # -----------------------------------------------------
    la    t0, destino_jalr
    jalr  ra, 0(t0)                # PC = t0, ra = dir. de retorno
    j     continuar                # (no deberia pasar por aca)

destino_jalr:
    li    t2, 0x0000BEEF           # marcador de exito
    sw    t2, 12(s0)               # = 0xBEEF si JALR ok

continuar:

    # -----------------------------------------------------
    #  [4] XOR -> bit a bit
    # -----------------------------------------------------
    li    t0, 0xF0F0F0F0
    li    t1, 0x0FF00FF0
    xor   t2, t0, t1               # 0xFF00FF00
    sw    t2, 16(s0)               # = 0xFF00FF00 si XOR ok

    # -----------------------------------------------------
    #  [5] XORI -> bit a bit con inmediato
    # -----------------------------------------------------
    li    t0, 0x000000FF
    xori  t2, t0, 0x0F0            # 0x0000000F
    sw    t2, 20(s0)               # = 0x0000000F si XORI ok

    # -----------------------------------------------------
    #  [6] AUIPC -> rd = PC + (imm << 12)
    #      imm = 0, entonces rd = direccion de esta instruccion
    # -----------------------------------------------------
    auipc t2, 0
    sw    t2, 24(s0)               # = PC de esta instruccion

    # -----------------------------------------------------
    #  [7] LUI -> rd = imm << 12
    # -----------------------------------------------------
    lui   t2, 0x12345              # 0x12345000
    sw    t2, 28(s0)               # = 0x12345000 si LUI ok

    # -----------------------------------------------------
    #  Comprobando resultados y poniendolo en LEDs
    # -----------------------------------------------------
    la    s0, resultados
    la    s1, esperados
    li    s2, 0                # i (índice)
    li    s3, 8                # cantidad tests
    li    s4, 0                # mascara de LEDs
    li    s5, 1                # bit actual

document_results:
    lw    t3, 0(s0)                 # resultados[i]
    lw    t4, 0(s1)                 # esperados[i]
    bne   t3, t4, avanzar_results   # si son diferentes, no enciende LED
    or    s4, s4, s5                # LED[i] = 1

avanzar_results:
    addi  s0, s0, 4            # avanzar puntero
    addi  s1, s1, 4
    add   s5, s5, s5           # s5 = s5 << 1  (bit al siguiente LED)
    addi  s2, s2, 1            # i += 1
    blt   s2, s3, document_results  # Begin audio prompt in 3, 2, 1...

    # Escribir la máscara en los LEDs
    lui   t0, 0xFF200
    sw    s4, 0(t0)

    # -----------------------------------------------------
    # Fin: bucle infinito para que el CPU no se vaya a X
	#      como ya paso que no servia pa nada en la simulacion
    # -----------------------------------------------------
done:
    j done

# =========================================================
# Subrutina llamada por JALR
# =========================================================
subrutina_jalr:
    jr    ra

.data
    resultados: .space 32          # 8 words
    scratch:    .word 0            # variable auxiliar para lw/sw
    # leds:       .byte 0xFF200000   # puntero LEDS
    # switches:   .byte 0xFF200040   # puntero switches

    esperados:
        .word 0x11111111            # [0] BNE
        .word 0x22222222            # [1] BLT
        .word 0x33333333            # [2] BGE
        .word 0x0000BEEF            # [3] JALR
        .word 0xFF00FF00            # [4] XOR
        .word 0x0000000F            # [5] XORI
        .word 0x00000098            # [6] AUIPC
        .word 0x12345000            # [7] LUI
