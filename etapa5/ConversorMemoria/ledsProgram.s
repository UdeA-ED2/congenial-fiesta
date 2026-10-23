.global _start
_start:
	
	la s0, LEDs
	lw s2, 0(s0)
	addi s1, s2, 0x40
loop:
	lw s0, 0(s1)
	addi s0, s0, 0
	sw s0, 0(s2)
	J loop
	
.data
LEDs: .dc.l 0xFF200000
