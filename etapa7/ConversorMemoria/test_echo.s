.global _start
_start:
	

# ==========================================
# PRUEBA DE TECLADO Y ECO EN LCD
# Procesador RISC-V
# ==========================================

# Direccion base de los perifericos
    lui t0, 0xFF200


# ESPERAR UNA TECLA

esperar:
    lw t1, 128(t0)          # Leer FLAG y tecla
	
	andi t4, t1, 0x10
    bne t4, zero, esperar     # Si FLAG=0, seguir esperando
    # beq t4, zero, esperar

# LEER EL CODIGO DE LA TECLA
    andi t2, t1, 0xF        # Conservar los 4 bits

# CONVERTIR EL CODIGO A ASCII
    li t3, 10
    blt t2, t3, es_numero   # Si es menor que 10, es numero

es_letra:
    addi t2, t2, 55         # Convertir A-F
    j enviar_lcd

es_numero:
    addi t2, t2, 48         # Convertir 0-9


# ENVIAR EL CARACTER A LA LCD
enviar_lcd:
    sw t2, 0xC0(t0)          # Escribir ASCII en LCD


# ESPERAR QUE SUELTEN LA TECLA
esperar_soltar:
    lw t1, 128(t0)          # Leer FLAG nuevamente
	andi t3, t1, 0x10
    bne t3, zero, esperar_soltar
    # beq t1, zero, esperar_soltar

    j esperar               # Buscar otra tecla


