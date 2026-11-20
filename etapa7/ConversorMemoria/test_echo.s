.global _start
_start:
	

# ==========================================
# PRUEBA DE TECLADO Y ECO EN LCD
# Procesador RISC-V
# ==========================================

# Direccion base de los perifericos
    lui t0, 0xFF200


# 1. ESPERAR UNA TECLA

esperar:
    lw t1, 128(t0)          # Leer FLAG
    beq t1, zero, esperar   # Si FLAG=0, seguir esperando


# 2. LEER EL CODIGO DE LA TECLA

    lw t2, 132(t0)          # Leer TECLA (0-F)
    andi t2, t2, 0xF        # Conservar los 4 bits


# 3. CONVERTIR EL CODIGO A ASCII

    li t3, 10
    blt t2, t3, es_numero   # Si es menor que 10, es numero

es_letra:
    addi t2, t2, 55         # Convertir A-F
    j enviar_lcd

es_numero:
    addi t2, t2, 48         # Convertir 0-9


# 4. ENVIAR EL CARACTER A LA LCD

enviar_lcd:
    sw t2, 144(t0)          # Escribir ASCII en LCD


# 5. ESPERAR QUE SUELTEN LA TECLA

esperar_soltar:
    lw t1, 128(t0)          # Leer FLAG nuevamente
    bne t1, zero, esperar_soltar

    j esperar               # Buscar otra tecla

