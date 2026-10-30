# =========================================================
#  test_reducido.s
#
#  Pruebas punto flotante: fadd.s, fsub.s, fmul.s, fdiv.s,
#  		fcvt.s.w, fcvt.w.s, fmv.w.s, fmv.s.w
#  Finalmente las operaciones que desean realizar son:
#  a = (0.712*(4.61803 + 3.5794) - 27.821) / -1.4786;
#  Ademas mover y convertir
# =========================================================

.text
.globl main

main:
    la    s0, resultados           # s0 = base del arreglo de resultados

    # -----------------------------------------------------
    # INICIO PRUEBAS
    # -----------------------------------------------------
    li t0, 0x4093c6e7   # 4.61803
    fmv.w.x ft0, t0
    li t0, 0x406514e4   # 3.5794
    fmv.w.x ft1, t0

    # SUMA
    fadd.s fs0, ft0, ft1

    li t0, 0x3f3645a2   # 0.712
    fmv.w.x ft0, t0

    # PRODUCTO
    fmul.s fs1, fs0, ft0

    li t0, 0x41de9168   # 27.821
    fmv.w.x ft0, t0

    # RESTA
    fsub.s fs2, fs1, ft0

    li t0, 0xbfbd42c4   # -1.4786
    fmv.w.x ft0, t0

    # DIVISION
    fdiv.s fs3, fs2, ft0

    # MOVIMIENTOS
    # float -> int
    fmv.x.w t3, fs0
    # int -> float
    li t0, 0xBEEF     # 48879 == 0xbeef
    fmv.w.x fs4, t0

    # CONVERSIONES
    # int -> float
    li t0, 1278       # 1278 == 0x4fe
    fcvt.s.w fs4, t0

    # float -> int
    fcvt.w.s t4, fs1

    j done

    # -----------------------------------------------------
    #  FIN PRUEBAS
    #  Comprobando resultados y poniendolo en LEDs
    # -----------------------------------------------------
    la    s0, resultados
    la    s1, esperados
    li    s2, 0                # i (indice)
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
        .word 0x410328ac            # [0] fadd.s
        .word 0x40bac52f            # [1] fmul.s
        .word 0xc1afe01d            # [2] fsub.s
        .word 0x416de501            # [3] fdiv.s
        .word 0x410328ac            # [4] fmv.x.w
        .word 0x0000beef            # [5] fmv.w.x
        .word 0x449fc000            # [6] fcvt.s.w
        .word 0x0000000e            # [7] fcvt.w.s


    resultados: .space 32          # 8 words
