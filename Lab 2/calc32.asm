;--------------------------------
;Calculator Lab
;Adapted from "Read_sw6.asm" by Jesus Calvino-Fraga
;Input number by flipping SW9-0
;KEY3 is + | *
;KEY2 is - | /
;KEY1 is =
;KEY0 is modifier key for KEY3/2
;ex
;SW9 KEY0+KEY3 SW2 KEY1 displays 18

$modde0cv

	CSEG at 0
	ljmp init

	dseg at 30h
	
	x: 	ds 4 ; 32-bits for variable ‘x’
	y: 	ds 4 ; 32-bits for variable ‘y’
	bcd:ds 5 ; 10-digit packed BCD (each byte stores 2 digits)
	op: ds 1 ; add/sub/mult/div flags 0/1/2/3
	
	bseg
	mf:    dbit 1 ; Math functions lag
	
	$include(math32.asm) 

; Look-up table for 7-seg displays
S_segLUT:
    DB 0C0H, 0F9H, 0A4H, 0B0H, 099H        ; 0 TO 4
    DB 092H, 082H, 0F8H, 080H, 090H        ; 4 TO 9

showBCD MAC
	; display LSD
    mov A, %0
    anl a, #0fh
    movc A, @A+dptr
    mov %1, A
	; display MSD
    mov A, %0
    swap a
    anl a, #0fh
    movc A, @A+dptr
    mov %2, A
ENDMAC

display:
	mov dptr, #S_segLUT
	showBCD(bcd+0, HEX0, HEX1)
	showBCD(bcd+1, HEX2, HEX3)
	showBCD(bcd+2, HEX4, HEX5)
    ret

MYRLC MAC
	mov a, %0
	rlc a
	mov %0, a
ENDMAC

Shift_Digits:
	mov R0, #4 ; shift left four bits
Shift_Digits_L0:
	clr c
	MYRLC(bcd+0)
	MYRLC(bcd+1)
	MYRLC(bcd+2)
	MYRLC(bcd+3)
	MYRLC(bcd+4)
	djnz R0, Shift_Digits_L0
	; R7 has the new bcd digit	
	mov a, R7
	orl a, bcd+0
	mov bcd+0, a
	; bcd+3 and bcd+4 don't fit in the 7-segment displays so make them zero
	clr a
	mov bcd+4, a
	ret

Wait50ms:
;33.33MHz, 1 clk per cycle: 0.03us
	mov R0, #30
L3: mov R1, #74
L2: mov R2, #250
L1: djnz R2, L1 ;3*250*0.03us=22.5us
    djnz R1, L2 ;74*22.5us=1.665ms
    djnz R0, L3 ;1.665ms*30=50ms
    ret

; Check if SW0 to SW9 are toggled up.  Returns the toggled switch in
; R7.  If the carry is not set, no toggling switches were detected.
ReadNumber:
	mov r4, SWA ; Read switches 0 to 7
	mov a, SWB ; Read switches 8 to 9
	anl a, #00000011B ; Only two bits of SWB available
	mov r5, a
	mov a, r4
	orl a, r5
	jz ReadNumber_no_number
	lcall Wait50ms ; debounce
	mov a, SWA
	clr c
	subb a, r4
	jnz ReadNumber_no_number ; it was a bounce
	mov a, SWB
	anl a, #00000011B
	clr c
	subb a, r5
	jnz ReadNumber_no_number ; it was a bounce
	mov r7, #16 ; Loop counter
ReadNumber_L0:
	clr c
	mov a, r4
	rlc a
	mov r4, a
	mov a, r5
	rlc a
	mov r5, a
	jc ReadNumber_decode
	djnz r7, ReadNumber_L0
	sjmp ReadNumber_no_number	
ReadNumber_decode:
	dec r7
	setb c
ReadNumber_L1:
	mov a, SWA
	jnz ReadNumber_L1
ReadNumber_L2:
	mov a, SWB
	jnz ReadNumber_L2
	ret
ReadNumber_no_number:
	clr c
	ret
	
do_add:
	lcall add32
	lcall hex2bcd
	ret
do_sub:
	lcall sub32
	lcall hex2bcd
	ret
do_mul:
	lcall mul32
	lcall hex2bcd
	ret
do_div:
	lcall div32
	lcall hex2bcd
	ret

do_op:
	; Select op: 
	mov a, op   
	jb acc.0, do_add
	jb acc.1, do_sub
	jb acc.2, do_mul 
	jb acc.3, do_div
	ret
	
init:
	mov SP, #7FH ;set stack pointer
	
	;clear BCD disp
	clr a
	mov LEDRA, a
	mov LEDRB, a
	mov bcd+0, a
	mov bcd+1, a
	mov bcd+2, a
	mov bcd+3, a
	mov bcd+4, a
	lcall display
	sjmp main

main:
	jb KEY.3, sub_div ; Check if KEY3 is pressed (+|*)
	jnb KEY.3, $ 
	lcall bcd2hex ;Convert the BCD to hex
	lcall copy_xy ;Copy x into y
	Load_X(0)	  ;Clear x
	lcall hex2bcd ;Convert x hex into bcd
	lcall display ;display x in bcd
	jnb KEY.0, is_mult
	mov op, #0001B
	ljmp main
is_mult:
	mov op, #0100B
	ljmp main
sub_div:
	jb KEY.2, equal_check ; Check if KEY2 is pressed (-|/)
	jnb KEY.2, $ 
	lcall bcd2hex ;Convert the BCD to hex
	lcall copy_xy ;Copy x into y
	Load_X(0)	  ;Clear x
	lcall hex2bcd ;Convert x hex into bcd
	lcall display ;display x in bcd
	jnb KEY.0, is_div
	mov op, #0010B
	ljmp main
is_div:
	mov op, #1000B
	ljmp main
equal_check:
	jb KEY.1, no_equal ; If the '=' key not pressed, skip
	jnb KEY.1, $; Wait for user to release the '=' key
	lcall bcd2hex      ; Convert the BCD number to hex in x
	lcall xchg_xy	   ; Swap x and y so that the op is first op last
	
	lcall do_op	;jump for the operation because the program won't work otherwise
	
	lcall display
	ljmp main
no_equal: ;Redisplay numbers and jump back to main
	lcall ReadNumber
	jnc main
	lcall Shift_digits
	lcall display
	ljmp main
end
