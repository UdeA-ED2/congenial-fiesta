.global _start
_start:
main:
  addi sp, zero, 0x400 # inicializar el stack en 0x400
# Bucle principal. Lee y muestra caracter en UART
read:
  jal ReadUART
  la t0, OchoMil
  lw t0, 0(t0) # Carga 0x8000 para verificar entrada dato
  and t0, t0, a0
  beq t0, zero, NOchar
  and t0, a0, 0xFF
  add s1, zero, t0
  addi t1, zero, 0x7f # Del Char
  bne t0, t1, cont
  jal DELChar
  j NOchar
cont:
  add a0, zero, s1
  jal WriteUART
NOchar:
  j read
WriteUART: # recibe en a0 caracter a escribir
  la t0, WriteAddrUART
  lw t0, 0(t0) # Carga en t0 direccion UART
  sw a0, 0(t0)
  jr ra
ReadUART: # retorna en a0 caracter entrado
  la t0, ReadAddrUART
  lw t0, 0(t0) # Carga en t0 direccion UART
  lw a0, 0(t0)
  jr ra
DELChar: # borra un caracter de la pantalla
  addi sp, sp, -4
  sw ra, 0(sp) # Push ra
  addi a0, zero, 0x8 # caracter retroceso
  jal WriteUART
  addi a0, zero, 0x20 # caracter espacio en blanco
  jal WriteUART
  addi a0, zero, 0x8 # caracter retroceso
  jal WriteUART
  lw ra, 0(sp) # Pop ra
  addi sp, sp, 4
  jr ra
  
.data
OchoMil: .word 0x8000
ReadAddrUART: .dc.l 0xff201000
WriteAddrUART: .dc.l 0xff201000