#include <xc.inc>

	global  Keypad_Setup_1, Decoder, LCD_delay_x4us, LCD_delay_ms, NonDataVals_n_Instructions,loadfsr, setkey1,ClearMem,Keypad_getKey
    
	extrn	 LCD_ClearScreen
	extrn	Keypad_output,Keypad_output2,MessageLength1,MessageLength2,Typed_in_vals,Read_out_vals, Decoded_val
	extrn	LCD_Write_Message, LCD_Setup, keyv, keyvalue
;;;;;;;;;;;;;;;-**Code for Decoding keypad buttons pushed**-;;;;;;;;;;;;;;;;;;;;;;;     
psect    udata_acs   ; reserve data space in access ram, for named variables
cnt_h:	ds 1   ; reserve 1 byte for variable cnt_h used in 16bit delay
cnt_l:	ds 1   ; reserve 1 byte for variable cnt_l used in 16 bit delay  
cnt_ms:	ds 1   ; reserve 1 byte for ms counter used in microsecond delay      

    ;;;;;;;-**Button-Byte space reservations**-;;;;;;;;

ErrButtons:ds 1
NoButton:   ds 1
Button0:    ds 1
Button1:    ds 1
Button2:    ds 1
Button3:    ds 1
Button4:    ds 1
Button5:    ds 1
Button6:    ds 1
Button7:    ds 1    
Button8:    ds 1
Button9:    ds 1
ButtonA:    ds 1
ButtonB:    ds 1
ButtonC:    ds 1
ButtonD:    ds 1
ButtonE:    ds 1
ButtonF:    ds 1 
ClearButtons:	ds 1


NoButtonInput EQU  0x00	; defined hex constant used in keypad-decoding 
			; instance when no button is pressed
;ErrButtonInput EQU 0xff	; defined hex constant used in keypad-decoding 
			; instance when multiple buttons are pressed 
			; resulting in an error case
;;;;;;;;;;;;;;;-**Keypad Setup Code**-;;;;;;;;;;;;;;;;;;;;;;;    
psect	keypad_setup_code,class=CODE
			
setkey1:  ; Calls the Keypad Setup Routine, and Enables PORTC as Output 
	    ;	To test and verify which keys are pressed using LCD Display
    movlw   0x00
    movwf   TRISC, A	    ; Enable PortC to output keypad vals for Testing
    movlw   1
    movwf   MessageLength1, A  ;Start messagelength1 reserved byte when (no pressed keys) by filling with value 1 for computational reasons 
			    ;(typed values must be followed by hex-digit in order to display properly on screen)
    movlw   0		 ;Start messagelength2 reserved byte when(no keys pressed) at 0 True count for Start
    movwf   MessageLength2, A
    call    Keypad_Setup_1  ;Call Keypad Setup from Keypad_Setup Module
    return

 Keypad_Setup_1:
	banksel    PADCFG1
	bsf        REPU
	movlw	11111111B
	movwf	ErrButtons, A
	movlw   00000000B
	movwf   NoButton, A
	movlw   10001000B
	movwf   Button1, A
	movlw   01001000B
	movwf   Button2, A
	movlw   00101000B
	movwf   Button3, A
	movlw   00011000B
	movwf   ButtonF, A
	movlw   10000100B
	movwf   Button4, A
	movlw   01000100B 
	movwf   Button5, A
	movlw   00100100B
	movwf   Button6, A
	movlw   00010100B
	movwf   ButtonE, A
	movlw	10000010B    
	movwf   Button7, A
	movlw	01000010B    
	movwf   Button8, A
	movlw   00100010B
	movwf   Button9, A
	movlw   00010010B
	movwf   ButtonD, A
	movlw	10000001B    
	movwf   ButtonA, A
	movlw	01000001B    
	movwf   Button0, A
	movlw   00100001B
	movwf   ButtonB, A
	movlw   00010001B
	movwf   ButtonC, A
	movlw	00011001B
	movwf	ClearButtons, A		; Clears Screen when Buttins C+F pushed simultaneously
	return


Keypad_getKey:
    ;get col input
    clrf    LATE, A	;Clear Latch (for All Pins) of PortE
    movlw   0x0F	
    movwf   TRISE, A	;Enable Output for Pins RE:4-7
    movlw   100		;400(4x100)us micro-second delay 
    call    LCD_delay_x4us
    
    ;columns
    movlw   0x0F
    movff   PORTE, WREG	;take keypad readings for lower-nibble, replace in W
    movwf   Keypad_output, A ;move lower-nibble reading to-Keypad_outout for storage
    ;movwf   LATF, A
    
    ;get row input
    clrf    LATE, A	; Clear Latch PortE (for All Pins)
    movlw   0xF0	
    movwf   TRISE, A	;Enable Output for Pins RE:0-3
    movlw   100	
    call    LCD_delay_x4us	;400(4x100)us micro-second delay
    
    ;row
    movlw   0xF0
    ;andwf   PORTE, W, A	;take keypad readings for higher-nibble, replace in W
    movff   PORTE, WREG	;take keypad readings for higher-nibble, replace in W
    iorwf   Keypad_output, W, A ;inclusive-or higher-nibble readings with lower (in Keypad_output)
				;replace in W, Now had information for both Row-Column 
				;of button pressed with low bits 0 for each and high-1s 
				;everywhere else
    comf    WREG, W, A	    ; Gets the complementary value of the above byte
			    ; so rows-columns selected are represented by 1's and rest 0's
    movwf   Keypad_output2, A	; Store this Final-value back in Keypad_output
    movwf   LATC, A	    ;Send it to PortC also for Keypad functionality check 
    call    Decoder	    ;Call the Decoder for decoding what Button was pressed
			    ;sends a corresponding Character to W
    movwf keyv, A
    return
    
    
;;;;;;;;;;;;;;;-**Keypad Decoder Code**-;;;;;;;;;;;;;;;;;;;;;;; 
psect	Decoder_code_setup,class=CODE
Decoder:
    
    cpfseQ  NoButton, A	    ; if no button is pressed code skips to retlw-return 
				; and sends hex 0x00 to WREG
    bra	    check0		; if not a 'no-button' code branches to Check0 
				; to check if 'Zero' - was pressed
    retlw   0x00
    check0:
	cpfseQ  Button0, A	; if Zero-button is pressed code skips to retlw-return
				; and sends hex '0' to WREG
	bra	check1		; if not a 'button0' code branches to Check1
				; to check if Button1 was pressed
	retlw   '0'
    check1:
	cpfseQ  Button1, A	; if Button1 is pressed code skips to retlw-return
				; and sends hex '1' to WREG
	bra	check2		; if not a 'button1' code branches to Check2
				; to check if Button2 was pressed
	retlw   '1'
    check2:
	cpfseQ  Button2, A	; if Button2 is pressed code skips to retlw-return
				; and sends hex '2' to WREG
	bra	check3		; if not a 'button2' code branches to Check3
				; to check if Button3 was pressed
	retlw   '2'
    check3:
	cpfseQ  Button3, A	; if Button3 is pressed code skips to retlw-return
				; and sends hex '3' to WREG
	bra	check4		; if not a 'button3' code branches to Check4
				; to check if Button4 was pressed
	retlw   '3'
    check4:
	cpfseQ  Button4, A	; if Button4 is pressed code skips to retlw-return
				; and sends hex '4' to WREG
	bra	check5		; if not a 'button4' code branches to Check5
				; to check if Button5 was pressed
	retlw   '4'
    check5:
	cpfseQ  Button5, A	; if Button5 is pressed code skips to retlw-return
				; and sends hex '5' to WREG
	bra	check6		; if not a 'button5' code branches to Check6
				; to check if Button6 was pressed
	retlw   '5'
    check6:
	cpfseQ  Button6, A	; if Button6 is pressed code skips to retlw-return
				; and sends hex '6' to WREG
	bra     check7		; if not a 'button6' code branches to Check7
				; to check if Button7 was pressed
	retlw   '6'
    check7:
	cpfseQ  Button7, A	; if Button7 is pressed code skips to retlw-return
				; and sends hex '7' to WREG
	bra     check8		; if not a 'button7' code branches to Check8
				; to check if Button8 was pressed	
	retlw   '7'
    check8:
	cpfseQ  Button8, A	; if Button8 is pressed code skips to retlw-return
				; and sends hex '8' to WREG
	bra     check9		; if not a 'button8' code branches to Check9
				; to check if Button9 was pressed	
	retlw   '8'
    check9:
	cpfseQ  Button9, A	; if Button9 is pressed code skips to retlw-return
				; and sends hex '9' to WREG
	bra     checkA		; if not a 'button9' code branches to CheckA
				; to check if ButtonA was pressed	
	retlw   '9'
    checkA:
	cpfseQ  ButtonA, A	; if ButtonA is pressed code skips to retlw-return
				; and sends hex 'A' to WREG
	bra     checkB		; if not a 'buttonA' code branches to CheckB
				; to check if ButtonB was pressed	
	retlw   'A'
    checkB:
	cpfseQ  ButtonB, A	; if ButtonB is pressed code skips to retlw-return
				; and sends hex 'B' to WREG
	bra     checkC		; if not a 'buttonB' code branches to CheckC
				; to check if ButtonC was pressed	
	retlw   'B'
    checkC:
	cpfseQ  ButtonC, A	; if ButtonC is pressed code skips to retlw-return
				; and sends hex 'C' to WREG
	bra     checkD		; if not a 'buttonC' code branches to CheckD
				; to check if ButtonD was pressed	
	retlw   'C'
    checkD:
	cpfseQ  ButtonD, A	; if ButtonD is pressed code skips to retlw-return
				; and sends hex 'D' to WREG
	bra     checkE		; if not a 'buttonD' code branches to CheckE
				; to check if ButtonE was pressed	
	retlw   'D'
    checkE:
	cpfseQ  ButtonE, A	; if ButtonE is pressed code skips to retlw-return
				; and sends hex 'E' to WREG
	bra     checkF		; if not a 'buttonE' code branches to CheckF
				; to check if ButtonF was pressed	
	retlw   'E'
    checkF:
	cpfseQ	ButtonF, A	; if ButtonF is pressed code skips to retlw-return
				; and sends hex 'F' to WREG
	bra     check_clearscreen	; if not a 'buttonF' code branches to CheckError
				; to check if an Error Occurred	
	retlw   'F'
    check_clearscreen:
	cpfseQ	ClearButtons, A	; if Buttons (C+F) pressed code skips to retlw-return
				; and sends clear-signal to WREG
	bra     checkError	; if not a 'C+F' code branches to CheckError
				; to check if an Error Occurred	
	movff	ClearButtons, WREG, A
	return 
    checkError:
	retlw   0xFF
  
    
;    call    NonDataVals_n_Instructions
;    bra Keypad_getKey

	
	
;------------------------------------------------------------------------------;
;	        UNUSED FUNCTIONS WHICH MAY BE USEFUL ELSEWHERE	               ;
;------------------------------------------------------------------------------;	
;*****************  Below are Subroutines which were not used  ****************;	
;-----------------------------  In this Project  ------------------------------;	
	
    
NonDataVals_n_Instructions:
    	
	;-----;;;Subroutine to Check if an Error or NoButton was recorded---
	
	CheckError_or_NoInput:	 ; This subroutine checks for NoButton or Error(multiple buttons) being pressed
			   ; returns to Keypad_getKey if either of these conditions are satisfied
	    bra CheckNoButtonInput
	    CheckNoButtonInput:
		cpfseQ  NoButton, A
		bra	CheckErrorInput 
		return
	    CheckErrorInput:
		cpfseQ  ErrButtons, A
		bra     Checkclear_Screen_n_Memory
		;clrf	WREG, A
		return
	;-----;;;Subroutine to Check if a ClearScreen (C+F) Instruction was pushed---
	Checkclear_Screen_n_Memory:	; This subroutine checks if C+F pressed
		; and sends a clear LCD screen instruction as well as clears the Typed_in_memory space
		cpfseQ  ClearButtons, A
		goto	LoadFSRs
		call	LCD_ClearScreen
		call	ClearMem
		goto	Keypad_getKey
		
		

		
LoadFSRs:   ;   Stores Typed in Keypad Values @ FSRs
    movwf   Decoded_val, A  ;Stores this character in byte address Decoded_val
		    ; Load FSR's 1 and 2 with predefined Byte addresses
    lfsr    1, Typed_in_vals
    lfsr    2, Read_out_vals
        loadfsr:
	movlw   0
	cpfseQ  MessageLength2, A  ;skips if number of characters stored in FSR1&2 is Zero
				  ; Signified by MessageLength2 = 0
	call    inc_fsr1_n_2_by_msglngth2; FSR's are reset on each getKey loop;
	; so this function increments the FSRs to the Currennt registers to be filled.
	movff	Decoded_val, WREG, A
	;clrf	INDF1, A    
	;clrf	INDF2, A
	movwf   INDF1, A    ; transfers returned W literals from button-press into most recent FSR1
	movff   POSTINC1, POSTINC2  ; clones the value into FSR2, and then PostIncrements
	movlw	0x0a
	movwf	INDF1, A    ;Fills last register with hex-value for LCD printability 
	movwf	INDF2, A    ;Fills last register with hex-value for LCD printability 
	incf    MessageLength1, F, A	; Increment Message-length1 to more-better account for full no. bytes in FSR's including hex-val 
	movlw	2
	movff   MessageLength1, MessageLength2
	subwf	MessageLength2, F, A	; set-as msglngth1 -2 in prep for use in next subroutine
	;movwf   PORTC, A
	bra	LCD_Display
	reset_msglngth2:
	movff   MessageLength1, MessageLength2
	movlw	1
	subwf	MessageLength2, F, A
	clrf	WREG, A
	movlw   2800
	call    LCD_delay_ms
	call     Keypad_getKey
	
	
	
	
LCD_Display:
    ;call    dec_fsr1_n_2_by_msglngth2
    lfsr    1, Typed_in_vals
    lfsr    2, Read_out_vals
    movlw   0
    cpfseQ  MessageLength2, A
    call    inc_fsr1_n_2_by_msglngth2
    clrf    WREG, A
    movlw   1
    ;movff   MessageLength1, WREG
    call    LCD_Write_Message
    ;movff   MessageLength1, MessageLength2
    bra	    reset_msglngth2
    ;return
    
    
dec_fsr1_n_2_by_msglngth2:
    decf    FSR2, F, A
    decf    FSR1, F, A
    decfsz    MessageLength2, A
    bra    dec_fsr1_n_2_by_msglngth2
    return
inc_fsr1_n_2_by_msglngth2:
    incf    FSR2, F, A
    incf    FSR1, F, A
    decfsz  MessageLength2, A
    bra    inc_fsr1_n_2_by_msglngth2
    return 
    
    
ClearMem:
    movff   MessageLength1, MessageLength2
    lfsr    1, Typed_in_vals
    clear:
	clrf    POSTINC1, A
	decfsz	MessageLength2, F, A
	bra	clear
	movlw	1
	movff   MessageLength2, MessageLength1
	addwf	MessageLength1, F, A
	return
	

		end

