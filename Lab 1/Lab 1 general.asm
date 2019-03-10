$MODDE0CV

; ------------------
; 7seg display
; These are the inputs to the 7seg for a given binary
; 		-6543210
; 		-gfedcba
n0 equ  01000000b ;0
n1 equ  01111001b ;1
n2 equ  00100100b ;2
n3 equ  00110000b ;3
n4 equ  00011001b ;4
n5 equ  00010010b ;5
n6 equ  00000010b ;6
n7 equ  01111000b ;7
n8 equ  00000000b ;8
n9 equ  00011000b ;9
L_h equ 00001001b ;H
L_e equ 00000110b ;E
L_l equ 01000111b ;L
L_c equ 01000110b ;C
L_p equ 00001100b ;P
L_n equ 01001000b ;N
; ------------------

; Enter your SN here
L_1 equ n1
L_2 equ n2
L_3 equ n3
L_4 equ n4
L_5 equ n5
L_6 equ n6
L_7 equ n7
L_8 equ n8
BLANK equ 01111111b
DASH equ 00111111b

; Assembler load address, jump to init
org 0
	ljmp init

; Wait function, waits for ~0.5 secs
wait_05:
    mov R2, #90  ; 90 is 5AH
L3: mov R1, #250 ; 250 is FAH 
L2: mov R0, #250
L1: djnz R0, L1  ; 3 machine cycles-> 3*30ns*250=22.5us
    djnz R1, L2  ; 22.5us*250=5.625ms
    djnz R2, L3  ; 5.625ms*90=0.506s (approximately)
	ret

; Initialize stat + clear LEDs
init:
	mov SP, #0x7f ; Initialize the stack
	mov LEDRA, #0
	mov LEDRB, #0
	
main_loop:

	; Store all switch bits in A and mask all except the last 3 to compare
	mov A, SWA 
	anl A, #00000111b
	; Compare and jump to each loop as required
		cjne A, #00000000b, disp_1l
			LJMP disp_0
			SJMP main_loop
disp_1l: cjne A, #00000001b, disp_2l
			LJMP disp_1
			SJMP main_loop
disp_2l: cjne A, #00000010b, disp_3l
			LJMP disp_2
			SJMP main_loop
disp_3l: cjne A, #00000011b, disp_4l
			LJMP disp_3
			SJMP main_loop
disp_4l: cjne A, #00000100b, disp_5l
			LJMP disp_4
			SJMP main_loop
disp_5l: cjne A, #00000101b, disp_6l
			LJMP disp_5
			SJMP main_loop
disp_6l: cjne A, #00000110b, disp_7l
			LJMP disp_6
			SJMP main_loop
disp_7l: cjne A, #00000111b, main_loop
			LJMP disp_7
			SJMP main_loop

; First 6 SN
disp_0:
	mov HEX5, #L_1
	mov HEX4, #L_2
	mov HEX3, #L_3
	mov HEX2, #L_4
	mov HEX1, #L_5
	mov HEX0, #L_6
	LJMP main_loop

; Last 2 SN
disp_1:
	mov HEX5, #BLANK
	mov HEX4, #BLANK
	mov HEX3, #BLANK
	mov HEX2, #BLANK
	mov HEX1, #L_7
	mov HEX0, #L_8
	LJMP main_loop

; Scroll to the left
disp_2:
	; Abuse pointers
	
	;Assign 8SNs to 8 sequential addresses in memory
		;mov @R0 SN
		;increment R0
		;repeat
	
	;Set R0 to first address
	;Loop
		;Assign Hex to R0 value
			;mov HEX0 @R0
		;increment R0 address
			;R0 + 1?
		;Assign to next
			;mov HEX1 @R0
		;Repeat till all hex complete
		;Compare if its at the end of addresses if so reset R0 to first address and loop back 
		;if not at the end of all addresses increment one more time then loop back
	
	LJMP main_loop

; Scroll to the right
disp_3:
	LJMP main_loop

;Blink last 6
disp_4:
	mov HEX5, #L_3
	mov HEX4, #L_4
	mov HEX3, #L_5
	mov HEX2, #L_6
	mov HEX1, #L_7
	mov HEX0, #L_8
	lcall wait_05
	mov HEX5, #BLANK
	mov HEX4, #BLANK
	mov HEX3, #BLANK
	mov HEX2, #BLANK
	mov HEX1, #BLANK
	mov HEX0, #BLANK
	lcall wait_05
	LJMP main_loop

;make first 6 display one at a time
disp_5:
	mov HEX5, #BLANK
	mov HEX4, #BLANK
	mov HEX3, #BLANK
	mov HEX2, #BLANK
	mov HEX1, #BLANK
	mov HEX0, #BLANK
	lcall wait_05
	mov HEX5, #L_1
	lcall wait_05
	mov HEX4, #L_2
	lcall wait_05
	mov HEX3, #L_3
	lcall wait_05
	mov HEX2, #L_4
	lcall wait_05
	mov HEX1, #L_5
	lcall wait_05
	mov HEX0, #L_6
	lcall wait_05
	LJMP main_loop

; display hello, then first 6, then cpn312
disp_6:
	mov HEX5, #L_h
	mov HEX4, #L_e
	mov HEX3, #L_l
	mov HEX2, #L_l
	mov HEX1, #n0
	mov HEX0, #BLANK
	lcall wait_05
	mov HEX5, #L_1
	mov HEX4, #L_2
	mov HEX3, #L_3
	mov HEX2, #L_4
	mov HEX1, #L_5
	mov HEX0, #L_6
	lcall wait_05
	mov HEX5, #L_c
	mov HEX4, #L_p
	mov HEX3, #L_n
	mov HEX2, #L_3
	mov HEX1, #L_1
	mov HEX0, #L_2
	lcall wait_05
	LJMP main_loop

; Be creative
disp_7:
	LJMP main_loop

END