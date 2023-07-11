#include <xc.inc>

global  LCD_Setup, LCD_Write_Message, LCD_Write_Hex, LCD_hex_tmp, LCD_tmp, LCD_Send_Byte_D, delay, LCD_write_dec,LCD_Send_Byte_I
global	LCD_delay_ms,LCD_ClearScreen, LCD_delay_x4us	,sinemul, wavedis
extrn hex_low, hex_high, hex_dec_conversion, keyvalue
psect	udata_acs   ; named variables spaces(bytes) reserved in access ram
LCD_cnt_l:	ds 1	; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h:	ds 1	; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms:	ds 1	; reserve 1 byte for ms counter
LCD_tmp:	ds 1	; reserve 1 byte for temporary use
LCD_counter:	ds 1	; reserve 1 byte for counting through nessage
    
chk: ds 1;check dec
sinemul: ds 1

PSECT	udata_acs_ovr,space=1,ovrld,class=COMRAM
LCD_hex_tmp:	ds 1    ; reserve 1 byte for temporaty usage (variable LCD_hex_tmp) 
			; for hex-dig. to ascii hex values 
	LCD_E	EQU 5	; LCD enable bit
    	LCD_RS	EQU 4	; LCD register select bit
	
;__________________________________________________	
;_______________________________   

;******************************************************************************;
;___________________________ LCD - Setup - CODE _______________________________;
;**************************			 ******************************;	
;_____________________	
psect	lcd_code,class=CODE
    
LCD_Setup:
	clrf    LATB, A
	movlw   11000000B	    ; RB0:5 all outputs
	movwf	TRISB, A
	movlw   40
	call	LCD_delay_ms	; wait 40ms for LCD to start up properly
	movlw	00110000B	; Function set 4-bit
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00101000B	; 2 line display 5x8 dot characters
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00101000B	; repeat, 2 line display 5x8 dot characters
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00001111B	; display on, cursor on, blinking on
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00000001B	; display clear
	call	LCD_Send_Byte_I
	movlw	2		; wait 2ms
	call	LCD_delay_ms
	movlw	00000100B	; entry mode incr by 1 no shift
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	return	
;______________________________________________________________________________;
;______________________________________________________________________________;
;------------------------------------------------------------------------------;
;			    LCD  INSTRUCTIONS				       ;
;------------------------------------------------------------------------------;	
;**********************  Settings & Write Commands  ***************************;

LCD_Write_Message:	    ; Message stored at FSR2, length stored in W
	movwf   LCD_counter, A
LCD_Loop_message:
	movf    POSTINC2, W, A
	call    LCD_Send_Byte_D
	decfsz  LCD_counter, A
	bra	LCD_Loop_message
	return
	
LCD_ClearScreen:	    ; Clears LCD Screen
	movlw	00000001B	; display clear
	call	LCD_Send_Byte_I
	movlw	2		; wait 2ms
	call	LCD_delay_ms
	return
	
LCD_Send_Byte_I:	    ; Transmits byte stored in W to instruction reg
	movwf   LCD_tmp, A
	swapf   LCD_tmp, W, A   ; swap nibbles, high nibble goes first
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bcf	LATB, LCD_RS, A	; Instruction write clear RS bit
	call    LCD_Enable  ; Pulse enable Bit 
	movf	LCD_tmp, W, A   ; swap nibbles, now do low nibble
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bcf	LATB, LCD_RS, A	; Instruction write clear RS bit
        call    LCD_Enable  ; Pulse enable Bit 
	return

LCD_Send_Byte_D:	    ; Transmits byte stored in W to data reg
	movwf   LCD_tmp, A
	swapf   LCD_tmp, W, A	; swap nibbles and send swapped to WREG, high nibble goes first
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bsf	LATB, LCD_RS, A	; Data write set RS bit
	call    LCD_Enable  ; Pulse enable Bit 
	movf	LCD_tmp, W, A	; now do low nibble
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bsf	LATB, LCD_RS, A	; Data write set RS bit	    
        call    LCD_Enable  ; Pulse enable Bit 
	movlw	10	    ; delay 40us
	call	LCD_delay_x4us
	return

LCD_Enable:	    ; pulse enable bit LCD_E for 500ns
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bsf	LATB, LCD_E, A	    ; Take enable high
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bcf	LATB, LCD_E, A	    ; Writes data to LCD
	return
    
; ** a few delay routines below here as LCD timing can be quite critical ****
LCD_delay_ms:		    ; delay given in ms in WREG
	movwf	LCD_cnt_ms, A
lcdlp2:	movlw	250	    ; 1 ms delay
	call	LCD_delay_x4us	
	decfsz	LCD_cnt_ms, A
	bra	lcdlp2
	return
    
LCD_delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	LCD_cnt_l, A	; now need to multiply by 16
	swapf   LCD_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	LCD_cnt_l, W, A ; move only low (and-gated) (previously high) nibble to W
	movwf	LCD_cnt_h, A	; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	LCD_cnt_l, F, A ; move high (and-gated) (previously low) nibble 
				; to LCD_cnt_l but x16(nibble-swapped)
	call	LCD_delay
	return
	LCD_delay:			; delay routine	4 instruction loop == 250ns	    
		movlw 	0x00		; W=0
	lcdlp1:	decf 	LCD_cnt_l, F, A	; no carry when 0x00 -> 0xff
		subwfb 	LCD_cnt_h, F, A	; no carry when 0x00 -> 0xff                  
		bc 	lcdlp1		; carry, then loop again
		return			; carry reset so return
		
;______________________________________________________________________________;
;______________________________________________________________________________;
;------------------------------------------------------------------------------;
;			 LCD - Write Decimal Digit      		       ;
;------------------------------------------------------------------------------;	
;**********************  Settings & Write Commands  ******************;

LCD_write_dec:	   ; Checks for Correct Decimal Value and Writes Digit to LCD
		    ;   to Write	    
    ; - Writes 1st Digit - ;
	movff 0x40,chk, A
	call LCD_check_dec  ; write the dec digit stored in 0x40
	movf	0x00, W, A
	call LCD_Send_Byte_D
    ; - Writes 2nd Digit - ;
	movff 0x41,chk, A
	call LCD_check_dec; write the dec digit stored in 
	movf	0x00, W, A
	call LCD_Send_Byte_D
    ; - Writes 3rd Digit - ;
	movff 0x42,chk, A
	call LCD_check_dec; write the dec digit stored in 
	movf	0x00, W, A
	call LCD_Send_Byte_D
    ; - Writes 4th Digit - ;
	movff 0x43,chk, A
	call LCD_check_dec; write the dec digit stored in 
	movf	0x00, W, A
	call LCD_Send_Byte_D
	
    ; Checks for the value in each of 0x40,41,42,43 Decimal digits & writes the
    ; appropriate ASCII Code to the 0x00 register. To be sent to LCD
	
	LCD_check_dec:
		call dec0	    ;	Check if Decimal is '0'
		nop
		call dec1	    ;	Check if Decimal is '1'
		nop
		call dec2	    ;	Check if Decimal is '2'
		nop
		call dec3	    ;	Check if Decimal is '3'
		nop
		call dec4	    ;	Check if Decimal is '4'
		nop
		call dec5	    ;	Check if Decimal is '5'
		nop
		call dec6	    ;	Check if Decimal is '6'
		nop
		call dec7	    ;	Check if Decimal is '7'
		nop
		call dec8	    ;	Check if Decimal is '8'
		nop
		call dec9	    ;	Check if Decimal is '9'
		nop
		return

	dec0:	
		movlw	0x00
		cpfseq	chk, A
		return
		movlw	'0'
		movwf 0x00, A
	;	lfsr	2, 0x00 
		return	
	dec1:	
		movlw	0x01
		cpfseq	chk, A
		return
		movlw	'1'
		movwf 0x00, A
	;	lfsr	2, 0x00 
		return	
	dec2:	
		movlw	0x02
		cpfseq	chk, A
		return
		movlw	'2'
		movwf 0x00, A
	;	lfsr	2, 0x00 
		return	
	dec3:	
		movlw	0x03
		cpfseq	chk, A
		return
		movlw	'3'
		movwf 0x00, A
	;	lfsr	2, 0x00 
		return	
	dec4:	
		movlw	0x04
		cpfseq	chk, A
		return
		movlw	'4'
		movwf 0x00, A
	;	lfsr	2, 0x00 
		return	
	dec5:	
		movlw	0x05
		cpfseq	chk, A
		return
		movlw	'5'
		movwf 0x00, A
	;	lfsr	2, 0x00 
		return	
	dec6:	
		movlw	0x06
		cpfseq	chk, A
		return
		movlw	'6'
		movwf 0x00, A
	;	lfsr	2, 0x00 
		return	
	dec7:	
		movlw	0x07
		cpfseq	chk, A
		return
		movlw	'7'
		movwf 0x00, A
	;	lfsr	2, 0x00 
		return	
	dec8:	
		movlw	0x08
		cpfseq	chk, A
		return
		movlw	'8'
		movwf 0x00, A
	;	lfsr	2, 0x00 
		return	
	dec9:	
		movlw	0x09
		cpfseq	chk, A
		return
		movlw	'9'
		movwf 0x00, A
	;	lfsr	2, 0x00 
		return	    
		
		
delay:
		decfsz 0x10, f, A
		bra dey
		return
	dey:
		movlw 0xf0;delay time1
		movwf 0x20, A
		call delay1
		nop
		bra delay
	delay1:	
		decfsz 0x20, f, A
		bra dey1
		return
	dey1:
		movlw 0xf0;delay time1
		movwf 0x30, A
		call delay2
		nop
		bra delay1
	delay2:	
		decfsz 0x30, f, A
		bra delay2
		return
		
wavedis:
	goto check1
check1:
	movlw '1'
	cpfseq	keyvalue, A
	bra check2
	movlw 's'
	call LCD_Send_Byte_D
	movlw 'a'
	call LCD_Send_Byte_D
	movlw 'w'
	call LCD_Send_Byte_D
	return
check2:
	movlw '2'
	cpfseq	keyvalue, A
	bra check3
	movlw 's'
	call LCD_Send_Byte_D
	movlw 'q'
	call LCD_Send_Byte_D
	movlw 'u'
	call LCD_Send_Byte_D
	return
check3:
	movlw '3'
	cpfseq	keyvalue, A
	bra checkf
	movlw 's'
	call LCD_Send_Byte_D
	movlw 'i'
	call LCD_Send_Byte_D
	movlw 'n'
	call LCD_Send_Byte_D
	return
	
checkf:
	movlw 'F'
	cpfseq	keyvalue, A
	bra check4
	movlw 'r'
	call LCD_Send_Byte_D
	movlw 'a'
	call LCD_Send_Byte_D
	movlw 'n'
	call LCD_Send_Byte_D
	return
check4:
	movlw '4'
	cpfseq	keyvalue, A
	bra check5
	movlw '8'
	call LCD_Send_Byte_D
	movlw 'M'
	call LCD_Send_Byte_D
	movlw 'H'
	call LCD_Send_Byte_D
	movlw 'z'
	call LCD_Send_Byte_D
	return
check5:
	movlw '5'
	cpfseq	keyvalue, A
	bra check6
	movlw '4'
	call LCD_Send_Byte_D
	movlw 'M'
	call LCD_Send_Byte_D
	movlw 'H'
	call LCD_Send_Byte_D
	movlw 'z'
	call LCD_Send_Byte_D
	return
check6:
	movlw '6'
	cpfseq	keyvalue, A
	bra checke
	movlw '2'
	call LCD_Send_Byte_D
	movlw 'M'
	call LCD_Send_Byte_D
	movlw 'H'
	call LCD_Send_Byte_D
	movlw 'z'
	call LCD_Send_Byte_D
	return
	
checke:
	movlw 'E'
	cpfseq	keyvalue, A
	bra check7
	
	return
    
check7:
	movlw '7'
	cpfseq	keyvalue, A
	bra check8
	movlw '1'
	call LCD_Send_Byte_D
	movlw 'M'
	call LCD_Send_Byte_D
	movlw 'H'
	call LCD_Send_Byte_D
	movlw 'z'
	call LCD_Send_Byte_D
	return
	
check8:
	movlw '8'
	cpfseq	keyvalue, A
	bra check9
	movlw '5'
	call LCD_Send_Byte_D
	movlw '0'
	call LCD_Send_Byte_D
	movlw '0'
	call LCD_Send_Byte_D
	movlw 'K'
	call LCD_Send_Byte_D
	movlw 'H'
	call LCD_Send_Byte_D
	movlw 'z'
	call LCD_Send_Byte_D
	return
	
check9:
	movlw '9'
	cpfseq	keyvalue, A
	bra checkD
	movlw '2'
	call LCD_Send_Byte_D
	movlw '5'
	call LCD_Send_Byte_D
	movlw '0'
	call LCD_Send_Byte_D
	movlw 'K'
	call LCD_Send_Byte_D
	movlw 'H'
	call LCD_Send_Byte_D
	movlw 'z'
	call LCD_Send_Byte_D
	return
checkD:
	movlw 'D'
	cpfseq	keyvalue, A
	bra checkA
	return
checkA:
	movlw 'A'
	cpfseq	keyvalue, A
	bra checkB
	movlw 's'
	call LCD_Send_Byte_D
	movlw 'd'
	call LCD_Send_Byte_D
	movlw 'i'
	call LCD_Send_Byte_D
	movlw 's'
	call LCD_Send_Byte_D
	return
checkB:
	movlw 'B'
	cpfseq	keyvalue, A
	bra checkC
	return
 checkC:
	movlw 'C'
	cpfseq	keyvalue, A
	bra check0
	return
check0: 
	movlw '0'
	cpfseq	keyvalue, A
	bra checkend
	movlw '1'
	call LCD_Send_Byte_D
	movlw '2'
	call LCD_Send_Byte_D
	movlw '5'
	call LCD_Send_Byte_D
	movlw 'K'
	call LCD_Send_Byte_D
	movlw 'H'
	call LCD_Send_Byte_D
	movlw 'z'
	call LCD_Send_Byte_D
	return
checkend:
	
	movlw 'n'
	call LCD_Send_Byte_D
	movlw 'o'
	call LCD_Send_Byte_D
	movlw 'n'
	call LCD_Send_Byte_D
	movlw 'e'
	return
		
   
end