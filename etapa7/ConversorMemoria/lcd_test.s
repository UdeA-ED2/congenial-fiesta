.global _start
_start:
    lui t0, 0xFF200            # t0 = 0xFF200000 (base I/O)

    # ---------- Linea 1: "HOLA" ----------
    lui   t1, 0x484F5          # 0x484F5000
    addi  t1, t1, -0x3BF       #   - 0x3BF = 0x484F4C41
    sw    t1, 0xC0(t0)         # 0xFF2000C0 -> line1[159:128]

    # ---------- Linea 2: "MUND" ----------
    lui   t1, 0x4D555
    addi  t1, t1, -0x1BC       # 0x4D554E44
    sw    t1, 0xD4(t0)         # 0xFF2000D4 -> line2[159:128]

    # ---------- Linea 3: "PRUE" ----------
    lui   t1, 0x50525
    addi  t1, t1, 0x545        # 0x50525545
    sw    t1, 0xE8(t0)         # 0xFF2000E8 -> line3[159:128]

    # ---------- Linea 4: "FUNC" ----------
    lui   t1, 0x46555
    addi  t1, t1, -0x1BD       # 0x46554E43
    sw    t1, 0xFC(t0)         # 0xFF2000FC -> line4[159:128]

    # --- señal visual en LEDs: "llegue hasta aqui" ---
    li  t2, 0x155              # patron 01 0101 0101 en 10 bits
    sw  t2, 0x000(t0)          # enciende LEDs alternados

done:
    j done
