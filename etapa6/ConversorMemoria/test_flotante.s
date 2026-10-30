# =========================================================
#  test_reducido.s
#
#  Pruebas punto flotante: fadd.s, fsub.s, fmul.s, fdiv.s,
#  		fcvt.s.w, fcvt.w.s, fmv.w.s, fmv.s.w
#  Finalmente las operaciones que desean realizar son:
#  a = (0.712*(4.61803 + 3.5794) - 27.821) / -1.4786;
#  b = (int) a;
#  c = (float) 9178135;
#  Ademas mover dos valores que aun no se cuales
# =========================================================

.text
.globl main

main:
    la    s0, resultados           # s0 = base del arreglo de resultados

    # -----------------------------------------------------
    # INICIO PRUEBAS
    # -----------------------------------------------------
    li t0, 0x4093c6e7   # 4.61803
    fmv.w.s ft0, t0
    li t0, 0x406514e4   # 3.5794
    fmv.w.s ft1, t0

    fadd.s fs0, ft0, ft1

    li t0, 0x3f3645a2   # 0.712
    fmv.w.s ft0, t0

    fmul.s fs1, fs0, ft0

    li t0, 0x41de9168   # 27.821
    fmv.w.s ft0, t0

    fsub.s fs2, fs1, ft0

    li t0, 0xbfbd42c4   # -1.4786
    fmv.w.s ft0, t0

    fdiv.s fs3, fs2, ft0

    # -----------------------------------------------------
    #  FIN PRUEBAS
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

    # Escribir la mascara en los LEDs
    lui   t0, 0xFF200
    sw    s4, 0(t0)

    # -----------------------------------------------------
    # Fin: bucle infinito para que el CPU no se vaya a X
	#      como ya paso que no servia pa nada en la simulacion
    # -----------------------------------------------------
done:
    j done

.data
    # leds:       .byte 0xFF200000   # puntero LEDS
    # switches:   .byte 0xFF200040   # puntero switches
    esperados:
        .word 0x00000000            # [0] fadd.s
        .word 0x00000000            # [1] fsub.s
        .word 0x00000000            # [2] fmul.s
        .word 0x00000000            # [3] fdiv.s
        .word 0x00000000            # [4] fcvt.w.s
        .word 0x00000000            # [5] fcvt.s.w
        .word 0x00000000            # [6] fmv.w.s
        .word 0x00000000            # [7] fmv.s.w

    resultados: .space 32          # 8 words
